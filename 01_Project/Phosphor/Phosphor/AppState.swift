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

    // MARK: - Initialization

    init() {}

    // MARK: - Playback Control

    /// Start the playback timer based on current frame rate
    private func startPlayback() {
        guard hasFrames else {
            isPlaying = false
            return
        }

        let interval = 1.0 / exportSettings.frameRate
        playbackTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.advanceFrame()
            }
    }

    /// Stop the playback timer
    private func stopPlayback() {
        playbackTimer?.cancel()
        playbackTimer = nil
    }

    /// Advance to the next frame, wrapping around at the end
    private func advanceFrame() {
        guard hasFrames else { return }
        currentPreviewIndex = (currentPreviewIndex + 1) % frames.count
    }

    /// Toggle playback on/off
    func togglePlayback() {
        guard hasFrames else { return }
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

        let hadFrames = hasFrames
        frames.append(contentsOf: importedItems)

        if !hadFrames && hasFrames {
            selectedFrameIndex = 0
        }
    }

    /// Remove frame at the specified index
    func removeFrame(at index: Int) {
        guard frames.indices.contains(index) else { return }

        frames.remove(at: index)

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
        guard let selectedIndex = selectedFrameIndex,
              let movedIndex = source.first else {
            frames.move(fromOffsets: source, toOffset: destination)
            return
        }

        frames.move(fromOffsets: source, toOffset: destination)

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
        frames[index].isMuted.toggle()
    }

    // MARK: - Export

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
                    perFrameDelays: nil,
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
                    perFrameDelays: nil,
                    progressHandler: { [weak self] progress in
                        self?.exportProgress = progress
                    }
                )

            case .webp:
                // WebP not implemented yet
                throw ExportError.failedToCreateDestination
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
