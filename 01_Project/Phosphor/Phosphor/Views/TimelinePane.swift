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

    @State private var draggedFrameID: UUID?
    @State private var dropTargetIndex: Int?

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
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    private var emptyStateView: some View {
        // Drop zone indicator only - import button is in toolbar
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.6))

            Text("Drop images here")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var timelineContentView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 8) {
                ForEach(Array(appState.frames.enumerated()), id: \.element.id) { index, frame in
                    ZStack {
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
                        .onDrag {
                            draggedFrameID = frame.id
                            return NSItemProvider(object: frame.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: FrameDropDelegate(
                            draggedFrameID: $draggedFrameID,
                            dropTargetIndex: $dropTargetIndex,
                            frames: appState.frames,
                            destinationIndex: index,
                            appState: appState
                        ))

                        if dropTargetIndex == index {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 3)
                                .frame(maxHeight: .infinity)
                                .offset(x: -(appState.thumbnailWidth / 2 + 4))
                        }
                    }
                }
            }
            .padding(8)
        }
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

struct FrameDropDelegate: DropDelegate {
    @Binding var draggedFrameID: UUID?
    @Binding var dropTargetIndex: Int?
    let frames: [ImageItem]
    let destinationIndex: Int
    let appState: AppState

    func dropEntered(info: DropInfo) {
        dropTargetIndex = destinationIndex
    }

    func dropExited(info: DropInfo) {
        if dropTargetIndex == destinationIndex {
            dropTargetIndex = nil
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedID = draggedFrameID,
              let sourceIndex = frames.firstIndex(where: { $0.id == draggedID }) else {
            return false
        }

        if sourceIndex != destinationIndex {
            appState.reorderFrames(from: IndexSet(integer: sourceIndex), to: destinationIndex)
        }

        draggedFrameID = nil
        dropTargetIndex = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

#Preview {
    TimelinePane(appState: AppState())
        .frame(height: 150)
}
