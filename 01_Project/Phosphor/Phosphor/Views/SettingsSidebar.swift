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

    init(appState: AppState) {
        self.appState = appState
        self.exportSettings = appState.exportSettings
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Format Selection
                    FormatSelectionSection(settings: appState.exportSettings)

                    // Timing (FPS, Loop Count)
                    TimingSection(settings: appState.exportSettings)

                    // Quality (GIF only)
                    QualitySection(settings: appState.exportSettings)

                    // Color Depth (GIF only)
                    ColorDepthSection(settings: appState.exportSettings)

                    // Resize Options
                    ResizeSection(settings: appState.exportSettings)

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

                if appState.isExporting {
                    // Progress indicator during export
                    VStack(spacing: 4) {
                        ProgressView(value: appState.exportProgress)
                            .progressViewStyle(.linear)

                        Text("Exporting... \(Int(appState.exportProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Export button
                    Button(action: {
                        appState.performExport()
                    }) {
                        Text("Export \(exportSettings.format.rawValue)")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(appState.unmutedFrames.isEmpty)
                }
            }
            .padding()
        }
        .frame(minWidth: 280, idealWidth: 300, maxWidth: 350)
        .background(Color(nsColor: .controlBackgroundColor))
        // Success alert
        .alert("Export Complete", isPresented: $appState.showExportSuccess) {
            Button("Show in Finder") {
                if let url = appState.lastExportURL {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            if let url = appState.lastExportURL {
                Text("Saved to \(url.lastPathComponent)")
            }
        }
        // Error alert
        .alert("Export Failed", isPresented: .init(
            get: { appState.exportError != nil },
            set: { if !$0 { appState.exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = appState.exportError {
                Text(error.localizedDescription)
            }
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
