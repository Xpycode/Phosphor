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
    private var currentImportTask: Task<Void, Never>?

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

    var currentImage: NSImage? {
        guard !sortedImages.isEmpty, currentFrameIndex < sortedImages.count else { return nil }
        return NSImage(contentsOf: sortedImages[currentFrameIndex].url)
    }

    var totalFrames: Int {
        sortedImages.count
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
                        self.applyAutomaticSort(order: self.lastAutomaticSortOrder)
                    } else {
                        self.lastAutomaticSortOrder = newOrder
                    }
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

                if importBuffer.count == 8 || index == urlsCopy.count - 1 || Task.isCancelled {
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
        exportCompletionDate = nil

        defer {
            isExporting = false
            exportProgress = 0.0
        }

        let images = sortedImages

        let resizeConfiguration = settings.activeResizeConfiguration

        switch settings.format {
        case .gif:
            try await GIFExporter.export(
                images: images,
                to: url,
                frameDelay: settings.frameDelay / 1000.0,
                loopCount: settings.loopCount,
                quality: settings.quality,
                dithering: settings.enableDithering,
                resizeConfiguration: resizeConfiguration,
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
                resizeConfiguration: resizeConfiguration,
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
                resizeConfiguration: resizeConfiguration,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.exportProgress = progress
                    }
                }
            )
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
}
