//
//  ContentView.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        HSplitView {
            // Left column: Preview (top) + Toolbar + Timeline (bottom)
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Preview area
                    PreviewPane(appState: appState, settings: appState.exportSettings)
                        .frame(minHeight: 300)

                    // Divider between preview and timeline section
                    Divider()

                    // Timeline section (toolbar + thumbnails) with darker background
                    VStack(spacing: 0) {
                        UnifiedToolbar(
                            appState: appState,
                            availableWidth: geometry.size.width,
                            onImport: showImportPanel
                        )

                        Divider()

                        TimelinePane(appState: appState, onImport: showImportPanel)
                            .frame(minHeight: 120)
                    }
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
                }
            }
            .frame(minWidth: 600)

            // Right sidebar: Settings and controls
            SettingsSidebar(appState: appState)
                .frame(minWidth: 280, maxWidth: 400)
        }
        .frame(minWidth: 1080, minHeight: 700)
        .focusedValue(\.importAction, showImportPanel)
        .focusedValue(\.exportAction, appState.performExport)
        .focusedValue(\.canExport, !appState.unmutedFrames.isEmpty && !appState.isExporting)
        .focusedValue(\.undoAction, performUndo)
        .focusedValue(\.redoAction, performRedo)
        .focusedValue(\.canUndo, appState.undoManager.canUndo)
        .focusedValue(\.canRedo, appState.undoManager.canRedo)
        .focusedValue(\.undoActionName, appState.undoManager.currentUndoActionName)
        .focusedValue(\.redoActionName, appState.undoManager.currentRedoActionName)
        .focusedValue(\.isImporting, appState.isImporting)
        .focusedValue(\.isExporting, appState.isExporting)
    }

    private func showImportPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = ImageItem.supportedContentTypes
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "Select images to import"

        if panel.runModal() == .OK {
            Task {
                await appState.importImages(urls: panel.urls)
            }
        }
    }

    private func performUndo() {
        try? appState.undoManager.undo(on: appState)
    }

    private func performRedo() {
        try? appState.undoManager.redo(on: appState)
    }
}

#Preview {
    ContentView()
}
