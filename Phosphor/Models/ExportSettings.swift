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

    // Single source of truth - frameDelay in milliseconds
    @Published var frameDelay: Double = 100

    // Computed property - frameRate in FPS (calculated from frameDelay: fps = 1000 / delay)
    var frameRate: Double {
        get {
            1000.0 / frameDelay
        }
        set {
            frameDelay = 1000.0 / newValue
        }
    }
}
