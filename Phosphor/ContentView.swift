//
//  ContentView.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI
import AppKit

// MARK: - Shared Accent Color Environment

private struct AppAccentColorKey: EnvironmentKey {
    static let defaultValue: Color = Color(nsColor: NSColor.controlAccentColor)
}

extension EnvironmentValues {
    var appAccentColor: Color {
        get { self[AppAccentColorKey.self] }
        set { self[AppAccentColorKey.self] = newValue }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @AppStorage("prefersLightMode") private var prefersLightMode = false
    @AppStorage("useOrangeAccent") private var useOrangeAccent = false

    private var activeAccentColor: Color {
        useOrangeAccent ? .orange : Color(nsColor: NSColor.controlAccentColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HSplitView {
                // Left Pane: File List
                FileListView(viewModel: viewModel)
                    .frame(minWidth: 340, idealWidth: 400, maxWidth: 440)

                // Center Pane: Preview Player
                PreviewPlayerView(viewModel: viewModel)
                    .frame(minWidth: 360, idealWidth: 600)

                // Right Pane: Settings and Export
                SettingsPanelView(viewModel: viewModel)
                    .frame(minWidth: 340, idealWidth: 370, maxWidth: 400)
            }
        }
        .frame(minWidth: 1040, minHeight: 700)
        .preferredColorScheme(prefersLightMode ? .light : .dark)
        .accentColor(activeAccentColor)
        .environment(\.appAccentColor, activeAccentColor)
    }
}

#Preview {
    ContentView()
}
