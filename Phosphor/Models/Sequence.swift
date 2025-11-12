//
//  Sequence.swift
//  Phosphor
//
//  Created on 2025-11-12
//

import Foundation
import CoreGraphics

/// Represents a canvas preset for common social media and output formats
struct CanvasPreset: Identifiable, Equatable {
    let id: String
    let label: String
    let size: CGSize
    let category: PresetCategory

    enum PresetCategory: String, CaseIterable {
        case instagram = "Instagram"
        case twitter = "Twitter"
        case tiktok = "TikTok"
        case discord = "Discord"
        case custom = "Custom"
    }

    var displayLabel: String {
        "\(label) (\(Int(size.width))×\(Int(size.height)))"
    }

    var aspectRatioValue: Double {
        guard size.height > 0 else { return 1.0 }
        return size.width / size.height
    }

    var aspectRatioLabel: String {
        let widthInt = Int(size.width)
        let heightInt = Int(size.height)
        let divisor = gcd(widthInt, heightInt)
        let simplifiedWidth = widthInt / divisor
        let simplifiedHeight = heightInt / divisor
        return "\(simplifiedWidth):\(simplifiedHeight)"
    }
}

extension CanvasPreset {
    /// Social media and common canvas presets
    static let presets: [CanvasPreset] = [
        // Instagram
        .init(id: "ig-square", label: "Square", size: CGSize(width: 1080, height: 1080), category: .instagram),
        .init(id: "ig-portrait", label: "Portrait", size: CGSize(width: 1080, height: 1350), category: .instagram),
        .init(id: "ig-story", label: "Story", size: CGSize(width: 1080, height: 1920), category: .instagram),

        // Twitter
        .init(id: "tw-landscape", label: "Landscape", size: CGSize(width: 1200, height: 675), category: .twitter),
        .init(id: "tw-square", label: "Square", size: CGSize(width: 1200, height: 1200), category: .twitter),

        // TikTok
        .init(id: "tt-vertical", label: "Vertical", size: CGSize(width: 1080, height: 1920), category: .tiktok),

        // Discord
        .init(id: "dc-emoji", label: "Emoji", size: CGSize(width: 320, height: 320), category: .discord),
        .init(id: "dc-sticker", label: "Sticker", size: CGSize(width: 512, height: 512), category: .discord),
    ]

    static func preset(for id: String) -> CanvasPreset? {
        presets.first { $0.id == id }
    }

    static func presetsForCategory(_ category: PresetCategory) -> [CanvasPreset] {
        presets.filter { $0.category == category }
    }

    /// Auto-detect canvas size based on the first image's dimensions
    static func autoDetect(from size: CGSize) -> CanvasPreset {
        // Try to match against known presets
        for preset in presets {
            if abs(preset.size.width - size.width) < 1.0 && abs(preset.size.height - size.height) < 1.0 {
                return preset
            }
        }

        // Create a custom preset with the detected size
        return .init(
            id: "auto-\(Int(size.width))x\(Int(size.height))",
            label: "Auto",
            size: size,
            category: .custom
        )
    }
}

/// Represents a frame within a sequence, with ordering and per-frame settings
struct SequenceFrame: Identifiable, Equatable {
    let id: UUID
    let imageID: UUID  // References ImageItem.id from MediaLibrary
    var customDelay: Double?  // Optional per-frame delay override in milliseconds
    var isEnabled: Bool  // Whether to include in export

    init(imageID: UUID, customDelay: Double? = nil, isEnabled: Bool = true) {
        self.id = UUID()
        self.imageID = imageID
        self.customDelay = customDelay
        self.isEnabled = isEnabled
    }
}

/// Represents a sequence/project with canvas size, frame rate, and frame ordering
class PhosphorSequence: ObservableObject, Identifiable {
    let id: UUID
    @Published var name: String
    @Published var canvasPreset: CanvasPreset
    @Published var customCanvasSize: CGSize?  // Used when preset is custom
    @Published var frameRate: Double  // FPS
    @Published var loopCount: Int  // 0 = infinite
    @Published var frames: [SequenceFrame]
    @Published var createdDate: Date
    @Published var modifiedDate: Date

    var displayName: String {
        name.isEmpty ? "Untitled Sequence" : name
    }

    var resolvedCanvasSize: CGSize {
        if canvasPreset.category == .custom, let custom = customCanvasSize {
            return custom
        }
        return canvasPreset.size
    }

    var frameDelay: Double {
        guard frameRate > 0 else { return 100 }
        return 1000.0 / frameRate
    }

    var enabledFrames: [SequenceFrame] {
        frames.filter { $0.isEnabled }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        canvasPreset: CanvasPreset = .presets[0],
        customCanvasSize: CGSize? = nil,
        frameRate: Double = 10,
        loopCount: Int = 0,
        frames: [SequenceFrame] = []
    ) {
        self.id = id
        self.name = name
        self.canvasPreset = canvasPreset
        self.customCanvasSize = customCanvasSize
        self.frameRate = frameRate
        self.loopCount = loopCount
        self.frames = frames
        self.createdDate = Date()
        self.modifiedDate = Date()
    }

    func addFrame(imageID: UUID) {
        let frame = SequenceFrame(imageID: imageID)
        frames.append(frame)
        modifiedDate = Date()
    }

    func addFrames(imageIDs: [UUID]) {
        let newFrames = imageIDs.map { SequenceFrame(imageID: $0) }
        frames.append(contentsOf: newFrames)
        modifiedDate = Date()
    }

    func removeFrame(at index: Int) {
        guard index >= 0 && index < frames.count else { return }
        frames.remove(at: index)
        modifiedDate = Date()
    }

    func moveFrames(from source: IndexSet, to destination: Int) {
        frames.move(fromOffsets: source, toOffset: destination)
        modifiedDate = Date()
    }

    func setFrameDelay(for frameID: UUID, delay: Double?) {
        if let index = frames.firstIndex(where: { $0.id == frameID }) {
            frames[index].customDelay = delay
            modifiedDate = Date()
        }
    }

    func toggleFrameEnabled(frameID: UUID) {
        if let index = frames.firstIndex(where: { $0.id == frameID }) {
            frames[index].isEnabled.toggle()
            modifiedDate = Date()
        }
    }

    func updateCanvasSize(_ size: CGSize, asCustom: Bool = false) {
        if asCustom {
            customCanvasSize = size
            canvasPreset = CanvasPreset(
                id: "custom-\(Int(size.width))x\(Int(size.height))",
                label: "Custom",
                size: size,
                category: .custom
            )
        } else {
            canvasPreset = CanvasPreset.autoDetect(from: size)
        }
        modifiedDate = Date()
    }
}

private func gcd(_ a: Int, _ b: Int) -> Int {
    var x = abs(a)
    var y = abs(b)
    while y != 0 {
        let remainder = x % y
        x = y
        y = remainder
    }
    return max(x, 1)
}
