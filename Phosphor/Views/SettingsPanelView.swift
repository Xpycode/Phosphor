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
    @State private var selectedExportTab: ExportTab = .basic
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
            Text("Export")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                .frame(height: 24)

            Divider()

            formatPickerSection

            Divider()

            tabPicker

            Divider()

            Group {
                if selectedExportTab == .basic {
                    basicSettingsContent(presetOptions: presetOptions)
                } else {
                    advancedSettingsContent
                }
            }

            Divider()

            exportButton
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onChange(of: viewModel.settings.loopCount) { _, newValue in
            if newValue != 0 {
                let clamped = max(1, min(newValue, 100))
                lastFiniteLoopCount = clamped
                loopCountText = String(clamped)
            }
        }
        .onChange(of: viewModel.settings.format) { _, newValue in
            syncPresetSelectionWithFormat()
            if newValue != .gif {
                viewModel.settings.colorDepthEnabled = false
            }
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
        .onChange(of: viewModel.settings.selectedPlatformTargetID) { _, newValue in
            applyPlatformPresetIfNeeded(for: newValue)
        }
    }

    private var tabPicker: some View {
        Picker("", selection: $selectedExportTab) {
            ForEach(ExportTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .tint(accentColor)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var formatPickerSection: some View {
        Picker("", selection: $viewModel.settings.format) {
            ForEach(ExportFormat.allCases, id: \.self) { format in
                Text(format.rawValue).tag(format)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(maxWidth: .infinity)
        .tint(accentColor)
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private func basicSettingsContent(presetOptions: [ResizePresetOption]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
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

                            if viewModel.hasCustomFrameDelays {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Custom frame timings are active. Changes here affect only untimed frames unless you override them.")
                                        .font(.caption2)
                                        .foregroundColor(viewModel.settings.overrideCustomFrameTimings ? .secondary : .orange)

                                    Toggle("Apply slider to custom frames", isOn: $viewModel.settings.overrideCustomFrameTimings)
                                        .font(.caption2)
                                        .tint(accentColor)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(10)
                } label: {
                    EmptyView()
                }

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
                                }
                            }
                        ))
                        .toggleStyle(AccentSwitchToggleStyle(accent: accentColor))

                        TextField(
                            "",
                            text: loopCountTextBinding
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 48)
                        .disabled(viewModel.settings.loopCount == 0)
                    }
                    .padding(10)
                } label: {
                    EmptyView()
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
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

                        Toggle("Enable Dithering", isOn: $viewModel.settings.enableDithering)
                            .font(.caption)
                            .help("Dithering helps reduce color banding in GIFs")
                            .tint(accentColor)
                    }
                    .padding(10)
                } label: {
                    EmptyView()
                }

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
    }

    private var advancedSettingsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Delivery Target")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(currentPlatformPreset?.label ?? "None")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }

                        Picker("", selection: $viewModel.settings.selectedPlatformTargetID) {
                            Text("None").tag(Optional<String>.none)
                            ForEach(ExportPlatformPreset.presets) { preset in
                                Text(preset.label)
                                    .tag(Optional(preset.id))
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)

                        if let preset = currentPlatformPreset {
                            Text("\(preset.notes)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Presets configure dimensions, frame rate, and size limits for common platforms.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(10)
                } label: {
                    EmptyView()
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Drop frames to reduce file size", isOn: $viewModel.settings.frameSkippingEnabled)
                            .font(.caption)
                            .tint(accentColor)

                        if viewModel.settings.frameSkippingEnabled {
                            Stepper(
                                value: frameSkipIntervalBinding,
                                in: 2...12
                            ) {
                                Text("Keep every \(viewModel.settings.frameSkipInterval)th frame")
                                    .font(.caption)
                            }
                        } else {
                            Text("Keep all frames for maximum smoothness.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Text("Effective frames: \(viewModel.exportFrameCount) of \(viewModel.sortedImages.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("This affects export only; playback keeps every frame so you can edit with full fidelity.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                } label: {
                    EmptyView()
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Estimated File Size")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(viewModel.estimatedExportSizeString ?? "Add frames to calculate")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(viewModel.estimatedExceedsSizeLimit ? .orange : .primary)
                        }

                        Toggle("Limit exported file size", isOn: $viewModel.settings.sizeLimitEnabled)
                            .font(.caption)
                            .tint(accentColor)

                        if viewModel.settings.sizeLimitEnabled {
                            Slider(
                                value: $viewModel.settings.maxFileSizeMB,
                                in: 0.25...16,
                                step: 0.25
                            )
                            .tint(accentColor)

                            HStack {
                                Text("Maximum")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formattedSizeLimit ?? "")
                                    .font(.caption.monospacedDigit())
                            }

                            if viewModel.estimatedExceedsSizeLimit {
                                Text("Estimated size exceeds this limit. Lower the frame rate, enable frame dropping, or reduce dimensions.")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        } else {
                            Text("Enable size limiting to guard against platform upload caps.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(10)
                } label: {
                    EmptyView()
                }

                if viewModel.settings.format == .gif {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Limit color palette (GIF)", isOn: $viewModel.settings.colorDepthEnabled)
                                .font(.caption)
                                .tint(accentColor)

                            if viewModel.settings.colorDepthEnabled {
                                Slider(
                                    value: $viewModel.settings.colorDepthLevels,
                                    in: 2...30,
                                    step: 1
                                )
                                .tint(accentColor)

                                let levels = viewModel.settings.clampedColorDepthLevels
                                Text("Levels per channel: \(levels)  •  ~\(formattedColorCount(for: viewModel.settings.approximateColorCount)) colors")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Full 8-bit color per channel. Enable to shrink GIF size at the cost of banding.")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(10)
                    } label: {
                        EmptyView()
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Per-frame timing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if viewModel.hasCustomFrameDelays {
                                Button("Reset All") {
                                    viewModel.resetAllCustomFrameDelays()
                                }
                                .buttonStyle(.borderless)
                                .font(.caption2)
                            }
                        }

                        Text("Fine-tune playback speed per frame to emphasize moments or trim duration without dropping frames.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Divider()

                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(viewModel.sortedImages.enumerated()), id: \.element.id) { index, item in
                                    frameTimingRow(for: item, index: index)
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    }
                    .padding(10)
                } label: {
                    EmptyView()
                }
            }
            .padding()
        }
    }

    private var exportButton: some View {
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

    private func formattedColorCount(for count: Int) -> String {
        guard count > 0 else { return "0" }
        return SettingsPanelView.numberFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    @ViewBuilder
    private func frameTimingRow(for item: ImageItem, index: Int) -> some View {
        let currentDelay = viewModel.customFrameDelays[item.id] ?? viewModel.settings.frameDelay
        let isCustom = viewModel.customFrameDelays[item.id] != nil

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Frame \(index + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(item.fileName)
                    .font(.caption)
                    .lineLimit(1)

                Spacer()

                Text("\(Int(currentDelay)) ms")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(isCustom ? .primary : .secondary)

                if isCustom {
                    Text("Custom")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("Default")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Slider(
                value: frameDelayBinding(for: item),
                in: 10...1000,
                step: 5
            )
            .tint(accentColor)

            HStack {
                Button("Reset") {
                    viewModel.resetCustomFrameDelay(for: item)
                }
                .buttonStyle(.borderless)
                .font(.caption2)
                .disabled(!isCustom)

                Spacer()

                Text("10 ms")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("1000 ms")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func frameDelayBinding(for item: ImageItem) -> Binding<Double> {
        Binding(
            get: {
                viewModel.customFrameDelays[item.id] ?? viewModel.settings.frameDelay
            },
            set: { newValue in
                viewModel.setCustomFrameDelay(for: item, delay: newValue)
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

    private var frameSkipIntervalBinding: Binding<Int> {
        Binding(
            get: {
                max(2, viewModel.settings.frameSkipInterval)
            },
            set: { newValue in
                viewModel.settings.frameSkipInterval = max(2, min(newValue, 12))
            }
        )
    }

    private var formattedSizeLimit: String? {
        guard viewModel.settings.sizeLimitEnabled else { return nil }
        let bytes = viewModel.settings.maxFileSizeBytes
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private var currentPlatformPreset: ExportPlatformPreset? {
        guard let id = viewModel.settings.selectedPlatformTargetID else { return nil }
        return ExportPlatformPreset.preset(id: id)
    }

    private func applyPlatformPresetIfNeeded(for id: String?) {
        guard let id, let preset = ExportPlatformPreset.preset(id: id) else { return }
        viewModel.settings.resizeEnabled = true
        viewModel.settings.resizeMode = .custom
        viewModel.settings.resizeWidth = Double(preset.maxDimensions.width)
        viewModel.settings.resizeHeight = Double(preset.maxDimensions.height)
        viewModel.settings.maintainAspectRatio = true
        viewModel.settings.sizeLimitEnabled = true
        viewModel.settings.maxFileSizeMB = preset.maxFileSizeMB
        viewModel.settings.frameRate = preset.recommendedFrameRate
        viewModel.settings.updateDelayFromFrameRate()
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

private extension SettingsPanelView {
    enum ExportTab: String, CaseIterable, Identifiable {
        case basic
        case advanced

        var id: String { rawValue }

        var title: String {
            switch self {
            case .basic: return "Basic"
            case .advanced: return "Advanced"
            }
        }
    }

    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
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
        .frame(width: 340, height: 640)
}
