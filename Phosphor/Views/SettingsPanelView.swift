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
    @State private var lastFiniteLoopCount: Int
    @State private var loopCountText: String

    init(viewModel: AppViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        let initialLoop = viewModel.settings.loopCount == 0 ? 1 : viewModel.settings.loopCount
        let finiteLoop = max(1, initialLoop)
        self._lastFiniteLoopCount = State(initialValue: finiteLoop)
        self._loopCountText = State(initialValue: String(finiteLoop))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Settings")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                .frame(height: 24)

            Divider()

            // Settings Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Timing Settings
                    GroupBox {
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
                    } label: {
                        EmptyView()
                    }

                    // Loop Settings
                    GroupBox {
                        HStack(spacing: 16) {
                            Text("Loop Count")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Toggle(isOn: Binding(
                                get: { viewModel.settings.loopCount == 0 },
                                set: { isInfinite in
                                    if isInfinite {
                                        if viewModel.settings.loopCount != 0 {
                                            lastFiniteLoopCount = max(1, viewModel.settings.loopCount)
                                            loopCountText = String(lastFiniteLoopCount)
                                        }
                                        viewModel.settings.loopCount = 0
                                    } else {
                                        viewModel.settings.loopCount = lastFiniteLoopCount
                                        loopCountText = String(lastFiniteLoopCount)
                                    }
                                }
                            )) {
                                Text("Infinite")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .toggleStyle(.switch)
                            .controlSize(.small)

                            Spacer()

                            TextField("", text: loopCountTextBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .disabled(viewModel.settings.loopCount == 0)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                    } label: {
                        EmptyView()
                    }

                    // Quality Settings
                    GroupBox {
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
                    } label: {
                        EmptyView()
                    }

                    // Export Format
                    GroupBox {
                        HStack(spacing: 12) {
                            Text("Export Format")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("", selection: $viewModel.settings.format) {
                                ForEach(ExportFormat.allCases, id: \.self) { format in
                                    Text(format.rawValue).tag(format)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(12)
                    } label: {
                        EmptyView()
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
        .onChange(of: viewModel.settings.loopCount) { newValue in
            if newValue != 0 {
                let clamped = max(1, min(newValue, 100))
                lastFiniteLoopCount = clamped
                loopCountText = String(clamped)
            }
        }
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

    private var loopCountTextBinding: Binding<String> {
        Binding(
            get: {
                loopCountText
            },
            set: { newValue in
                let filtered = newValue.filter(\.isNumber)
                loopCountText = filtered

                guard let value = Int(filtered) else { return }

                let clamped = max(1, min(value, 100))
                lastFiniteLoopCount = clamped

                if viewModel.settings.loopCount != 0 {
                    viewModel.settings.loopCount = clamped
                }
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
