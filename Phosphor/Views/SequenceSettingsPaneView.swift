//
//  SequenceSettingsPaneView.swift
//  Phosphor
//
//  Created on 2025-11-13
//  Top-right pane for sequence settings (canvas, FPS, fit mode, etc.)
//

import SwiftUI

struct SequenceSettingsPaneView: View {
    @ObservedObject var project: Project

    private var activeSequence: Sequence? {
        project.activeSequence
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SEQUENCE SETTINGS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Content
            if let sequence = activeSequence {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Sequence Name
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("Sequence name", text: $project.activeSequence!.name)
                                .textFieldStyle(.roundedBorder)
                        }

                        Divider()

                        // Canvas Size
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Canvas Size")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                TextField("Width", value: $project.activeSequence!.width, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)

                                Text("×")
                                    .foregroundColor(.secondary)

                                TextField("Height", value: $project.activeSequence!.height, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }

                            Text("\(sequence.width) × \(sequence.height) px")
                                .font(.caption2)
                                .foregroundColor(.tertiary)
                        }

                        Divider()

                        // Frame Rate
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Frame Rate")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                TextField("FPS", value: $project.activeSequence!.frameRate, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)

                                Text("fps")
                                    .foregroundColor(.secondary)
                            }

                            Text("\(String(format: "%.1f", sequence.frameDelay)) ms delay")
                                .font(.caption2)
                                .foregroundColor(.tertiary)
                        }

                        Divider()

                        // Default Fit Mode
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Default Fit Mode")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("Fit Mode", selection: $project.activeSequence!.defaultFitMode) {
                                ForEach(FrameFitMode.allCases, id: \.self) { mode in
                                    HStack {
                                        Image(systemName: mode.icon)
                                        Text(mode.rawValue)
                                    }
                                    .tag(mode)
                                }
                            }
                            .pickerStyle(.radioGroup)
                        }

                        Divider()

                        // Loop Count
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Loop Count")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                TextField("Loops", value: $project.activeSequence!.loopCount, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)

                                Text(sequence.loopCount == 0 ? "(infinite)" : "times")
                                    .foregroundColor(.secondary)
                                    .font(.caption2)
                            }

                            Text("0 = infinite loop")
                                .font(.caption2)
                                .foregroundColor(.tertiary)
                        }

                        Divider()

                        // Frame Count
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Frames")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(sequence.frames.count) total")
                                .font(.body)

                            Text("\(sequence.enabledFrames.count) enabled")
                                .font(.caption2)
                                .foregroundColor(.tertiary)
                        }

                        Spacer()
                    }
                    .padding(12)
                }
            } else {
                // No active sequence
                VStack(spacing: 12) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Select a sequence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    let project = Project()
    let _ = project.createSequence(name: "Test Sequence", width: 1080, height: 1080, frameRate: 10, fitMode: .fill)
    return SequenceSettingsPaneView(project: project)
        .frame(width: 300, height: 600)
}
