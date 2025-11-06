//
//  ExportSettings.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import Foundation

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

class ExportSettings: ObservableObject {
    @Published var format: ExportFormat = .gif
    @Published var frameDelay: Double = 100 // milliseconds
    @Published var frameRate: Double = 10 // FPS
    @Published var loopCount: Int = 0 // 0 = infinite
    @Published var quality: Double = 0.8 // 0.0 to 1.0
    @Published var enableDithering: Bool = true
    @Published var sortOrder: SortOrder = .fileName

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
        if frameDelay > 0 {
            frameRate = 1000.0 / frameDelay
        }
    }

    func updateDelayFromFrameRate() {
        if frameRate > 0 {
            frameDelay = 1000.0 / frameRate
        }
    }
}
