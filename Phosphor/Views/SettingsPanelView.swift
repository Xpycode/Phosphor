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
    private let footerHeight: CGFloat = 60
    @AppStorage("useOrangeAccent") private var useOrangeAccent = false

    private var accentColor: Color {
        useOrangeAccent ? .orange : Color(nsColor: NSColor.controlAccentColor)
    }

    init(viewModel: AppViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        let initialLoop = viewModel.settings.loopCount == 0 ? 1 : viewModel.settings.loopCount
        let finiteLoop = max(1, initialLoop)
        self._lastFiniteLoopCount = State(initialValue: finiteLoop)
        self._loopCountText = State(initialValue: String(finiteLoop))
    }

    var body: some View {
        let presetOptions = ResizePresetOption.presets(for: viewModel.settings.format)

        return VStack(spacing: 0) {
            // Header
            Text("Export")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                .frame(height: 24)

            Divider()

            // Settings Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Timing Settings
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
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
                                .tint(accentColor)
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
                                .tint(accentColor)
                            }
                        }
                        .padding(10)
                    } label: {
                        EmptyView()
                    }

                    // Loop Settings
                    GroupBox {
                        HStack(spacing: 12) {
                            Text("Loop Count")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("Infinite")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)

                            Toggle("", isOn: Binding(
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
                            ))
                            .labelsHidden()
                            .toggleStyle(AccentSwitchToggleStyle(accent: accentColor))
                            .accessibilityLabel("Infinite loop")

                            Spacer()

                            TextField("", text: loopCountTextBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .disabled(viewModel.settings.loopCount == 0)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                    } label: {
                        EmptyView()
                    }

                    // Quality Settings
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
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
                                .tint(accentColor)
                            }

                            // Dithering Toggle
                            Toggle("Enable Dithering", isOn: $viewModel.settings.enableDithering)
                                .font(.caption)
                                .help("Dithering helps reduce color banding in GIFs")
                                .tint(accentColor)
                        }
                        .padding(10)
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
                            .tint(accentColor)
                        }
                        .padding(10)
                    } label: {
                        EmptyView()
                    }

                    // Resize Settings
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Resize Output", isOn: $viewModel.settings.resizeEnabled)
                                .font(.caption)
                                .tint(accentColor)

                            if viewModel.settings.resizeEnabled {
                                Picker("", selection: $viewModel.settings.resizeMode) {
                                    Text("Common").tag(ResizeMode.common)
                                    Text("Custom").tag(ResizeMode.custom)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                                .tint(accentColor)

                                if viewModel.settings.resizeMode == .common {
                                    if presetOptions.isEmpty {
                                        Text("No presets for \(viewModel.settings.format.rawValue)")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    } else {
                                        Picker("Preset", selection: $viewModel.settings.selectedResizePresetID) {
                                            ForEach(presetOptions) { preset in
                                                Text(preset.displayLabel)
                                                    .tag(preset.id)
                                            }
                                        }
                                        .labelsHidden()
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: .infinity)
                                        .tint(accentColor)
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 12) {
                                            dimensionField(
                                                title: "Width",
                                                value: dimensionBinding(for: .width)
                                            )

                                            dimensionField(
                                                title: "Height",
                                                value: dimensionBinding(for: .height)
                                            )
                                        }

                                        Toggle("Maintain aspect ratio", isOn: $viewModel.settings.maintainAspectRatio)
                                            .font(.caption)
                                            .tint(accentColor)
                                    }
                                }
                            }
                        }
                        .padding(10)
                    } label: {
                        EmptyView()
                    }
                }
                .padding()
            }

            Divider()

            // Export Button
            VStack(spacing: 8) {
                if viewModel.isExporting {
                    ProgressView(value: viewModel.exportProgress) {
                        Text("Exporting...")
                            .font(.caption)
                    }
                    .progressViewStyle(.linear)
                    .tint(accentColor)
                } else {
                    let exportCompleted = viewModel.exportCompletionDate != nil
                    Button(action: exportAnimation) {
                        Label(
                            exportCompleted ? "Exported" : "Export Animation",
                            systemImage: exportCompleted ? "checkmark.circle.fill" : "square.and.arrow.down"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(exportCompleted ? .green : .accentColor)
                    .disabled(viewModel.imageItems.isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: footerHeight)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onChange(of: viewModel.settings.loopCount) { _, newValue in
            if newValue != 0 {
                let clamped = max(1, min(newValue, 100))
                lastFiniteLoopCount = clamped
                loopCountText = String(clamped)
            }
        }
        .onChange(of: viewModel.settings.format) { _, _ in
            syncPresetSelectionWithFormat()
        }
        .onChange(of: viewModel.settings.selectedResizePresetID) { _, _ in
            applySelectedPresetIfNeeded()
        }
        .onChange(of: viewModel.settings.resizeMode) { _, newValue in
            if newValue == .common {
                syncPresetSelectionWithFormat()
            }
        }
        .onChange(of: viewModel.settings.resizeEnabled) { _, newValue in
            if newValue && viewModel.settings.resizeMode == .common {
                syncPresetSelectionWithFormat()
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

    private func dimensionField(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            TextField(
                "",
                value: value,
                format: .number.precision(.fractionLength(0))
            )
            .textFieldStyle(.roundedBorder)
            .frame(width: 80)
        }
    }

    private enum OutputDimension {
        case width
        case height
    }

    private func dimensionBinding(for dimension: OutputDimension) -> Binding<Double> {
        Binding(
            get: {
                switch dimension {
                case .width:
                    return viewModel.settings.resizeWidth
                case .height:
                    return viewModel.settings.resizeHeight
                }
            },
            set: { newValue in
                let range: ClosedRange<Double> = 64...4096
                let clamped = min(max(newValue, range.lowerBound), range.upperBound)
                let currentWidth = viewModel.settings.resizeWidth
                let currentHeight = viewModel.settings.resizeHeight
                let aspectRatio = currentHeight > 0 ? currentWidth / currentHeight : nil

                switch dimension {
                case .width:
                    viewModel.settings.resizeWidth = clamped
                    adjustHeightIfNeeded(using: aspectRatio, newWidth: clamped, range: range)
                case .height:
                    viewModel.settings.resizeHeight = clamped
                    adjustWidthIfNeeded(using: aspectRatio, newHeight: clamped, range: range)
                }
            }
        )
    }

    private func adjustHeightIfNeeded(using ratio: Double?, newWidth: Double, range: ClosedRange<Double>) {
        guard shouldMaintainAspect(), let ratio = ratio, ratio.isFinite, ratio > 0 else { return }
        let newHeight = max(range.lowerBound, min(newWidth / ratio, range.upperBound))
        viewModel.settings.resizeHeight = newHeight.rounded()
    }

    private func adjustWidthIfNeeded(using ratio: Double?, newHeight: Double, range: ClosedRange<Double>) {
        guard shouldMaintainAspect(), let ratio = ratio, ratio.isFinite, ratio > 0 else { return }
        let newWidth = max(range.lowerBound, min(newHeight * ratio, range.upperBound))
        viewModel.settings.resizeWidth = newWidth.rounded()
    }

    private func shouldMaintainAspect() -> Bool {
        viewModel.settings.resizeEnabled &&
        viewModel.settings.resizeMode == .custom &&
        viewModel.settings.maintainAspectRatio
    }

    private func applyPreset(_ preset: ResizePresetOption) {
        viewModel.settings.resizeWidth = preset.width
        viewModel.settings.resizeHeight = preset.height
    }

    private func syncPresetSelectionWithFormat() {
        guard viewModel.settings.resizeMode == .common else { return }
        let presets = ResizePresetOption.presets(for: viewModel.settings.format)
        guard !presets.isEmpty else { return }

        if let match = presets.first(where: { $0.id == viewModel.settings.selectedResizePresetID }) {
            applyPreset(match)
        } else if let first = presets.first {
            viewModel.settings.selectedResizePresetID = first.id
            applyPreset(first)
        }
    }

    private func applySelectedPresetIfNeeded() {
        guard viewModel.settings.resizeMode == .common else { return }
        guard let preset = ResizePresetOption.preset(
            for: viewModel.settings.format,
            id: viewModel.settings.selectedResizePresetID
        ) else { return }
        applyPreset(preset)
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

private struct AccentSwitchToggleStyle: ToggleStyle {
    var accent: Color

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(configuration.isOn ? accent : Color.secondary.opacity(0.35))
                    .frame(width: 44, height: 22)

                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .padding(.horizontal, 2)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, y: 1)
            }
            .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(configuration.isOn ? "On" : "Off")
    }
}

#Preview {
    SettingsPanelView(viewModel: AppViewModel())
        .frame(width: 320, height: 600)
}
