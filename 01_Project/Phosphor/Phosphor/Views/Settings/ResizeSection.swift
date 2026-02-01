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
        GroupBox {
            VStack(spacing: 8) {
                // Canvas Mode Picker (Original / Preset / Custom)
                Picker("", selection: $settings.canvasMode) {
                    ForEach(CanvasMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)

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
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        } label: {
            Text("Canvas")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Preset Section

    private var presetSection: some View {
        VStack(spacing: 8) {
            let presets = ResizePresetOption.presets(for: settings.format)

            Picker("", selection: $settings.selectedPresetID) {
                Text("Select...").tag(nil as String?)
                ForEach(presets) { preset in
                    Text(preset.displayLabel).tag(preset.id as String?)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
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
        HStack(spacing: 6) {
            Text("W:")
                .foregroundColor(.secondary)

            TextField("", value: widthBinding, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)

            Button(action: toggleAspectLock) {
                Image(systemName: "link")
                    .opacity(settings.aspectRatioLocked ? 1.0 : 0.4)
                    .foregroundColor(settings.aspectRatioLocked ? .accentColor : .secondary)
            }
            .buttonStyle(.borderless)
            .help(settings.aspectRatioLocked ? "Unlock aspect ratio" : "Lock aspect ratio")

            Text("H:")
                .foregroundColor(.secondary)

            TextField("", value: heightBinding, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
        }
        .onAppear {
            initializeCustomDimensionsIfNeeded()
        }
        .onChange(of: settings.canvasMode) { _, newMode in
            if newMode == .custom {
                initializeCustomDimensionsIfNeeded()
            }
        }
    }

    // MARK: - Aspect Ratio Lock Bindings

    private var widthBinding: Binding<Double> {
        Binding(
            get: { settings.canvasWidth },
            set: { newValue in
                settings.canvasWidth = newValue
                if settings.aspectRatioLocked {
                    settings.updateHeightFromWidth()
                }
            }
        )
    }

    private var heightBinding: Binding<Double> {
        Binding(
            get: { settings.canvasHeight },
            set: { newValue in
                settings.canvasHeight = newValue
                if settings.aspectRatioLocked {
                    settings.updateWidthFromHeight()
                }
            }
        )
    }

    private func toggleAspectLock() {
        settings.aspectRatioLocked.toggle()
        if settings.aspectRatioLocked {
            settings.captureAspectRatio()
        }
    }

    private func initializeCustomDimensionsIfNeeded() {
        // If switching to Custom and dimensions are default, use source image size
        if let sourceSize = settings.automaticCanvasSize,
           settings.canvasWidth == 640 && settings.canvasHeight == 480 {
            settings.canvasWidth = sourceSize.width
            settings.canvasHeight = sourceSize.height
        }
        // Capture initial aspect ratio if not already set
        if settings.lockedAspectRatio == nil {
            settings.captureAspectRatio()
        }
    }

    // MARK: - Scale Mode Section

    private var scaleModeSection: some View {
        VStack(spacing: 4) {
            Text("Scale")
                .font(.subheadline)

            Picker("", selection: $settings.scaleMode) {
                ForEach(ScaleMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Background Color Section (for Fit mode)

    private var backgroundColorSection: some View {
        VStack(spacing: 8) {
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
        .frame(maxWidth: .infinity)
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
