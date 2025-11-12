//
//  FrameSettingsView.swift
//  Phosphor
//
//  Created on 2025-11-12
//

import SwiftUI

struct FrameSettingsView: View {
    @ObservedObject var project: Project
    let selectedFrameIDs: Set<UUID>

    private var selectedFrames: [SequenceFrame] {
        guard let sequence = project.activeSequence else { return [] }
        return sequence.frames.filter { selectedFrameIDs.contains($0.id) }
    }

    private var isSingleSelection: Bool {
        selectedFrames.count == 1
    }

    private var firstFrame: SequenceFrame? {
        selectedFrames.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Frame Settings")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if !selectedFrames.isEmpty {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(selectedFrames.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if selectedFrames.isEmpty {
                emptySelectionView
            } else if isSingleSelection, let frame = firstFrame {
                singleFrameSettings(frame: frame)
            } else {
                multiFrameSettings()
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Empty State

    private var emptySelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Select frames in the timeline to edit settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Single Frame Settings

    private func singleFrameSettings(frame: SequenceFrame) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image info
                if let item = project.image(for: frame.imageID) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            if let thumbnail = item.thumbnail {
                                Image(nsImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 45)
                                    .clipped()
                                    .cornerRadius(4)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.fileName)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text(item.resolutionString)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()
                }

                // Frame Delay
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Frame Delay")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        if let customDelay = frame.customDelay {
                            Text("\(Int(customDelay)) ms")
                                .font(.caption)
                                .monospacedDigit()

                            Button("Reset") {
                                frame.customDelay = nil
                            }
                            .buttonStyle(.borderless)
                            .font(.caption2)
                        } else if let sequence = project.activeSequence {
                            Text("\(Int(sequence.frameDelay)) ms (default)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Slider(
                        value: Binding(
                            get: {
                                frame.customDelay ?? project.activeSequence?.frameDelay ?? 100
                            },
                            set: { newValue in
                                frame.customDelay = newValue
                            }
                        ),
                        in: 10...1000,
                        step: 10
                    )

                    HStack {
                        Text("10 ms")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                        Spacer()
                        Text("1000 ms")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }

                Divider()

                // Fit Mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fit Mode")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Fit Mode", selection: Binding(
                        get: { frame.fitMode },
                        set: { frame.fitMode = $0 }
                    )) {
                        ForEach(FrameFitMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)

                    Text(fitModeDescription(frame.fitMode))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Enable/Disable
                Toggle("Include in export", isOn: Binding(
                    get: { frame.isEnabled },
                    set: { frame.isEnabled = $0 }
                ))
                .font(.caption)

                Divider()

                // Remove
                Button(role: .destructive, action: {
                    removeFrame(frame)
                }) {
                    Label("Remove Frame", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding()
        }
    }

    // MARK: - Multi Frame Settings

    private func multiFrameSettings() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Bulk delay
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apply Delay to All Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Slider(value: $bulkDelay, in: 10...1000, step: 10)
                        Text("\(Int(bulkDelay)) ms")
                            .font(.caption)
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }

                    Button("Apply") {
                        applyBulkDelay()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }

                Divider()

                // Bulk fit mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apply Fit Mode to All Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Fit Mode", selection: $bulkFitMode) {
                        ForEach(FrameFitMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)

                    Button("Apply") {
                        applyBulkFitMode()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }

                Divider()

                // Bulk enable/disable
                HStack {
                    Button("Enable All") {
                        selectedFrames.forEach { $0.isEnabled = true }
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)

                    Button("Disable All") {
                        selectedFrames.forEach { $0.isEnabled = false }
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }

                Divider()

                // Remove
                Button(role: .destructive, action: {
                    removeSelectedFrames()
                }) {
                    Label("Remove \(selectedFrames.count) Frames", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding()
        }
    }

    // MARK: - Bulk Operations

    @State private var bulkDelay: Double = 100
    @State private var bulkFitMode: FrameFitMode = .fill

    private func applyBulkDelay() {
        selectedFrames.forEach { $0.customDelay = bulkDelay }
    }

    private func applyBulkFitMode() {
        selectedFrames.forEach { $0.fitMode = bulkFitMode }
    }

    // MARK: - Helpers

    private func fitModeDescription(_ mode: FrameFitMode) -> String {
        switch mode {
        case .fill:
            return "Scale to cover canvas, crop edges if needed"
        case .fit:
            return "Scale to fit inside canvas, letterbox if needed"
        case .stretch:
            return "Distort to fill canvas exactly"
        case .custom:
            return "Manual crop and position (not yet implemented)"
        }
    }

    private func removeFrame(_ frame: SequenceFrame) {
        guard let sequence = project.activeSequence,
              let index = sequence.frames.firstIndex(where: { $0.id == frame.id }) else { return }
        sequence.removeFrame(at: index)
    }

    private func removeSelectedFrames() {
        guard let sequence = project.activeSequence else { return }
        let idsToRemove = Set(selectedFrames.map { $0.id })
        sequence.frames.removeAll { idsToRemove.contains($0.id) }
    }
}

#Preview {
    let project = Project()
    let _ = project.createSequence(name: "Test", width: 1920, height: 1080, frameRate: 24, fitMode: .fill)
    return FrameSettingsView(project: project, selectedFrameIDs: [])
        .frame(width: 400, height: 400)
}
