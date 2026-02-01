//
//  ExportSettingsView.swift
//  Phosphor
//
//  Format and quality configuration for export
//

import SwiftUI

struct ExportSettingsView: View {
    @ObservedObject var appState: AppState
    let onExport: () -> Void

    @ObservedObject private var exportSettings: ExportSettings

    init(appState: AppState, onExport: @escaping () -> Void) {
        self.appState = appState
        self.onExport = onExport
        self.exportSettings = appState.exportSettings
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Format Selection
                    formatSection

                    // Quality (GIF only)
                    if exportSettings.format == .gif {
                        qualitySection
                        colorDepthSection
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }

            Divider()

            VStack(spacing: 8) {
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

                Button(action: onExport) {
                    Text("Export \(exportSettings.format.rawValue)")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(appState.unmutedFrames.isEmpty)
            }
            .padding()
        }
    }

    // MARK: - Format Section

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Format")
                .font(.headline)

            Picker("Format", selection: $exportSettings.format) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    // MARK: - Quality Section (GIF only)

    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quality")
                .font(.headline)

            VStack(spacing: 12) {
                // Quality slider
                HStack {
                    Text("Quality")
                    Spacer()
                    Text("\(Int(exportSettings.quality * 100))%")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $exportSettings.quality, in: 0.1...1.0, step: 0.05)

                // Dithering toggle
                Toggle("Enable Dithering", isOn: $exportSettings.enableDithering)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: - Color Depth Section (GIF only)

    private var colorDepthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Depth")
                .font(.headline)

            VStack(spacing: 12) {
                Toggle("Reduce Colors", isOn: $exportSettings.colorDepthEnabled)

                if exportSettings.colorDepthEnabled {
                    HStack {
                        Text("Levels")
                        Spacer()
                        Text("\(Int(exportSettings.colorDepthLevels))")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $exportSettings.colorDepthLevels, in: 2...30, step: 1)

                    Text("≈ \(exportSettings.approximateColorCount) colors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    ExportSettingsView(appState: AppState(), onExport: {})
        .frame(width: 320, height: 500)
}
