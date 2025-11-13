//
//  TimelineView.swift
//  Phosphor
//
//  Created on 2025-11-12
//

import SwiftUI

struct TimelineView: View {
    @ObservedObject var project: Project
    @Binding var selectedFrameIDs: Set<UUID>
    @State private var thumbnailZoom: Double = 1.0 // 0.5 to 2.0
    @State private var draggedFrameID: UUID?
    @State private var isDropTargeted = false

    private let minThumbnailWidth: CGFloat = 60
    private let maxThumbnailWidth: CGFloat = 200
    private let baseWidth: CGFloat = 100

    private var thumbnailWidth: CGFloat {
        baseWidth * thumbnailZoom
    }

    var sequence: Sequence? {
        project.activeSequence
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Timeline")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let seq = sequence {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(seq.frames.count) frames")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Zoom controls
                HStack(spacing: 8) {
                    Button(action: { zoomOut() }) {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    .disabled(thumbnailZoom <= 0.5)

                    Slider(value: $thumbnailZoom, in: 0.5...2.0)
                        .frame(width: 80)

                    Button(action: { zoomIn() }) {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    .disabled(thumbnailZoom >= 2.0)
                }
                .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Timeline strip
            if let sequence = sequence {
                if sequence.frames.isEmpty {
                    emptyTimelineView
                } else {
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 8) {
                            ForEach(Array(sequence.frames.enumerated()), id: \.element.id) { index, frame in
                                TimelineFrameView(
                                    frame: frame,
                                    item: project.image(for: frame.imageID),
                                    index: index,
                                    sequence: sequence,
                                    thumbnailWidth: thumbnailWidth,
                                    isSelected: selectedFrameIDs.contains(frame.id),
                                    onSelect: { toggleSelection(frame.id) }
                                )
                                .onDrag {
                                    draggedFrameID = frame.id
                                    return NSItemProvider(object: frame.id.uuidString as NSString)
                                }
                                .onDrop(of: [.text], delegate: FrameDropDelegate(
                                    frame: frame,
                                    sequence: sequence,
                                    draggedFrameID: $draggedFrameID
                                ))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .frame(height: thumbnailWidth / sequence.aspectRatio + 50)
                    .onDrop(of: [.text], isTargeted: $isDropTargeted) { providers in
                        handleDrop(providers: providers, at: sequence.frames.count)
                    }
                    .overlay {
                        if isDropTargeted {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.orange, lineWidth: 3, antialiased: true)
                                .background(Color.orange.opacity(0.1))
                                .padding(4)
                        }
                    }
                }
            } else {
                emptySequenceView
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var emptyTimelineView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Drag images from Media Library to add frames")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 150)
        .onDrop(of: [.text], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers, at: 0)
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.orange, lineWidth: 3, antialiased: true)
                    .background(Color.orange.opacity(0.1))
                    .padding(4)
            }
        }
    }

    private var emptySequenceView: some View {
        VStack(spacing: 12) {
            Image(systemName: "film")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Select or create a sequence")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 150)
    }

    private func zoomIn() {
        thumbnailZoom = min(thumbnailZoom + 0.25, 2.0)
    }

    private func zoomOut() {
        thumbnailZoom = max(thumbnailZoom - 0.25, 0.5)
    }

    private func toggleSelection(_ id: UUID) {
        if selectedFrameIDs.contains(id) {
            selectedFrameIDs.remove(id)
        } else {
            selectedFrameIDs.insert(id)
        }
    }

    private func handleDrop(providers: [NSItemProvider], at index: Int) -> Bool {
        guard let sequence = sequence else { return false }

        for provider in providers {
            _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                guard let idString = string as? String,
                      let uuid = UUID(uuidString: idString) else { return }

                DispatchQueue.main.async {
                    // Check if it's a media item
                    if project.image(for: uuid) != nil {
                        sequence.insertFrame(imageID: uuid, at: index)
                    }
                }
            }
        }

        return true
    }
}

// MARK: - Timeline Frame View

struct TimelineFrameView: View {
    @ObservedObject var frame: SequenceFrame
    let item: ImageItem?
    let index: Int
    let sequence: Sequence
    let thumbnailWidth: CGFloat
    let isSelected: Bool
    let onSelect: () -> Void

    private var thumbnailHeight: CGFloat {
        thumbnailWidth / sequence.aspectRatio
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                // Thumbnail
                if let item = item, let thumbnail = item.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                        .clipped()
                        .cornerRadius(6)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                        .cornerRadius(6)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }

                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.accentColor, lineWidth: 3)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                }

                // Disabled overlay
                if !frame.isEnabled {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.5))
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                }

                // Badges
                VStack(alignment: .trailing, spacing: 4) {
                    if frame.customDelay != nil {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                    }

                    if frame.fitMode != sequence.defaultFitMode {
                        Image(systemName: frame.fitMode.icon)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.orange.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
            }

            // Frame number
            Text("#\(index + 1)")
                .font(.caption2)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Drop Delegate for Reordering

struct FrameDropDelegate: DropDelegate {
    let frame: SequenceFrame
    let sequence: Sequence
    @Binding var draggedFrameID: UUID?

    func performDrop(info: DropInfo) -> Bool {
        draggedFrameID = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedID = draggedFrameID,
              draggedID != frame.id,
              let fromIndex = sequence.frames.firstIndex(where: { $0.id == draggedID }),
              let toIndex = sequence.frames.firstIndex(where: { $0.id == frame.id })
        else { return }

        withAnimation(.default) {
            sequence.frames.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
}

#Preview {
    let project = Project()
    let _ = project.createSequence(name: "Test", width: 1920, height: 1080, frameRate: 24, fitMode: .fill)
    return TimelineView(project: project)
        .frame(width: 800, height: 200)
}
