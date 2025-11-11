//
//  AppViewModel.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var imageItems: [ImageItem] = []
    @Published var settings = ExportSettings()
    @Published var isPlaying = false
    @Published var currentFrameIndex = 0
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var exportCompletionDate: Date?
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var importTaskID = UUID()
    @Published var customFrameDelays: [UUID: Double] = [:] // ms override per frame
    private var currentImportTask: Task<Void, Never>?
    private let importFlushBatchSize = 8 // small batches keep memory low while smoothing progress updates

    private var playbackTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastAutomaticSortOrder: SortOrder = .fileName

    var sortedImages: [ImageItem] {
        switch settings.sortOrder {
        case .fileName:
            return imageItems.sorted { $0.fileName.localizedStandardCompare($1.fileName) == .orderedAscending }
        case .modificationDate:
            return imageItems.sorted { $0.modificationDate < $1.modificationDate }
        case .manual:
            return imageItems
        }
    }

    var currentImageItem: ImageItem? {
        guard !sortedImages.isEmpty, currentFrameIndex < sortedImages.count else { return nil }
        return sortedImages[currentFrameIndex]
    }

    var currentImage: NSImage? {
        guard !sortedImages.isEmpty, currentFrameIndex < sortedImages.count else { return nil }
        return NSImage(contentsOf: sortedImages[currentFrameIndex].url)
    }

    var totalFrames: Int {
        sortedImages.count
    }

    var exportCandidateImages: [ImageItem] {
        let interval = settings.effectiveFrameSkipInterval
        guard interval > 1 else { return sortedImages }
        guard !sortedImages.isEmpty else { return [] }
        return stride(from: 0, to: sortedImages.count, by: interval).map { sortedImages[$0] }
    }

    var exportFrameCount: Int {
        exportCandidateImages.count
    }

    private let aspectTolerance: Double = 0.02

    var dominantAspectRatio: Double? {
        let ratios = sortedImages.compactMap { $0.aspectRatioValue }
        guard !ratios.isEmpty else { return nil }
        var buckets: [(ratio: Double, count: Int)] = []
        for ratio in ratios {
            if let index = buckets.firstIndex(where: { abs($0.ratio - ratio) <= aspectTolerance }) {
                buckets[index].count += 1
            } else {
                buckets.append((ratio, 1))
            }
        }
        return buckets.max(by: { $0.count < $1.count })?.ratio
    }

    var referenceAspectRatio: Double? {
        if let dominantAspectRatio {
            return dominantAspectRatio
        }
        return sortedImages.first?.aspectRatioValue
    }

    var hasMixedAspectRatios: Bool {
        guard let target = referenceAspectRatio else { return false }
        return sortedImages.contains { item in
            guard let ratio = item.aspectRatioValue else { return false }
            return abs(ratio - target) > aspectTolerance
        }
    }

    var dominantAspectLabel: String? {
        guard let ratio = dominantAspectRatio else { return nil }
        guard let sample = sortedImages.first(where: { item in
            guard let value = item.aspectRatioValue else { return false }
            return abs(value - ratio) <= aspectTolerance
        }) else { return nil }
        return sample.aspectRatioLabel
    }

    func delayForFrame(at index: Int) -> Double {
        guard index >= 0 && index < sortedImages.count else { return settings.frameDelay }
        if settings.overrideCustomFrameTimings {
            return settings.frameDelay
        }
        let item = sortedImages[index]
        return customFrameDelays[item.id] ?? settings.frameDelay
    }

    func delayForImage(_ item: ImageItem) -> Double {
        if settings.overrideCustomFrameTimings {
            return settings.frameDelay
        }
        return customFrameDelays[item.id] ?? settings.frameDelay
    }

    var hasCustomFrameDelays: Bool {
        !customFrameDelays.isEmpty
    }

    var estimatedExportSizeBytes: Int64? {
        let frames = exportCandidateImages
        guard !frames.isEmpty else { return nil }
        let totalBytes = frames.reduce(into: Int64(0)) { $0 += $1.fileSize }
        guard totalBytes > 0 else { return nil }

        var compressionFactor: Double
        switch settings.format {
        case .gif:
            compressionFactor = 0.38
        case .webp:
            compressionFactor = 0.22
        case .apng:
            compressionFactor = 0.9
        }

        let qualityFactor = 0.6 + (settings.quality * 0.4)
        let colorDepthFactor = settings.colorDepthEnabled
            ? max(0.2, Double(settings.clampedColorDepthLevels) / 30.0)
            : 1.0

        var resizeFactor = 1.0
        if settings.resizeEnabled {
            switch settings.resizeMode {
            case .common:
                let scalePercent = max(settings.resizeScalePercent, 1)
                let scale = scalePercent / 100.0
                // Area scales with square of the linear percentage
                let areaRatio = scale * scale
                resizeFactor = max(0.01, min(areaRatio, 1.0))
            case .custom:
                let averageArea = frames
                    .map { Double($0.resolution.width * $0.resolution.height) }
                    .reduce(0, +) / Double(frames.count)
                if averageArea > 0 {
                    let targetArea = settings.resizeWidth * settings.resizeHeight
                    let ratio = targetArea / averageArea
                    resizeFactor = max(0.1, min(ratio, 1.0))
                }
            }
        }

        let estimatedBytes = Double(totalBytes)
            * compressionFactor
            * qualityFactor
            * resizeFactor
            * colorDepthFactor
        return Int64(estimatedBytes)
    }

    var estimatedExportSizeString: String? {
        guard let bytes = estimatedExportSizeBytes else { return nil }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    var exportSizeLimitBytes: Int64? {
        settings.sizeLimitEnabled ? settings.maxFileSizeBytes : nil
    }

    var estimatedExceedsSizeLimit: Bool {
        guard let limit = exportSizeLimitBytes, let estimate = estimatedExportSizeBytes else {
            return false
        }
        return estimate > limit
    }

    init() {
        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.objectWillChange.send()
                if !self.isExporting {
                    self.exportCompletionDate = nil
                }
            }
            .store(in: &cancellables)

        // Observe settings changes to update frame rate/delay synchronization
        settings.$frameRate
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.settings.updateDelayFromFrameRate()
                }
            }
            .store(in: &cancellables)

        settings.$frameDelay
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.settings.updateFrameRateFromDelay()
                }
            }
            .store(in: &cancellables)

        settings.$sortOrder
            .dropFirst()
            .sink { [weak self] newOrder in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if newOrder == .manual {
                        return
                    }

                    self.lastAutomaticSortOrder = newOrder
                    self.applyAutomaticSort(order: newOrder)
                }
            }
            .store(in: &cancellables)
    }

    func addImages(from urls: [URL]) {
        guard !urls.isEmpty else { return }

        isImporting = true
        importProgress = 0.0

        currentImportTask?.cancel()

        let taskID = UUID()
        importTaskID = taskID

        currentImportTask = Task(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let urlsCopy = urls
            var importBuffer: [ImageItem] = []
            let total = urlsCopy.count

            for (index, url) in urlsCopy.enumerated() {
                if Task.isCancelled { break }

                autoreleasepool {
                    if let item = ImageItem.from(url: url) {
                        importBuffer.append(item)
                    }
                }

                if importBuffer.count == importFlushBatchSize || index == urlsCopy.count - 1 || Task.isCancelled {
                    let flushedItems = importBuffer
                    importBuffer.removeAll(keepingCapacity: true)

                    await MainActor.run {
                        if self.importTaskID == taskID {
                            self.imageItems.append(contentsOf: flushedItems)
                            self.importProgress = Double(index + 1) / Double(max(total, 1))
                        }
                    }
                } else {
                    await MainActor.run {
                        if self.importTaskID == taskID {
                            self.importProgress = Double(index + 1) / Double(max(total, 1))
                        }
                    }
                }
            }

            await MainActor.run {
                if self.importTaskID == taskID {
                    self.importProgress = 0.0
                    self.isImporting = false
                    self.currentImportTask = nil
                }
            }
        }
    }

    func cancelImport() {
        currentImportTask?.cancel()
        currentImportTask = nil
        importTaskID = UUID()
        importProgress = 0.0
        isImporting = false
    }

    func removeImage(_ item: ImageItem) {
        imageItems.removeAll { $0.id == item.id }
        customFrameDelays.removeValue(forKey: item.id)
        let visibleCount = sortedImages.count
        if visibleCount == 0 {
            currentFrameIndex = 0
        } else if currentFrameIndex >= visibleCount {
            currentFrameIndex = max(visibleCount - 1, 0)
        }
    }

    func clearAll() {
        imageItems.removeAll()
        currentFrameIndex = 0
        stopPlayback()
        customFrameDelays.removeAll()
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        imageItems.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Frame Timing

    func setCustomFrameDelay(for item: ImageItem, delay: Double) {
        let clamped = min(max(delay, 10), 1000)
        customFrameDelays[item.id] = clamped
    }

    func resetCustomFrameDelay(for item: ImageItem) {
        customFrameDelays.removeValue(forKey: item.id)
    }

    func resetAllCustomFrameDelays() {
        customFrameDelays.removeAll()
    }

    func perFrameDelays(for exportFrames: [ImageItem]) -> [Double] {
        if settings.overrideCustomFrameTimings {
            return Array(repeating: settings.frameDelay, count: exportFrames.count)
        }
        return exportFrames.map { customFrameDelays[$0.id] ?? settings.frameDelay }
    }

    var currentFrameDelayValue: Double {
        delayForFrame(at: currentFrameIndex)
    }

    func setCurrentFrameDelay(_ delay: Double) {
        guard let item = currentImageItem else { return }
        setCustomFrameDelay(for: item, delay: delay)
    }

    func resetCurrentFrameDelay() {
        guard let item = currentImageItem else { return }
        resetCustomFrameDelay(for: item)
    }

    // MARK: - Playback Controls

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    func startPlayback() {
        guard !sortedImages.isEmpty else { return }
        isPlaying = true

        scheduleNextPlaybackTick()
    }

    func stopPlayback() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func nextFrame(reschedule: Bool = true) {
        guard !sortedImages.isEmpty else { return }
        currentFrameIndex = (currentFrameIndex + 1) % sortedImages.count
        if isPlaying && reschedule {
            scheduleNextPlaybackTick()
        }
    }

    func previousFrame(reschedule: Bool = true) {
        guard !sortedImages.isEmpty else { return }
        currentFrameIndex = (currentFrameIndex - 1 + sortedImages.count) % sortedImages.count
        if isPlaying && reschedule {
            scheduleNextPlaybackTick()
        }
    }

    func seekToFrame(_ index: Int) {
        guard index >= 0 && index < sortedImages.count else { return }
        currentFrameIndex = index
        if isPlaying {
            scheduleNextPlaybackTick()
        }
    }

    private func scheduleNextPlaybackTick() {
        playbackTimer?.invalidate()
        guard isPlaying, !sortedImages.isEmpty else { return }
        let delayMilliseconds = delayForFrame(at: currentFrameIndex)
        let interval = max(0.01, delayMilliseconds / 1000.0)
        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.isPlaying else { return }
                self.nextFrame(reschedule: false)
                self.scheduleNextPlaybackTick()
            }
        }
    }

    // MARK: - Export

    func exportAnimation(to url: URL) async throws {
        isExporting = true
        exportProgress = 0.0
        exportCompletionDate = nil

        defer {
            isExporting = false
            exportProgress = 0.0
        }

        let images = exportCandidateImages
        guard !images.isEmpty else {
            throw ExportError.noImages
        }

        let resizeInstruction = settings.resizeInstruction
        let dominantAspectRatio = referenceAspectRatio
        let sizeLimitBytes = exportSizeLimitBytes
        let colorDepthLevels = settings.clampedColorDepthLevels
        let perFrameDelays = perFrameDelays(for: images)

        switch settings.format {
        case .gif:
            try await GIFExporter.export(
                images: images,
                to: url,
                frameDelay: settings.frameDelay / 1000.0,
                loopCount: settings.loopCount,
                quality: settings.quality,
                dithering: settings.enableDithering,
                resizeInstruction: resizeInstruction,
                dominantAspectRatio: dominantAspectRatio,
                colorDepthLevels: colorDepthLevels > 0 ? colorDepthLevels : nil,
                perFrameDelays: perFrameDelays,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.exportProgress = progress
                    }
                }
            )
        case .webp:
            try await WebPExporter.export(
                images: images,
                to: url,
                frameDelay: settings.frameDelay / 1000.0,
                loopCount: settings.loopCount,
                quality: settings.quality,
                resizeInstruction: resizeInstruction,
                dominantAspectRatio: dominantAspectRatio,
                perFrameDelays: perFrameDelays,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.exportProgress = progress
                    }
                }
            )
        case .apng:
            try await APNGExporter.export(
                images: images,
                to: url,
                frameDelay: settings.frameDelay / 1000.0,
                loopCount: settings.loopCount,
                resizeInstruction: resizeInstruction,
                dominantAspectRatio: dominantAspectRatio,
                perFrameDelays: perFrameDelays,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.exportProgress = progress
                    }
                }
            )
        }

        if let limit = sizeLimitBytes {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let actualSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
            if actualSize > limit {
                try? FileManager.default.removeItem(at: url)
                throw ExportError.fileSizeLimitExceeded(maxBytes: limit, actualBytes: actualSize)
            }
        }

        exportCompletionDate = Date()
    }

    private func applyAutomaticSort(order: SortOrder) {
        switch order {
        case .fileName:
            imageItems.sort { $0.fileName.localizedStandardCompare($1.fileName) == .orderedAscending }
        case .modificationDate:
            imageItems.sort { $0.modificationDate < $1.modificationDate }
        case .manual:
            break
        }
    }

    func isAspectOutlier(_ item: ImageItem) -> Bool {
        guard let target = referenceAspectRatio, let ratio = item.aspectRatioValue else { return false }
        return abs(ratio - target) > aspectTolerance
    }

    func aspectRatioLabel(for item: ImageItem) -> String {
        item.aspectRatioLabel
    }

    func scaledSize(for percent: Double, relativeTo item: ImageItem?) -> CGSize? {
        let referenceItem = item ?? sortedImages.first
        guard let referenceItem else { return nil }
        let factor = max(percent, 1) / 100.0
        let width = Double(referenceItem.resolution.width) * factor
        let height = Double(referenceItem.resolution.height) * factor
        guard width.isFinite, height.isFinite else { return nil }
        return CGSize(width: max(width, 1), height: max(height, 1))
    }
}
