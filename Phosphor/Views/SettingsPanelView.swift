//
//  SettingsPanelView.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsPanelView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            // Settings Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Timing Settings
                    GroupBox("Timing") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Frame Rate
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Frame Rate")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(String(format: "%.1f", viewModel.settings.frameRate)) FPS")
                                        .font(.caption.monospacedDigit())
                                }

                                Slider(
                                    value: $viewModel.settings.frameRate,
                                    in: 1...60,
                                    step: 0.1
                                )
                            }

                            // Frame Delay
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Frame Delay")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(String(format: "%.0f", viewModel.settings.frameDelay)) ms")
                                        .font(.caption.monospacedDigit())
                                }

                                Slider(
                                    value: $viewModel.settings.frameDelay,
                                    in: 16...5000,
                                    step: 1
                                )
                            }
                        }
                        .padding(8)
                    }

                    // Loop Settings
                    GroupBox("Loop") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Loop Count")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(viewModel.settings.loopCount == 0 ? "Infinite" : "\(viewModel.settings.loopCount)")
                                    .font(.caption.monospacedDigit())
                            }

                            HStack {
                                Button("Infinite") {
                                    viewModel.settings.loopCount = 0
                                }
                                .buttonStyle(.borderless)

                                Slider(
                                    value: Binding(
                                        get: { Double(viewModel.settings.loopCount) },
                                        set: { viewModel.settings.loopCount = Int($0) }
                                    ),
                                    in: 0...100,
                                    step: 1
                                )
                            }
                        }
                        .padding(8)
                    }

                    // Quality Settings
                    GroupBox("Quality") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Quality Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Quality")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(Int(viewModel.settings.quality * 100))%")
                                        .font(.caption.monospacedDigit())
                                }

                                Slider(
                                    value: $viewModel.settings.quality,
                                    in: 0.1...1.0,
                                    step: 0.05
                                )
                            }

                            // Dithering Toggle
                            Toggle("Enable Dithering", isOn: $viewModel.settings.enableDithering)
                                .font(.caption)
                                .help("Dithering helps reduce color banding in GIFs")
                        }
                        .padding(8)
                    }

                    // Sort Order
                    GroupBox("Sort Order") {
                        Picker("", selection: $viewModel.settings.sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .font(.caption)
                        .padding(8)
                    }

                    // Export Format
                    GroupBox("Export Format") {
                        Picker("", selection: $viewModel.settings.format) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .font(.caption)
                        .padding(8)
                    }
                }
                .padding()
            }

            Divider()

            // Export Button
            VStack(spacing: 12) {
                if viewModel.isExporting {
                    ProgressView(value: viewModel.exportProgress) {
                        Text("Exporting...")
                            .font(.caption)
                    }
                    .progressViewStyle(.linear)
                } else {
                    Button(action: exportAnimation) {
                        Label("Export Animation", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.imageItems.isEmpty)
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func exportAnimation() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: viewModel.settings.format.fileExtension)!]
        panel.nameFieldStringValue = "animation.\(viewModel.settings.format.fileExtension)"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                do {
                    try await viewModel.exportAnimation(to: url)

                    // Show success message
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.messageText = "Export Complete"
                        alert.informativeText = "Animation saved successfully to \(url.lastPathComponent)"
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                } catch {
                    // Show error message
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.messageText = "Export Failed"
                        alert.informativeText = error.localizedDescription
                        alert.alertStyle = .critical
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsPanelView(viewModel: AppViewModel())
        .frame(width: 320, height: 600)
}
