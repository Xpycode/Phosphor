//
//  WorkspaceState.swift
//  Phosphor
//
//  Created on 2025-11-13
//  Manages visibility state for the 6-pane workspace
//

import Foundation
import SwiftUI

/// Manages which panes are visible in the workspace
class WorkspaceState: ObservableObject {
    // Pane visibility
    @Published var showSequences: Bool = false
    @Published var showMedia: Bool = false
    @Published var showSequenceSettings: Bool = false
    @Published var showExport: Bool = false

    // Viewer and Timeline are always visible (core panes)
    var showViewer: Bool { true }
    var showTimeline: Bool { true }

    /// Show media pane (triggered by import)
    func revealMediaPane() {
        showMedia = true
    }

    /// Show sequences pane (triggered by first sequence creation)
    func revealSequencesPane() {
        showSequences = true
    }

    /// Toggle sequence settings pane
    func toggleSequenceSettings() {
        showSequenceSettings.toggle()
    }

    /// Show export pane (triggered by export button)
    func revealExportPane() {
        showExport = true
    }

    /// Hide export pane
    func hideExportPane() {
        showExport = false
    }

    /// Reset to initial state (only Viewer + Timeline visible)
    func resetToMinimal() {
        showSequences = false
        showMedia = false
        showSequenceSettings = false
        showExport = false
    }

    /// Show all panes (for advanced users)
    func showAll() {
        showSequences = true
        showMedia = true
        showSequenceSettings = true
        showExport = true
    }
}
