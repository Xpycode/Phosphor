//
//  ContentView.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        HSplitView {
            // Left Pane: File List
            FileListView(viewModel: viewModel)
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)

            // Center Pane: Preview Player
            PreviewPlayerView(viewModel: viewModel)
                .frame(minWidth: 400, idealWidth: 600)

            // Right Pane: Settings and Export
            SettingsPanelView(viewModel: viewModel)
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
        }
        .frame(minWidth: 1000, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
