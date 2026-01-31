//
//  ResizeSection.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

struct ResizeSection: View {
    @ObservedObject var settings: ExportSettings

    var body: some View {
        GroupBox("Canvas") {
            VStack(alignment: .leading, spacing: 8) {
                // Canvas Mode Picker (Original / Preset / Custom)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Size")
                        .font(.subheadline)

                    Picker("", selection: $settings.canvasMode) {
                        ForEach(CanvasMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                // Mode-specific content
                switch settings.canvasMode {
                case .original:
                    if let size = settings.automaticCanvasSize {
                        Text("Source: \(Int(size.width)) × \(Int(size.height)) px")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Uses source image dimensions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                case .preset:
                    presetSection
                    scaleModeSection

                case .custom:
                    customDimensionsSection
                    scaleModeSection
                }

                // Background color picker for Fit mode (GIF only)
                if settings.canvasMode != .original &&
                   settings.scaleMode == .fit &&
                   settings.format == .gif {
                    backgroundColorSection
                }

                // Output size preview (for preset/custom)
                if settings.canvasMode != .original,
                   let size = settings.resolvedCanvasSize {
                    HStack {
                        Text("Output:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(size.width)) × \(Int(size.height)) px")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Preset Section

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let presets = ResizePresetOption.presets(for: settings.format)

            Picker("", selection: $settings.selectedPresetID) {
                Text("Select...").tag(nil as String?)
                ForEach(presets) { preset in
                    Text(preset.displayLabel).tag(preset.id as String?)
                }
            }
            .labelsHidden()
        }
        .onAppear {
            // Auto-select first preset if none selected
            if settings.selectedPresetID == nil {
                settings.selectedPresetID = ResizePresetOption.defaultID(for: settings.format)
            }
        }
    }

    // MARK: - Custom Dimensions Section

    private var customDimensionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Width:")
                    .frame(width: 50, alignment: .leading)

                TextField("", value: $settings.canvasWidth, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)

                Text("px")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Height:")
                    .frame(width: 50, alignment: .leading)

                TextField("", value: $settings.canvasHeight, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)

                Text("px")
                    .foregroundColor(.secondary)
            }

            Text("Range: \(Int(ExportConstants.dimensionRange.lowerBound))–\(Int(ExportConstants.dimensionRange.upperBound)) px")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Scale Mode Section

    private var scaleModeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Scale")
                .font(.subheadline)

            Picker("", selection: $settings.scaleMode) {
                ForEach(ScaleMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Help text for scale modes
            Group {
                switch settings.scaleMode {
                case .fit:
                    Text("Letterbox: entire image visible, adds padding")
                case .fill:
                    Text("Crop: fills canvas completely, may trim edges")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Background Color Section (for Fit mode)

    private var backgroundColorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Letterbox Background")
                .font(.subheadline)

            HStack(spacing: 12) {
                Toggle("Auto-detect", isOn: $settings.useAutoBackgroundColor)
                    .toggleStyle(.checkbox)

                if !settings.useAutoBackgroundColor {
                    ColorPicker("", selection: Binding(
                        get: { Color(nsColor: settings.fitBackgroundColor) },
                        set: { settings.fitBackgroundColor = NSColor($0) }
                    ))
                    .labelsHidden()
                    .frame(width: 40)
                }
            }

            if settings.useAutoBackgroundColor {
                Text("Samples corner pixel from first frame")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ResizeSection(settings: {
            let s = ExportSettings()
            s.canvasMode = .original
            return s
        }())

        ResizeSection(settings: {
            let s = ExportSettings()
            s.canvasMode = .preset
            s.selectedPresetID = "gif-720"
            return s
        }())

        ResizeSection(settings: {
            let s = ExportSettings()
            s.canvasMode = .custom
            s.scaleMode = .fit
            return s
        }())
    }
    .padding()
    .frame(width: 300)
}
