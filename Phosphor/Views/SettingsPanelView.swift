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
                        VStack(alignment: .leading, spacing: 16) {
                            // Frame Rate
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Frame Rate")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(Int(viewModel.settings.frameRate)) FPS")
                                        .font(.caption.monospacedDigit())
                                }

                                Slider(
                                    value: steppedBinding(
                                        $viewModel.settings.frameRate,
                                        step: 1.0,
                                        range: 1.0...60.0
                                    ),
                                    in: 1.0...60.0
                                )
                                .controlSize(.regular)
                            }

                            // Frame Delay
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Frame Delay")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(String(format: "%.0f", viewModel.settings.frameDelay)) ms / \(String(format: "%.1f", viewModel.settings.frameDelay / 10.0)) cs")
                                        .font(.caption.monospacedDigit())
                                }

                                Slider(
                                    value: steppedBinding(
                                        $viewModel.settings.frameDelay,
                                        step: 1,
                                        range: (1000.0 / 60.0)...1000.0
                                    ),
                                    in: (1000.0 / 60.0)...1000.0
                                )
                                .controlSize(.regular)
                            }
                        }
                        .padding(12)
                    }

                    // Loop Settings
                    GroupBox("Loop") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Loop Count")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Toggle("Infinite", isOn: Binding(
                                    get: { viewModel.settings.loopCount == 0 },
                                    set: { viewModel.settings.loopCount = $0 ? 0 : 1 }
                                ))
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            }

                            if viewModel.settings.loopCount != 0 {
                                HStack {
                                    Text("Repeats:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    TextField("", value: $viewModel.settings.loopCount, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)

                                    Stepper("", value: $viewModel.settings.loopCount, in: 1...100)
                                        .labelsHidden()
                                }
                            }
                        }
                        .padding(8)
                    }

                    // Quality Settings
                    GroupBox("Quality") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Quality Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Quality")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(Int(viewModel.settings.quality * 100))%")
                                        .font(.caption.monospacedDigit())
                                }

                                Slider(
                                    value: steppedBinding(
                                        $viewModel.settings.quality,
                                        step: 0.05,
                                        range: 0.1...1.0
                                    ),
                                    in: 0.1...1.0
                                )
                                .controlSize(.regular)
                            }

                            // Dithering Toggle
                            Toggle("Enable Dithering", isOn: $viewModel.settings.enableDithering)
                                .font(.caption)
                                .help("Dithering helps reduce color banding in GIFs")
                        }
                        .padding(12)
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

    private func steppedBinding(
        _ binding: Binding<Double>,
        step: Double,
        range: ClosedRange<Double>
    ) -> Binding<Double> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                let snappedValue = (newValue / step).rounded() * step
                binding.wrappedValue = min(max(snappedValue, range.lowerBound), range.upperBound)
            }
        )
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
