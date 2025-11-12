//
//  NewSequenceSheet.swift
//  Phosphor
//
//  Created on 2025-11-12
//

import SwiftUI

struct NewSequenceSheet: View {
    @ObservedObject var project: Project
    @Binding var isPresented: Bool

    @State private var name: String = "Untitled Sequence"
    @State private var selectedPreset: CanvasPreset = CanvasPreset.presets[0]
    @State private var isCustom: Bool = false
    @State private var customWidth: String = "1920"
    @State private var customHeight: String = "1080"
    @State private var frameRate: Double = 24
    @State private var defaultFitMode: FrameFitMode = .fill

    private var resolvedWidth: Int {
        if isCustom {
            return Int(customWidth) ?? 1920
        }
        return selectedPreset.width
    }

    private var resolvedHeight: Int {
        if isCustom {
            return Int(customHeight) ?? 1080
        }
        return selectedPreset.height
    }

    private var frameDelay: Double {
        guard frameRate > 0 else { return 100 }
        return 1000.0 / frameRate
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create New Sequence")
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Sequence name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Canvas
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Canvas")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("", selection: $isCustom) {
                            Text("Preset").tag(false)
                            Text("Custom").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        if !isCustom {
                            // Preset dropdown
                            Picker("Preset", selection: $selectedPreset) {
                                ForEach(CanvasPreset.presets) { preset in
                                    Text(preset.displayName).tag(preset)
                                }
                            }
                            .labelsHidden()
                        } else {
                            // Custom dimensions
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Width")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    TextField("Width", text: $customWidth)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                }

                                Text("×")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 12)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Height")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    TextField("Height", text: $customHeight)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                }
                            }
                        }
                    }

                    Divider()

                    // Frame Rate
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Frame Rate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(frameRate)) fps")
                                .font(.caption)
                                .monospacedDigit()
                            Text("•")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text("\(Int(frameDelay)) ms (\(String(format: "%.1f", frameDelay / 10)) cs)")
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $frameRate, in: 1...60, step: 1)
                    }

                    Divider()

                    // Default Fit Mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Fit Mode")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Fit Mode", selection: $defaultFitMode) {
                            ForEach(FrameFitMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    createSequence()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || resolvedWidth <= 0 || resolvedHeight <= 0)
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }

    private func createSequence() {
        _ = project.createSequence(
            name: name,
            width: resolvedWidth,
            height: resolvedHeight,
            frameRate: frameRate,
            fitMode: defaultFitMode,
            inBin: false
        )
        isPresented = false
    }
}

#Preview {
    NewSequenceSheet(project: Project(), isPresented: .constant(true))
}
