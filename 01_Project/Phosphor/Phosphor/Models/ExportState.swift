//
//  ExportState.swift
//  Phosphor
//
//  Export workflow state machine
//

import Foundation

enum ExportState: Equatable {
    case idle
    case configuring
    case exporting(progress: Double)
    case completed(url: URL)
    case failed(error: String)

    var isExporting: Bool {
        if case .exporting = self { return true }
        return false
    }
}
