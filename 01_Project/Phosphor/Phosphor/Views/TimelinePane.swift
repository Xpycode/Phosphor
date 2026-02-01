//
//  TimelinePane.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI
import UniformTypeIdentifiers

struct TimelinePane: View {
    @ObservedObject var appState: AppState
    var onImport: (() -> Void)?

    @State private var draggedFrameID: UUID?
    @State private var dropTargetIndex: Int?
    @State private var isDropTargeted = false

    var body: some View {
        ZStack {
            if appState.frames.isEmpty {
                emptyStateView
            } else {
                timelineContentView
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120, idealHeight: 150)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.3))
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 3)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(4)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ContentUnavailableView {
                Label("No Images", systemImage: "photo.on.rectangle.angled")
            } description: {
                Text("Drag images here or click Add Images")
            }

            if let onImport = onImport {
                Button("Add Images") {
                    onImport()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var timelineContentView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 8) {
                ForEach(Array(appState.frames.enumerated()), id: \.element.id) { index, frame in
                    thumbnailWithDropZone(frame: frame, index: index)
                }
            }
            .padding(8)
        }
    }

    @ViewBuilder
    private func thumbnailWithDropZone(frame: ImageItem, index: Int) -> some View {
        let thumbnailHeight = appState.thumbnailWidth * 0.75  // 4:3 aspect ratio

        HStack(spacing: 0) {
            // Drop indicator (always present, visibility controlled by opacity)
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 3, height: thumbnailHeight)
                .opacity(dropTargetIndex == index ? 1.0 : 0.0)
                .padding(.trailing, 4)

            // Thumbnail button
            Button {
                appState.selectedFrameIndex = index
            } label: {
                FrameThumbnailView(
                    imageItem: frame,
                    index: index,
                    isSelected: appState.selectedFrameIndex == index,
                    isMuted: frame.isMuted,
                    thumbnailWidth: appState.thumbnailWidth,
                    onDelete: { appState.removeFrame(at: index) },
                    onToggleMute: { appState.toggleMute(at: index) }
                )
            }
            .buttonStyle(.plain)
            .opacity(draggedFrameID == frame.id ? 0.5 : 1.0)
            .draggable(frame.id.uuidString) {
                // Drag preview
                FrameThumbnailView(
                    imageItem: frame,
                    index: index,
                    isSelected: true,
                    isMuted: frame.isMuted,
                    thumbnailWidth: appState.thumbnailWidth,
                    onDelete: {},
                    onToggleMute: {}
                )
                .onAppear { draggedFrameID = frame.id }
            }
            .dropDestination(for: String.self) { items, location in
                handleFrameDrop(droppedItems: items, destinationIndex: index)
            } isTargeted: { isTargeted in
                if isTargeted {
                    dropTargetIndex = index
                } else if dropTargetIndex == index {
                    dropTargetIndex = nil
                }
            }
        }
    }

    private func handleFrameDrop(droppedItems: [String], destinationIndex: Int) -> Bool {
        guard let draggedID = draggedFrameID,
              let sourceIndex = appState.frames.firstIndex(where: { $0.id == draggedID }) else {
            draggedFrameID = nil
            dropTargetIndex = nil
            return false
        }

        if sourceIndex != destinationIndex {
            appState.reorderFrames(from: IndexSet(integer: sourceIndex), to: destinationIndex)
        }

        draggedFrameID = nil
        dropTargetIndex = nil
        return true
    }

    private func showImportPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = ImageItem.supportedContentTypes
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "Select images to import"

        if panel.runModal() == .OK {
            Task {
                await appState.importImages(urls: panel.urls)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                defer { group.leave() }

                guard let url = url, error == nil else { return }

                let contentType = UTType(filenameExtension: url.pathExtension)
                if ImageItem.supportedContentTypes.contains(where: { $0 == contentType }) {
                    urls.append(url)
                }
            }
        }

        group.notify(queue: .main) {
            if !urls.isEmpty {
                Task {
                    await appState.importImages(urls: urls)
                }
            }
        }

        return true
    }
}


#Preview {
    TimelinePane(appState: AppState(), onImport: {})
        .frame(height: 150)
}
