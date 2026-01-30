//
//  ExportSettings.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import Foundation
import CoreGraphics
import UniformTypeIdentifiers
import AppKit

// MARK: - Export Constants

enum ExportConstants {
    static let dimensionRange: ClosedRange<Double> = 64...4096
    static let frameRateRange: ClosedRange<Double> = 1...60
    static let frameDelayRange: ClosedRange<Double> = (1000.0 / 60.0)...(1000.0 / 1.0)
    static let qualityRange: ClosedRange<Double> = 0.1...1.0
    static let loopCountRange: ClosedRange<Int> = 1...100
    static let importBatchSize = 8
}

enum ExportFormat: String, CaseIterable {
    case gif = "GIF"
    case webp = "WebP"
    case apng = "APNG"

    static var implementedFormats: [ExportFormat] {
        allCases.filter { $0 != .webp }
    }

    var isImplemented: Bool {
        self != .webp
    }

    var fileExtension: String {
        switch self {
        case .gif: return "gif"
        case .webp: return "webp"
        case .apng: return "png"
        }
    }

    var utType: UTType {
        switch self {
        case .gif: return .gif
        case .webp: return .webP
        case .apng: return .png
        }
    }
}

enum SortOrder: String, CaseIterable {
    case fileName = "File Name"
    case modificationDate = "Modification Date"
    case manual = "Manual"
}

enum ScaleMode: String, CaseIterable, Identifiable {
    case fit   // Letterbox - entire image visible
    case fill  // Crop - fills frame completely

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fit: return "Fit"
        case .fill: return "Fill"
        }
    }
}

enum ResizeInstruction {
    case scale(percent: Double)
    case fill(size: CGSize)
    case fit(size: CGSize, backgroundColor: NSColor)
}

enum CanvasMode: String, CaseIterable, Identifiable {
    case original  // Use source image dimensions (no resize)
    case preset
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .original: return "Original"
        case .preset: return "Preset"
        case .custom: return "Custom"
        }
    }
}

struct ResizePresetOption: Identifiable {
    let id: String
    let label: String
    let width: Double
    let height: Double

    var displayLabel: String {
        "\(label) (\(Int(width))×\(Int(height)))"
    }
}

struct ExportPlatformPreset: Identifiable {
    let id: String
    let label: String
    let maxDimensions: CGSize
    let maxFileSizeMB: Double
    let recommendedFrameRate: Double
    let notes: String

    var formattedDimensions: String {
        "\(Int(maxDimensions.width))×\(Int(maxDimensions.height))"
    }
}

extension ResizePresetOption {
    static func presets(for format: ExportFormat) -> [ResizePresetOption] {
        switch format {
        case .gif:
            return [
                .init(id: "gif-square", label: "Square", width: 480, height: 480),
                .init(id: "gif-sd", label: "SD", width: 640, height: 480),
                .init(id: "gif-720", label: "HD 720p", width: 1280, height: 720),
                .init(id: "gif-1080", label: "HD 1080p", width: 1920, height: 1080)
            ]
        case .webp:
            return [
                .init(id: "webp-story", label: "Story", width: 1080, height: 1920),
                .init(id: "webp-720", label: "HD 720p", width: 1280, height: 720),
                .init(id: "webp-1080", label: "HD 1080p", width: 1920, height: 1080),
                .init(id: "webp-1440", label: "QHD", width: 2560, height: 1440)
            ]
        case .apng:
            return [
                .init(id: "apng-small", label: "Small", width: 512, height: 512),
                .init(id: "apng-720", label: "HD 720p", width: 1280, height: 720),
                .init(id: "apng-1080", label: "HD 1080p", width: 1920, height: 1080),
                .init(id: "apng-1440", label: "QHD", width: 2560, height: 1440)
            ]
        }
    }

    static func defaultID(for format: ExportFormat) -> String {
        presets(for: format).first?.id ?? "custom"
    }

    static func preset(for format: ExportFormat, id: String) -> ResizePresetOption? {
        presets(for: format).first { $0.id == id }
    }
}

extension ExportPlatformPreset {
    static var presets: [ExportPlatformPreset] {
        [
            .init(
                id: "whatsapp-sticker",
                label: "WhatsApp Sticker",
                maxDimensions: CGSize(width: 512, height: 512),
                maxFileSizeMB: 1,
                recommendedFrameRate: 8,
                notes: "512×512 px, < 1 MB"
            ),
            .init(
                id: "discord-emoji",
                label: "Discord Emoji",
                maxDimensions: CGSize(width: 320, height: 320),
                maxFileSizeMB: 0.48,
                recommendedFrameRate: 15,
                notes: "320×320 px, 512 KB"
            ),
            .init(
                id: "slack-sticker",
                label: "Slack Sticker",
                maxDimensions: CGSize(width: 512, height: 512),
                maxFileSizeMB: 0.98,
                recommendedFrameRate: 12,
                notes: "512×512 px, 1 MB"
            ),
            .init(
                id: "telegram-sticker",
                label: "Telegram Sticker",
                maxDimensions: CGSize(width: 512, height: 512),
                maxFileSizeMB: 1.9,
                recommendedFrameRate: 24,
                notes: "Animated sticker, < 2 MB"
            )
        ]
    }

    static func preset(id: String) -> ExportPlatformPreset? {
        presets.first { $0.id == id }
    }
}

class ExportSettings: ObservableObject {
    @Published var format: ExportFormat = .gif
    @Published var frameDelay: Double = 100 // milliseconds
    @Published var frameRate: Double = 10 // FPS
    @Published var loopCount: Int = 0 // 0 = infinite
    @Published var quality: Double = 0.8 // 0.0 to 1.0
    @Published var enableDithering: Bool = true
    @Published var sortOrder: SortOrder = .fileName
    @Published var resizeEnabled: Bool = false
    @Published var canvasMode: CanvasMode = .original
    @Published var canvasWidth: Double = 640
    @Published var canvasHeight: Double = 480
    @Published var automaticCanvasSize: CGSize?
    @Published var frameSkippingEnabled: Bool = false
    @Published var frameSkipInterval: Int = 2
    @Published var sizeLimitEnabled: Bool = false
    @Published var maxFileSizeMB: Double = 8
    @Published var selectedPlatformTargetID: String?
    @Published var scaleMode: ScaleMode = .fill  // Default: Fill (crop to fill)
    @Published var selectedPresetID: String?
    @Published var fitBackgroundColor: NSColor = .white
    @Published var useAutoBackgroundColor: Bool = true
    @Published var colorDepthEnabled: Bool = false
    @Published var colorDepthLevels: Double = 16 // corresponds to CIColorPosterize levels
    @Published var overrideCustomFrameTimings: Bool = false

    private var isUpdating = false

    // Computed property to sync frame rate with delay
    var computedFrameDelay: Double {
        get {
            if frameRate > 0 {
                return 1000.0 / frameRate
            }
            return frameDelay
        }
        set {
            frameDelay = newValue
            if newValue > 0 {
                frameRate = 1000.0 / newValue
            }
        }
    }

    func updateFrameRateFromDelay() {
        guard !isUpdating else { return }
        guard frameDelay > 0 else { return }

        isUpdating = true
        defer { isUpdating = false }

        let snappedRate = snapFrameRate(1000.0 / frameDelay)
        frameRate = snappedRate
        frameDelay = 1000.0 / snappedRate
    }

    func updateDelayFromFrameRate() {
        guard !isUpdating else { return }
        guard frameRate > 0 else { return }

        isUpdating = true
        defer { isUpdating = false }

        let snappedRate = snapFrameRate(frameRate)
        frameRate = snappedRate
        frameDelay = 1000.0 / snappedRate
    }

    private func snapFrameRate(_ value: Double) -> Double {
        min(max(value.rounded(), ExportConstants.frameRateRange.lowerBound), ExportConstants.frameRateRange.upperBound)
    }

    var resizeInstruction: ResizeInstruction? {
        // Original mode = no resize
        guard canvasMode != .original else { return nil }
        guard let target = resolvedCanvasSize else { return nil }

        switch scaleMode {
        case .fill:
            return .fill(size: target)
        case .fit:
            return .fit(size: target, backgroundColor: fitBackgroundColor)
        }
    }

    var resolvedCanvasSize: CGSize? {
        switch canvasMode {
        case .original:
            return automaticCanvasSize
        case .preset:
            guard let presetID = selectedPresetID,
                  let preset = ResizePresetOption.preset(for: format, id: presetID) else {
                return automaticCanvasSize
            }
            return CGSize(width: preset.width, height: preset.height)
        case .custom:
            let width = max(1, canvasWidth)
            let height = max(1, canvasHeight)
            return CGSize(width: width, height: height)
        }
    }

    var effectiveFrameSkipInterval: Int {
        guard frameSkippingEnabled else { return 1 }
        return max(1, frameSkipInterval)
    }

    var maxFileSizeBytes: Int64 {
        let megabytes = max(0.01, maxFileSizeMB)
        return Int64(megabytes * 1024 * 1024)
    }

    var clampedColorDepthLevels: Int {
        let levels = Int(colorDepthLevels.rounded())
        return colorDepthEnabled ? max(2, min(levels, 30)) : 0
    }

    var approximateColorCount: Int {
        let levels = clampedColorDepthLevels
        guard levels > 0 else { return 0 }
        return Int(pow(Double(levels), 3.0))
    }
}
