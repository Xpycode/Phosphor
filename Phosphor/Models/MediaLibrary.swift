//
//  MediaLibrary.swift
//  Phosphor
//
//  Created on 2025-11-12
//

import Foundation
import SwiftUI
import Combine

/// Global media library that holds all imported images
/// Images can be referenced by multiple sequences (NLE-style workflow)
class MediaLibrary: ObservableObject {
    @Published var items: [ImageItem] = []
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0

    private var importTaskID = UUID()
    private var currentImportTask: Task<Void, Never>?
    private let importFlushBatchSize = 8

    var isEmpty: Bool {
        items.isEmpty
    }

    var count: Int {
        items.count
    }

    func item(for id: UUID) -> ImageItem? {
        items.first { $0.id == id }
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
                            self.items.append(contentsOf: flushedItems)
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

    func removeItem(_ item: ImageItem) {
        items.removeAll { $0.id == item.id }
    }

    func removeItems(_ itemsToRemove: [ImageItem]) {
        let idsToRemove = Set(itemsToRemove.map { $0.id })
        items.removeAll { idsToRemove.contains($0.id) }
    }

    func clearAll() {
        items.removeAll()
    }

    /// Compute aspect ratio warnings for items against a target canvas
    func aspectRatioMismatch(for item: ImageItem, targetCanvas: CGSize, tolerance: Double = 0.02) -> Bool {
        guard targetCanvas.height > 0, item.resolution.height > 0 else { return false }
        let targetRatio = targetCanvas.width / targetCanvas.height
        let itemRatio = item.resolution.width / item.resolution.height
        return abs(targetRatio - itemRatio) > tolerance
    }
}
