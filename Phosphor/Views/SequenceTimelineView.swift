//
//  SequenceTimelineView.swift
//  Phosphor
//
//  Created on 2025-11-12
//

import SwiftUI

struct SequenceTimelineView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedFrameID: UUID?

    var sequence: PhosphorSequence? {
        viewModel.activeSequence
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sequence selector header
            sequenceHeader

            Divider()

            if let sequence = sequence {
                // Canvas info
                canvasInfoSection(for: sequence)

                Divider()

                // Timeline strip
                timelineStrip(for: sequence)

                Divider()

                // Per-frame settings (when a frame is selected)
                if let selectedID = selectedFrameID,
                   let frame = sequence.frames.first(where: { $0.id == selectedID }) {
                    frameSettingsPanel(for: frame, in: sequence)
                } else {
                    emptyFrameSelection
                }
            } else {
                emptySequenceView
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Sequence Header

    private var sequenceHeader: some View {
        HStack {
            Menu {
                if viewModel.sequences.isEmpty {
                    Text("No sequences")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.sequences) { seq in
                        Button(action: {
                            viewModel.activeSequenceID = seq.id
                        }) {
                            HStack {
                                Text(seq.displayName)
                                if seq.id == viewModel.activeSequenceID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Divider()

                Button("New Sequence") {
                    viewModel.createNewSequence()
                }
            } label: {
                HStack {
                    Text(sequence?.displayName ?? "No Sequence")
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if sequence != nil {
                Button(action: {
                    if let seq = sequence {
                        viewModel.duplicateSequence(seq)
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Duplicate sequence")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Canvas Info Section

    private func canvasInfoSection(for sequence: PhosphorSequence) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Canvas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(sequence.resolvedCanvasSize.width))×\(Int(sequence.resolvedCanvasSize.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Preset")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(sequence.canvasPreset.displayLabel)
                    .font(.caption)
            }

            HStack {
                Text("Frame Rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(sequence.frameRate)) fps")
                    .font(.caption)
            }
        }
        .padding(12)
    }

    // MARK: - Timeline Strip

    private func timelineStrip(for sequence: PhosphorSequence) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Timeline")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(sequence.enabledFrames.count) frames")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if sequence.frames.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No frames in sequence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Add from Media Library")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 8) {
                        ForEach(Array(sequence.frames.enumerated()), id: \.element.id) { index, frame in
                            if let item = viewModel.mediaLibrary.item(for: frame.imageID) {
                                TimelineFrameView(
                                    frame: frame,
                                    item: item,
                                    index: index,
                                    isSelected: selectedFrameID == frame.id,
                                    hasAspectMismatch: viewModel.hasAspectMismatch(item: item, in: sequence),
                                    onSelect: {
                                        selectedFrameID = frame.id
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(height: 100)
            }
        }
    }

    // MARK: - Frame Settings Panel

    private func frameSettingsPanel(for frame: SequenceFrame, in sequence: PhosphorSequence) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Frame Settings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    selectedFrameID = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            if let item = viewModel.mediaLibrary.item(for: frame.imageID) {
                // Frame info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.fileName)
                        .font(.caption)
                        .lineLimit(1)

                    Text(item.resolutionString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Delay override
                HStack {
                    Text("Delay")
                        .font(.caption)
                    Spacer()
                    if let customDelay = frame.customDelay {
                        Text("\(Int(customDelay)) ms")
                            .font(.caption)
                        Button("Reset") {
                            sequence.setFrameDelay(for: frame.id, delay: nil)
                        }
                        .buttonStyle(.borderless)
                        .font(.caption2)
                    } else {
                        Text("\(Int(sequence.frameDelay)) ms (default)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Include/exclude toggle
                Toggle("Include in export", isOn: Binding(
                    get: { frame.isEnabled },
                    set: { _ in sequence.toggleFrameEnabled(frameID: frame.id) }
                ))
                .font(.caption)

                // Remove frame
                Button(action: {
                    if let index = sequence.frames.firstIndex(where: { $0.id == frame.id }) {
                        sequence.removeFrame(at: index)
                        selectedFrameID = nil
                    }
                }) {
                    Label("Remove Frame", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
        }
        .padding(12)
    }

    // MARK: - Empty States

    private var emptyFrameSelection: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.tap")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Select a frame to edit")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptySequenceView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No active sequence")
                .font(.headline)
                .foregroundColor(.secondary)
            Button("Create New Sequence") {
                viewModel.createNewSequence()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TimelineFrameView: View {
    let frame: SequenceFrame
    let item: ImageItem
    let index: Int
    let isSelected: Bool
    let hasAspectMismatch: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                // Thumbnail
                Group {
                    if let thumbnail = item.thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 40)
                            .clipped()
                            .cornerRadius(4)
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 60, height: 40)
                            .cornerRadius(4)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
                .opacity(frame.isEnabled ? 1.0 : 0.4)

                // Frame number
                Text("\(index + 1)")
                    .font(.caption2)
                    .padding(2)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(2)
                    .padding(2)

                // Badges
                VStack(alignment: .trailing, spacing: 2) {
                    if hasAspectMismatch {
                        Image(systemName: "crop")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(2)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    if frame.customDelay != nil {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(2)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(2)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
        }
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    SequenceTimelineView(viewModel: AppViewModel())
        .frame(width: 400, height: 500)
}
