//
//  AppState.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI
import Combine
import AppKit

/// Main application state for Phosphor
/// Holds the frames array and export settings
@MainActor
class AppState: ObservableObject {
    // MARK: - Undo/Redo
    let undoManager = PhosphorUndoManager()
    @Published var isImporting: Bool = false

    // MARK: - Frame Data

    /// All imported image frames
    @Published var frames: [ImageItem] = []

    /// Currently selected frame index (nil if none selected)
    @Published var selectedFrameIndex: Int? {
        didSet {
            // When user selects a frame while paused, sync preview to selection
            if !isPlaying, let index = selectedFrameIndex {
                currentPreviewIndex = index
            }
        }
    }

    // MARK: - Timeline Zoom

    /// Thumbnail width for timeline (20-100 pixels)
    @Published var thumbnailWidth: CGFloat = 80

    /// Minimum and maximum thumbnail widths
    static let thumbnailWidthRange: ClosedRange<CGFloat> = 40...120

    // MARK: - Playback State

    /// Whether the preview is currently playing
    @Published var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                startPlayback()
            } else {
                stopPlayback()
            }
        }
    }

    /// Current frame being displayed in preview
    @Published var currentPreviewIndex: Int = 0

    /// Timer for playback animation
    private var playbackTimer: AnyCancellable?

    // MARK: - Export Settings

    /// Export settings (frame rate, loop count, format, etc.)
    @Published var exportSettings = ExportSettings()

    // MARK: - Export State

    /// Whether an export is currently in progress
    @Published var isExporting: Bool = false

    /// Export progress (0.0 to 1.0)
    @Published var exportProgress: Double = 0.0

    /// Last export error (if any)
    @Published var exportError: Error?

    /// Whether to show export success alert
    @Published var showExportSuccess: Bool = false

    /// URL of the last successful export
    @Published var lastExportURL: URL?

    // MARK: - Computed Properties

    /// Whether there are any frames loaded
    var hasFrames: Bool {
        !frames.isEmpty
    }

    /// Currently selected frame (if any)
    var selectedFrame: ImageItem? {
        guard let index = selectedFrameIndex, frames.indices.contains(index) else {
            return nil
        }
        return frames[index]
    }

    /// Returns only non-muted frames for export
    var unmutedFrames: [ImageItem] {
        frames.filter { !$0.isMuted }
    }

    /// Number of unmuted frames (for display in frame counter)
    var unmutedFrameCount: Int {
        unmutedFrames.count
    }

    /// Current position within unmuted frames (1-based for display)
    /// Returns nil if current frame is muted or no frames
    var currentUnmutedPosition: Int? {
        guard hasFrames else { return nil }
        let index = currentPreviewIndex
        guard frames.indices.contains(index), !frames[index].isMuted else { return nil }

        // Count how many unmuted frames come before this one
        var position = 1
        for i in 0..<index {
            if !frames[i].isMuted {
                position += 1
            }
        }
        return position
    }

    /// Whether playback can proceed (need at least one unmuted frame)
    var canPlay: Bool {
        unmutedFrameCount > 0
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Per-Frame Timing

    /// Build per-frame delays array for export.
    /// Returns nil if no custom delays set (enables exporter optimization).
    func buildPerFrameDelays() -> [Double]? {
        let delays = unmutedFrames.map { frame -> Double in
            // customDelay is in ms, convert to seconds for exporters
            (frame.customDelay ?? exportSettings.frameDelay) / 1000.0
        }
        let hasCustom = unmutedFrames.contains { $0.customDelay != nil }
        return hasCustom ? delays : nil
    }

    // MARK: - Playback Control

    /// Start the playback timer based on current frame rate (with per-frame timing)
    private func startPlayback() {
        guard canPlay else {
            isPlaying = false
            return
        }

        // If current frame is muted, jump to first unmuted frame
        if frames[currentPreviewIndex].isMuted {
            jumpToFirstUnmutedFrame()
        }

        scheduleNextFrame()
    }

    /// Jump to the first unmuted frame
    private func jumpToFirstUnmutedFrame() {
        guard let firstUnmuted = frames.firstIndex(where: { !$0.isMuted }) else { return }
        currentPreviewIndex = firstUnmuted
    }

    /// Schedule the next frame with per-frame timing support
    private func scheduleNextFrame() {
        guard isPlaying, hasFrames else { return }

        let currentFrame = frames[currentPreviewIndex]
        let delayMs = currentFrame.customDelay ?? exportSettings.frameDelay
        let interval = delayMs / 1000.0

        playbackTimer?.cancel()
        playbackTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.advanceFrame()
                self?.scheduleNextFrame()
            }
    }

    /// Stop the playback timer
    private func stopPlayback() {
        playbackTimer?.cancel()
        playbackTimer = nil
    }

    /// Advance to the next unmuted frame, wrapping around at the end
    private func advanceFrame() {
        guard canPlay else { return }

        // Find the next unmuted frame after current position
        var nextIndex = (currentPreviewIndex + 1) % frames.count
        let startIndex = nextIndex

        // Walk through frames until we find an unmuted one (or wrap back to start)
        while frames[nextIndex].isMuted {
            nextIndex = (nextIndex + 1) % frames.count
            // Safety: if we've checked all frames, stop (shouldn't happen with canPlay guard)
            if nextIndex == startIndex { break }
        }

        currentPreviewIndex = nextIndex
    }

    /// Toggle playback on/off
    func togglePlayback() {
        guard canPlay else { return }
        isPlaying.toggle()
    }

    /// Jump to a specific frame
    func jumpToFrame(_ index: Int) {
        guard frames.indices.contains(index) else { return }
        currentPreviewIndex = index
        if !isPlaying {
            selectedFrameIndex = index
        }
    }

    /// Navigate to the previous unmuted frame (for left arrow key)
    func previousUnmutedFrame() {
        guard canPlay, !isPlaying else { return }

        // Find the previous unmuted frame
        var prevIndex = currentPreviewIndex - 1
        if prevIndex < 0 { prevIndex = frames.count - 1 }

        let startIndex = prevIndex

        // Walk backwards until we find an unmuted frame
        while frames[prevIndex].isMuted {
            prevIndex -= 1
            if prevIndex < 0 { prevIndex = frames.count - 1 }
            if prevIndex == startIndex { break }
        }

        currentPreviewIndex = prevIndex
        selectedFrameIndex = prevIndex
    }

    /// Navigate to the next unmuted frame (for right arrow key)
    func nextUnmutedFrame() {
        guard canPlay, !isPlaying else { return }

        // Find the next unmuted frame
        var nextIndex = (currentPreviewIndex + 1) % frames.count
        let startIndex = nextIndex

        // Walk forward until we find an unmuted frame
        while frames[nextIndex].isMuted {
            nextIndex = (nextIndex + 1) % frames.count
            if nextIndex == startIndex { break }
        }

        currentPreviewIndex = nextIndex
        selectedFrameIndex = nextIndex
    }

    /// Jump to a specific position in unmuted frames (for scrubber)
    /// Position is 1-based (matches display)
    func jumpToUnmutedPosition(_ position: Int) {
        guard position >= 1 && position <= unmutedFrameCount else { return }

        // Find the frame at this unmuted position
        var unmutedCount = 0
        for (index, frame) in frames.enumerated() {
            if !frame.isMuted {
                unmutedCount += 1
                if unmutedCount == position {
                    currentPreviewIndex = index
                    if !isPlaying {
                        selectedFrameIndex = index
                    }
                    return
                }
            }
        }
    }

    /// Calculate and set thumbnail width to fit all frames in the given width
    func fitAllThumbnails(availableWidth: CGFloat) {
        guard !frames.isEmpty else { return }

        // Account for spacing between thumbnails (8px gap) and some padding
        let spacing: CGFloat = 8
        let padding: CGFloat = 16
        let usableWidth = availableWidth - padding

        // Calculate optimal width: (usableWidth + spacing) / count - spacing
        let optimalWidth = (usableWidth + spacing) / CGFloat(frames.count) - spacing

        // Clamp to valid range
        thumbnailWidth = min(max(optimalWidth, Self.thumbnailWidthRange.lowerBound), Self.thumbnailWidthRange.upperBound)
    }

    // MARK: - Frame Management

    /// Import images from URLs, sorted by filename
    func importImages(urls: [URL]) async {
        let sortedURLs = urls.sorted { $0.lastPathComponent < $1.lastPathComponent }

        var importedItems: [ImageItem] = []

        for url in sortedURLs {
            if let item = ImageItem.from(url: url) {
                importedItems.append(item)
            }
        }

        guard !importedItems.isEmpty else { return }

        isImporting = true

        let command = ImportFramesCommand(frames: importedItems)
        try? undoManager.perform(command, on: self)

        let hadFrames = !frames.filter { !importedItems.contains($0) }.isEmpty
        if !hadFrames && hasFrames {
            selectedFrameIndex = 0
        }

        updateAutomaticCanvasSize()

        isImporting = false
    }

    /// Calculate the largest frame dimensions and update automaticCanvasSize
    private func updateAutomaticCanvasSize() {
        var maxWidth: CGFloat = 0
        var maxHeight: CGFloat = 0

        for frame in frames {
            if let image = NSImage(contentsOf: frame.url) {
                maxWidth = max(maxWidth, image.size.width)
                maxHeight = max(maxHeight, image.size.height)
            }
        }

        if maxWidth > 0 && maxHeight > 0 {
            exportSettings.automaticCanvasSize = CGSize(width: maxWidth, height: maxHeight)
        }
    }

    /// Remove frame at the specified index
    func removeFrame(at index: Int) {
        guard frames.indices.contains(index) else { return }

        let frame = frames[index]
        let command = DeleteFrameCommand(frame: frame, at: index)
        try? undoManager.perform(command, on: self)

        if let selected = selectedFrameIndex {
            if selected == index {
                selectedFrameIndex = index > 0 ? index - 1 : (frames.isEmpty ? nil : 0)
            } else if selected > index {
                selectedFrameIndex = selected - 1
            }
        }

        if currentPreviewIndex >= frames.count {
            currentPreviewIndex = max(0, frames.count - 1)
        }
    }

    /// Reorder frames using drag and drop
    func reorderFrames(from source: IndexSet, to destination: Int) {
        let command = ReorderFramesCommand(from: source, to: destination, currentFrames: frames)
        try? undoManager.perform(command, on: self)

        guard let selectedIndex = selectedFrameIndex,
              let movedIndex = source.first else {
            return
        }

        if source.contains(selectedIndex) {
            if destination > movedIndex {
                selectedFrameIndex = destination - 1
            } else {
                selectedFrameIndex = destination
            }
        } else {
            if selectedIndex >= destination && selectedIndex < movedIndex {
                selectedFrameIndex = selectedIndex + 1
            } else if selectedIndex > movedIndex && selectedIndex <= destination {
                selectedFrameIndex = selectedIndex - 1
            }
        }
    }

    /// Toggle the muted state of the frame at the specified index
    func toggleMute(at index: Int) {
        guard frames.indices.contains(index) else { return }
        let frameID = frames[index].id
        let command = ToggleMuteCommand(frameID: frameID)
        try? undoManager.perform(command, on: self)
    }

    // MARK: - Transform Management

    /// Whether to show confirmation dialog for Apply to All
    @Published var showApplyTransformToAllConfirmation: Bool = false

    /// Rotate the selected frame by the given degrees (90, -90, or 180)
    func rotateSelectedFrame(by degrees: Int) {
        guard let index = selectedFrameIndex else { return }

        let oldTransform = frames[index].transform
        var newTransform = oldTransform

        switch degrees {
        case 90:
            newTransform.rotate90Clockwise()
        case -90:
            newTransform.rotate90CounterClockwise()
        case 180:
            newTransform.rotate180()
        default:
            break
        }

        let command = TransformCommand(
            frameID: frames[index].id,
            oldTransform: oldTransform,
            newTransform: newTransform,
            actionName: "Rotate Frame"
        )
        try? undoManager.perform(command, on: self)
    }

    /// Update the scale of the selected frame
    func updateSelectedFrameScale(_ scale: Double) {
        guard let index = selectedFrameIndex else { return }

        let oldTransform = frames[index].transform
        var newTransform = oldTransform
        newTransform.scale = scale

        let currentX = newTransform.offsetX
        let currentY = newTransform.offsetY
        let clamped = clampedOffset(x: currentX, y: currentY, for: frames[index], scale: scale)
        newTransform.offsetX = clamped.x
        newTransform.offsetY = clamped.y

        let command = TransformCommand(
            frameID: frames[index].id,
            oldTransform: oldTransform,
            newTransform: newTransform,
            actionName: "Scale Frame"
        )
        try? undoManager.perform(command, on: self)
    }

    /// Update the offset of the selected frame with bounds clamping
    /// Pass nil to keep the current value for that axis
    func updateSelectedFrameOffset(x: CGFloat?, y: CGFloat?) {
        guard let index = selectedFrameIndex else { return }

        let oldTransform = frames[index].transform
        var newTransform = oldTransform

        let newX = x ?? oldTransform.offsetX
        let newY = y ?? oldTransform.offsetY
        let clamped = clampedOffset(x: newX, y: newY, for: frames[index])
        newTransform.offsetX = clamped.x
        newTransform.offsetY = clamped.y

        let command = TransformCommand(
            frameID: frames[index].id,
            oldTransform: oldTransform,
            newTransform: newTransform,
            actionName: "Move Frame"
        )
        try? undoManager.perform(command, on: self)
    }

    /// Clamp offset to keep image covering the canvas
    private func clampedOffset(x: CGFloat, y: CGFloat, for frame: ImageItem, scale: Double? = nil) -> (x: CGFloat, y: CGFloat) {
        guard let image = NSImage(contentsOf: frame.url) else {
            return (x, y)
        }

        let imageSize = image.size
        let canvasSize = exportSettings.effectiveCanvasSize
        let frameScale = scale ?? frame.transform.scale

        let scaledImage = CGSize(
            width: imageSize.width * frameScale / 100,
            height: imageSize.height * frameScale / 100
        )

        // Calculate max offset that keeps image covering canvas
        let maxOffsetX = abs(scaledImage.width - canvasSize.width) / 2
        let maxOffsetY = abs(scaledImage.height - canvasSize.height) / 2

        return (
            x: max(-maxOffsetX, min(maxOffsetX, x)),
            y: max(-maxOffsetY, min(maxOffsetY, y))
        )
    }

    /// Reset the selected frame's transform to identity
    func resetSelectedFrameTransform() {
        guard let index = selectedFrameIndex else { return }

        let oldTransform = frames[index].transform
        let newTransform = FrameTransform.identity

        let command = TransformCommand(
            frameID: frames[index].id,
            oldTransform: oldTransform,
            newTransform: newTransform,
            actionName: "Reset Transform"
        )
        try? undoManager.perform(command, on: self)
    }

    /// Apply the selected frame's transform to all frames
    func applyTransformToAllFrames() {
        guard let index = selectedFrameIndex else { return }
        let transform = frames[index].transform

        for i in frames.indices {
            frames[i].transform = transform
        }
    }

    /// Apply anchor preset to selected frame
    func applyAnchorPreset(
        _ anchor: PositionAnchor,
        imageSize: CGSize,
        canvasSize: CGSize,
        scale: Double
    ) {
        guard let index = selectedFrameIndex else { return }

        let oldTransform = frames[index].transform
        var newTransform = oldTransform

        let offset = anchor.offset(imageSize: imageSize, canvasSize: canvasSize, scale: scale)
        newTransform.offsetX = offset.x
        newTransform.offsetY = offset.y

        let command = TransformCommand(
            frameID: frames[index].id,
            oldTransform: oldTransform,
            newTransform: newTransform,
            actionName: "Apply Anchor"
        )
        try? undoManager.perform(command, on: self)
    }

    // MARK: - Export

    /// Execute export with progress callback (for ExportSheet)
    func executeExportWithProgress(to url: URL, frames: [ImageItem], onProgress: @escaping (Double) -> Void) async throws {
        let frameDelaySeconds = exportSettings.frameDelay / 1000.0

        switch exportSettings.format {
        case .gif:
            try await GIFExporter.export(
                images: frames,
                to: url,
                frameDelay: frameDelaySeconds,
                loopCount: exportSettings.loopCount,
                quality: exportSettings.quality,
                dithering: exportSettings.enableDithering,
                resizeInstruction: exportSettings.resizeInstruction,
                colorDepthLevels: exportSettings.clampedColorDepthLevels > 0 ? exportSettings.clampedColorDepthLevels : nil,
                perFrameDelays: buildPerFrameDelays(),
                progressHandler: onProgress
            )

        case .apng:
            try await APNGExporter.export(
                images: frames,
                to: url,
                frameDelay: frameDelaySeconds,
                loopCount: exportSettings.loopCount,
                resizeInstruction: exportSettings.resizeInstruction,
                perFrameDelays: buildPerFrameDelays(),
                progressHandler: onProgress
            )

        case .webp:
            try await WebPExporter.export(
                images: frames,
                to: url,
                frameDelay: frameDelaySeconds,
                loopCount: exportSettings.loopCount,
                quality: exportSettings.quality,
                resizeInstruction: exportSettings.resizeInstruction,
                perFrameDelays: buildPerFrameDelays(),
                progressHandler: onProgress
            )
        }
    }

    /// Perform export with save dialog
    func performExport() {
        let framesToExport = unmutedFrames
        guard !framesToExport.isEmpty else { return }

        // Configure save panel
        let panel = NSSavePanel()
        panel.title = "Export \(exportSettings.format.rawValue)"
        panel.allowedContentTypes = [exportSettings.format.utType]
        panel.nameFieldStringValue = "animation.\(exportSettings.format.fileExtension)"
        panel.canCreateDirectories = true

        // Show panel
        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }

            Task { @MainActor in
                await self.executeExport(to: url, frames: framesToExport)
            }
        }
    }

    /// Execute the actual export operation
    private func executeExport(to url: URL, frames: [ImageItem]) async {
        isExporting = true
        exportProgress = 0.0
        exportError = nil

        do {
            // Frame delay in seconds (exporters expect seconds)
            let frameDelaySeconds = exportSettings.frameDelay / 1000.0

            switch exportSettings.format {
            case .gif:
                try await GIFExporter.export(
                    images: frames,
                    to: url,
                    frameDelay: frameDelaySeconds,
                    loopCount: exportSettings.loopCount,
                    quality: exportSettings.quality,
                    dithering: exportSettings.enableDithering,
                    resizeInstruction: exportSettings.resizeInstruction,
                    colorDepthLevels: exportSettings.clampedColorDepthLevels > 0 ? exportSettings.clampedColorDepthLevels : nil,
                    perFrameDelays: buildPerFrameDelays(),
                    progressHandler: { [weak self] progress in
                        self?.exportProgress = progress
                    }
                )

            case .apng:
                try await APNGExporter.export(
                    images: frames,
                    to: url,
                    frameDelay: frameDelaySeconds,
                    loopCount: exportSettings.loopCount,
                    resizeInstruction: exportSettings.resizeInstruction,
                    perFrameDelays: buildPerFrameDelays(),
                    progressHandler: { [weak self] progress in
                        self?.exportProgress = progress
                    }
                )

            case .webp:
                try await WebPExporter.export(
                    images: frames,
                    to: url,
                    frameDelay: frameDelaySeconds,
                    loopCount: exportSettings.loopCount,
                    quality: exportSettings.quality,
                    resizeInstruction: exportSettings.resizeInstruction,
                    perFrameDelays: buildPerFrameDelays(),
                    progressHandler: { [weak self] progress in
                        self?.exportProgress = progress
                    }
                )
            }

            // Success
            lastExportURL = url
            showExportSuccess = true

        } catch {
            exportError = error
        }

        isExporting = false
    }
}
