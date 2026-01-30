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
                    PreviewPane(appState: appState)
                        .frame(minHeight: 300)

                    TimelineToolbar(
                        appState: appState,
                        availableWidth: geometry.size.width,
                        onImport: showImportPanel
                    )

                    TimelinePane(appState: appState)
                        .frame(minHeight: 120)
                }
            }
            .frame(minWidth: 600)

            // Right sidebar: Settings and controls
            SettingsSidebar(appState: appState)
                .frame(minWidth: 280, maxWidth: 400)
        }
        .frame(minWidth: 1080, minHeight: 700)
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
}

#Preview {
    ContentView()
}
