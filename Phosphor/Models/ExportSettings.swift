//
//  ExportSettings.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import Foundation
import CoreGraphics

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

    var fileExtension: String {
        switch self {
        case .gif: return "gif"
        case .webp: return "webp"
        case .apng: return "png"
        }
    }
}

enum SortOrder: String, CaseIterable {
    case fileName = "File Name"
    case modificationDate = "Modification Date"
    case manual = "Manual"
}

enum ResizeMode: String, CaseIterable {
    case common
    case custom
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

struct ExportResizeConfiguration {
    let targetSize: CGSize
    let preserveAspectRatio: Bool
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
    @Published var resizeWidth: Double = 640
    @Published var resizeHeight: Double = 480
    @Published var resizeMode: ResizeMode = .common
    @Published var selectedResizePresetID: String = ResizePresetOption.defaultID(for: .gif)
    @Published var maintainAspectRatio: Bool = true

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

    var activeResizeConfiguration: ExportResizeConfiguration? {
        guard resizeEnabled else { return nil }
        let width = max(1, resizeWidth)
        let height = max(1, resizeHeight)
        let size = CGSize(width: CGFloat(width), height: CGFloat(height))
        return ExportResizeConfiguration(
            targetSize: size,
            preserveAspectRatio: maintainAspectRatio
        )
    }
}
