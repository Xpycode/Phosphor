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

    private var playbackTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

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

    var currentImage: NSImage? {
        guard !sortedImages.isEmpty, currentFrameIndex < sortedImages.count else { return nil }
        return NSImage(contentsOf: sortedImages[currentFrameIndex].url)
    }

    var totalFrames: Int {
        sortedImages.count
    }

    init() {
        // Forward settings objectWillChange to this view model for proper SwiftUI updates
        settings.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Observe settings changes to update frame rate/delay synchronization
        settings.$frameRate
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.settings.updateDelayFromFrameRate()
            }
            .store(in: &cancellables)

        settings.$frameDelay
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.settings.updateFrameRateFromDelay()
            }
            .store(in: &cancellables)
    }

    func addImages(from urls: [URL]) {
        let newItems = urls.compactMap { ImageItem.from(url: $0) }
        imageItems.append(contentsOf: newItems)
    }

    func removeImage(_ item: ImageItem) {
        imageItems.removeAll { $0.id == item.id }
        if currentFrameIndex >= imageItems.count && currentFrameIndex > 0 {
            currentFrameIndex = imageItems.count - 1
        }
    }

    func clearAll() {
        imageItems.removeAll()
        currentFrameIndex = 0
        stopPlayback()
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        imageItems.move(fromOffsets: source, toOffset: destination)
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

        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: settings.frameDelay / 1000.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.nextFrame()
            }
        }
    }

    func stopPlayback() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func nextFrame() {
        guard !sortedImages.isEmpty else { return }
        currentFrameIndex = (currentFrameIndex + 1) % sortedImages.count
    }

    func previousFrame() {
        guard !sortedImages.isEmpty else { return }
        currentFrameIndex = (currentFrameIndex - 1 + sortedImages.count) % sortedImages.count
    }

    func seekToFrame(_ index: Int) {
        guard index >= 0 && index < sortedImages.count else { return }
        currentFrameIndex = index
    }

    // MARK: - Export

    func exportAnimation(to url: URL) async throws {
        isExporting = true
        exportProgress = 0.0

        defer {
            isExporting = false
            exportProgress = 0.0
        }

        let images = sortedImages

        switch settings.format {
        case .gif:
            try await GIFExporter.export(
                images: images,
                to: url,
                frameDelay: settings.frameDelay / 1000.0,
                loopCount: settings.loopCount,
                quality: settings.quality,
                dithering: settings.enableDithering,
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
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.exportProgress = progress
                    }
                }
            )
        }
    }
}
