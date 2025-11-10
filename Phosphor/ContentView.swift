//
//  ContentView.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @AppStorage("prefersLightMode") private var prefersLightMode = false
    @AppStorage("useOrangeAccent") private var useOrangeAccent = false

    private var activeAccentColor: Color {
        if useOrangeAccent {
            return Color.orange
        } else {
            return Color(nsColor: NSColor.controlAccentColor)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HSplitView {
                // Left Pane: File List
                FileListView(viewModel: viewModel)
                    .frame(minWidth: 380, idealWidth: 410, maxWidth: 440)

                // Center Pane: Preview Player
                PreviewPlayerView(viewModel: viewModel)
                    .frame(minWidth: 400, idealWidth: 600)

                // Right Pane: Settings and Export
                SettingsPanelView(viewModel: viewModel)
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            }
        }
        .frame(minWidth: 1000, minHeight: 630)
        .preferredColorScheme(prefersLightMode ? .light : .dark)
        .accentColor(activeAccentColor)
    }
}

#Preview {
    ContentView()
}
