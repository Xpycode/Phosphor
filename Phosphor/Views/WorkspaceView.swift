//
//  WorkspaceView.swift
//  Phosphor
//
//  Created on 2025-11-12
//
//  New sequence-based workspace layout with MediaLibrary + Timeline

import SwiftUI

struct WorkspaceView: View {
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
                // Left Panel: Media Library
                MediaLibraryView(viewModel: viewModel)
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)

                VSplitView {
                    // Top: Preview Player
                    PreviewPlayerView(viewModel: viewModel)
                        .frame(minHeight: 400, idealHeight: 600)

                    // Bottom: Timeline + Sequence Controls
                    SequenceTimelineView(viewModel: viewModel)
                        .frame(minHeight: 200, idealHeight: 300, maxHeight: 400)
                }
                .frame(minWidth: 500, idealWidth: 700)

                // Right Panel: Settings and Export (existing panel)
                SettingsPanelView(viewModel: viewModel)
                    .frame(minWidth: 320, idealWidth: 360, maxWidth: 400)
            }
        }
        .frame(minWidth: 1100, minHeight: 800)
        .preferredColorScheme(prefersLightMode ? .light : .dark)
        .accentColor(activeAccentColor)
        .onAppear {
            // Start with empty workspace as user requested
            // User needs to create a sequence manually
        }
    }
}

#Preview {
    WorkspaceView()
}
