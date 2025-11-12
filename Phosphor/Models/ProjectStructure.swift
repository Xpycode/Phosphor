//
//  ProjectStructure.swift
//  Phosphor
//
//  Created on 2025-11-12
//  Complete rewrite for NLE-style workflow
//

import Foundation
import CoreGraphics
import SwiftUI

// MARK: - Canvas Preset

struct CanvasPreset: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let width: Int
    let height: Int
    let category: String

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    var aspectRatio: Double {
        guard height > 0 else { return 1.0 }
        return Double(width) / Double(height)
    }

    var displayName: String {
        "\(name) (\(width)×\(height))"
    }

    static let presets: [CanvasPreset] = [
        // Instagram
        .init(id: "ig-square", name: "Instagram Square", width: 1080, height: 1080, category: "Instagram"),
        .init(id: "ig-portrait", name: "Instagram Portrait", width: 1080, height: 1350, category: "Instagram"),
        .init(id: "ig-story", name: "Instagram Story", width: 1080, height: 1920, category: "Instagram"),

        // Twitter
        .init(id: "tw-landscape", name: "Twitter Landscape", width: 1200, height: 675, category: "Twitter"),
        .init(id: "tw-square", name: "Twitter Square", width: 1200, height: 1200, category: "Twitter"),

        // TikTok
        .init(id: "tt-vertical", name: "TikTok", width: 1080, height: 1920, category: "TikTok"),

        // Discord
        .init(id: "dc-emoji", name: "Discord Emoji", width: 320, height: 320, category: "Discord"),
        .init(id: "dc-sticker", name: "Discord Sticker", width: 512, height: 512, category: "Discord"),

        // Standard
        .init(id: "hd-720", name: "HD 720p", width: 1280, height: 720, category: "Standard"),
        .init(id: "hd-1080", name: "HD 1080p", width: 1920, height: 1080, category: "Standard"),
    ]

    static func preset(for id: String) -> CanvasPreset? {
        presets.first { $0.id == id }
    }
}

// MARK: - Frame Fit Mode

enum FrameFitMode: String, CaseIterable, Codable {
    case fill = "Fill"
    case fit = "Fit"
    case stretch = "Stretch"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .fill: return "arrow.up.left.and.arrow.down.right"
        case .fit: return "arrow.down.right.and.arrow.up.left"
        case .stretch: return "arrow.left.and.right"
        case .custom: return "crop"
        }
    }
}

// MARK: - Media Bin

class MediaBin: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var items: [ImageItem] = []
    @Published var isExpanded: Bool = true

    init(name: String) {
        self.name = name
    }

    func addItem(_ item: ImageItem) {
        items.append(item)
    }

    func addItems(_ newItems: [ImageItem]) {
        items.append(contentsOf: newItems)
    }

    func removeItem(_ item: ImageItem) {
        items.removeAll { $0.id == item.id }
    }
}

// MARK: - Sequence Frame

class SequenceFrame: ObservableObject, Identifiable {
    let id = UUID()
    let imageID: UUID
    @Published var customDelay: Double? // milliseconds
    @Published var fitMode: FrameFitMode = .fill
    @Published var customCrop: CGRect? // For custom fit mode
    @Published var isEnabled: Bool = true

    init(imageID: UUID, fitMode: FrameFitMode = .fill) {
        self.imageID = imageID
        self.fitMode = fitMode
    }
}

// MARK: - Sequence

class Sequence: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var width: Int
    @Published var height: Int
    @Published var frameRate: Double // fps
    @Published var defaultFitMode: FrameFitMode = .fill
    @Published var loopCount: Int = 0 // 0 = infinite
    @Published var frames: [SequenceFrame] = []

    var canvasSize: CGSize {
        CGSize(width: width, height: height)
    }

    var frameDelay: Double {
        guard frameRate > 0 else { return 100 }
        return 1000.0 / frameRate
    }

    var aspectRatio: Double {
        guard height > 0 else { return 1.0 }
        return Double(width) / Double(height)
    }

    var enabledFrames: [SequenceFrame] {
        frames.filter { $0.isEnabled }
    }

    init(name: String, width: Int, height: Int, frameRate: Double, defaultFitMode: FrameFitMode = .fill) {
        self.name = name
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.defaultFitMode = defaultFitMode
    }

    func addFrame(imageID: UUID) {
        let frame = SequenceFrame(imageID: imageID, fitMode: defaultFitMode)
        frames.append(frame)
    }

    func addFrames(imageIDs: [UUID]) {
        let newFrames = imageIDs.map { SequenceFrame(imageID: $0, fitMode: defaultFitMode) }
        frames.append(contentsOf: newFrames)
    }

    func insertFrame(imageID: UUID, at index: Int) {
        let frame = SequenceFrame(imageID: imageID, fitMode: defaultFitMode)
        frames.insert(frame, at: index)
    }

    func removeFrame(at index: Int) {
        guard index >= 0 && index < frames.count else { return }
        frames.remove(at: index)
    }

    func moveFrames(from source: IndexSet, to destination: Int) {
        frames.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Sequence Container (Bin or loose)

class SequenceContainer: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var sequences: [Sequence] = []
    @Published var isExpanded: Bool = true
    let isBin: Bool // true = bin (folder), false = loose sequence

    init(name: String, isBin: Bool = false) {
        self.name = name
        self.isBin = isBin
    }

    func addSequence(_ sequence: Sequence) {
        sequences.append(sequence)
    }

    func removeSequence(_ sequence: Sequence) {
        sequences.removeAll { $0.id == sequence.id }
    }
}

// MARK: - Project (Root)

class Project: ObservableObject {
    @Published var mediaBins: [MediaBin] = []
    @Published var sequenceContainers: [SequenceContainer] = []
    @Published var activeSequenceID: UUID?

    // Default bins
    var defaultMediaBin: MediaBin {
        if let existing = mediaBins.first(where: { $0.name == "All Media" }) {
            return existing
        }
        let bin = MediaBin(name: "All Media")
        mediaBins.insert(bin, at: 0)
        return bin
    }

    var activeSequence: Sequence? {
        guard let id = activeSequenceID else { return nil }
        for container in sequenceContainers {
            if let seq = container.sequences.first(where: { $0.id == id }) {
                return seq
            }
        }
        return nil
    }

    func allImages() -> [ImageItem] {
        mediaBins.flatMap { $0.items }
    }

    func image(for id: UUID) -> ImageItem? {
        allImages().first { $0.id == id }
    }

    func createMediaBin(name: String) -> MediaBin {
        let bin = MediaBin(name: name)
        mediaBins.append(bin)
        return bin
    }

    func createSequence(name: String, width: Int, height: Int, frameRate: Double, fitMode: FrameFitMode, inBin: Bool = false, binName: String? = nil) -> Sequence {
        let sequence = Sequence(name: name, width: width, height: height, frameRate: frameRate, defaultFitMode: fitMode)

        if inBin {
            // Find or create bin
            let targetBinName = binName ?? "Sequences"
            if let existingBin = sequenceContainers.first(where: { $0.name == targetBinName && $0.isBin }) {
                existingBin.addSequence(sequence)
            } else {
                let newBin = SequenceContainer(name: targetBinName, isBin: true)
                newBin.addSequence(sequence)
                sequenceContainers.append(newBin)
            }
        } else {
            // Add as loose sequence
            let container = SequenceContainer(name: sequence.name, isBin: false)
            container.sequences = [sequence]
            sequenceContainers.append(container)
        }

        activeSequenceID = sequence.id
        return sequence
    }

    func deleteSequence(_ sequence: Sequence) {
        for container in sequenceContainers {
            container.removeSequence(sequence)
        }
        // Remove empty containers
        sequenceContainers.removeAll { !$0.isBin && $0.sequences.isEmpty }

        if activeSequenceID == sequence.id {
            activeSequenceID = nil
        }
    }
}
