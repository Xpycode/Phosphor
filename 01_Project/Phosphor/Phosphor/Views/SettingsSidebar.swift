//
//  SettingsSidebar.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

struct SettingsSidebar: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var exportSettings: ExportSettings
    @State private var showExportSheet = false

    init(appState: AppState) {
        self.appState = appState
        self.exportSettings = appState.exportSettings
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    // Canvas Options (global)
                    ResizeSection(settings: appState.exportSettings)

                    Divider()
                        .padding(.vertical, 4)

                    // Timing (global FPS, Loop Count)
                    TimingSection(settings: appState.exportSettings)

                    // Frame Timing (per-frame, only when selected)
                    FrameTimingSection(appState: appState)

                    // Transform (per-frame, only when selected)
                    TransformSection(appState: appState)

                    Spacer(minLength: 20)
                }
                .padding()
            }

            // Export Button Section
            Divider()

            VStack(spacing: 8) {
                // Frame count info
                if appState.hasFrames {
                    let unmutedCount = appState.unmutedFrames.count
                    let totalCount = appState.frames.count
                    if unmutedCount < totalCount {
                        Text("\(unmutedCount) of \(totalCount) frames")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(totalCount) frames")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Export button opens sheet
                Button(action: {
                    showExportSheet = true
                }) {
                    Text("Export...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(appState.unmutedFrames.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 280, idealWidth: 300, maxWidth: 350)
        .background(Color(nsColor: .controlBackgroundColor))
        // Export sheet
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(appState: appState, isPresented: $showExportSheet)
        }
        // Apply transform to all confirmation
        .alert("Apply Transform to All Frames?", isPresented: $appState.showApplyTransformToAllConfirmation) {
            Button("Apply to All", role: .destructive) {
                appState.applyTransformToAllFrames()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will apply the current frame's transform settings to all \(appState.frames.count) frames.")
        }
    }
}

#Preview {
    SettingsSidebar(appState: {
        let state = AppState()
        return state
    }())
    .frame(height: 700)
}
