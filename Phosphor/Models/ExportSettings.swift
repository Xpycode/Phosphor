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
    @Published var loopCount: Int = 0 // 0 = infinite
    @Published var quality: Double = 0.8 // 0.0 to 1.0
    @Published var enableDithering: Bool = true
    @Published var sortOrder: SortOrder = .fileName

    // Internal storage for timing values
    private var _frameDelay: Double = 100 // milliseconds
    private var _frameRate: Double = 10 // FPS

    // Public computed properties that handle synchronization
    var frameDelay: Double {
        get { _frameDelay }
        set {
            if newValue != _frameDelay && newValue > 0 {
                _frameDelay = newValue
                _frameRate = 1000.0 / newValue
                objectWillChange.send()
            }
        }
    }

    var frameRate: Double {
        get { _frameRate }
        set {
            if newValue != _frameRate && newValue > 0 {
                _frameRate = newValue
                _frameDelay = 1000.0 / newValue
                objectWillChange.send()
            }
        }
    }

    // Helper computed property for consistent delay calculation
    var delayInSeconds: Double {
        return _frameDelay / 1000.0
    }

    init() {
        // Set initial values consistently
        _frameRate = 10
        _frameDelay = 100
    }
}
