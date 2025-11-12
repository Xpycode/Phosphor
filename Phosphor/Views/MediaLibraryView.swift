//
//  MediaLibraryView.swift
//  Phosphor
//
//  Created on 2025-11-12
//

import SwiftUI

struct MediaLibraryView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedItems = Set<UUID>()
    @State private var draggedItems: [ImageItem] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Media Library")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.mediaLibrary.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Import progress
            if viewModel.mediaLibrary.isImporting {
                VStack(spacing: 4) {
                    ProgressView(value: viewModel.mediaLibrary.importProgress)
                        .progressViewStyle(.linear)
                    Text("Importing... \(Int(viewModel.mediaLibrary.importProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            // Media grid
            if viewModel.mediaLibrary.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No media imported")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Drop images here or use Import")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 8)
                    ], spacing: 8) {
                        ForEach(viewModel.mediaLibrary.items) { item in
                            MediaLibraryItemView(
                                item: item,
                                isSelected: selectedItems.contains(item.id),
                                hasAspectMismatch: hasAspectMismatch(item),
                                onSelect: {
                                    toggleSelection(item)
                                },
                                onDoubleClick: {
                                    addToActiveSequence([item])
                                },
                                onDrag: {
                                    draggedItems = [item]
                                    return NSItemProvider(object: item.id.uuidString as NSString)
                                }
                            )
                        }
                    }
                    .padding(8)
                }
            }

            Divider()

            // Actions
            HStack(spacing: 8) {
                Button(action: importImages) {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderless)

                Spacer()

                if !selectedItems.isEmpty {
                    Button(action: addSelectedToSequence) {
                        Label("Add to Sequence", systemImage: "plus.rectangle.on.folder")
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.activeSequence == nil)

                    Button(action: removeSelected) {
                        Label("Remove", systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            }
            .padding(8)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func toggleSelection(_ item: ImageItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }

    private func addSelectedToSequence() {
        let itemsToAdd = viewModel.mediaLibrary.items.filter { selectedItems.contains($0.id) }
        addToActiveSequence(itemsToAdd)
        selectedItems.removeAll()
    }

    private func addToActiveSequence(_ items: [ImageItem]) {
        guard viewModel.activeSequence != nil else { return }
        let ids = items.map { $0.id }
        viewModel.addImagesToActiveSequence(imageIDs: ids)
    }

    private func removeSelected() {
        let itemsToRemove = viewModel.mediaLibrary.items.filter { selectedItems.contains($0.id) }
        viewModel.mediaLibrary.removeItems(itemsToRemove)
        selectedItems.removeAll()
    }

    private func importImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = ImageItem.supportedContentTypes

        if panel.runModal() == .OK {
            viewModel.importImagesIntoLibrary(from: panel.urls, addToActiveSequence: false)
        }
    }

    private func hasAspectMismatch(_ item: ImageItem) -> Bool {
        guard let sequence = viewModel.activeSequence else { return false }
        return viewModel.hasAspectMismatch(item: item, in: sequence)
    }
}

struct MediaLibraryItemView: View {
    let item: ImageItem
    let isSelected: Bool
    let hasAspectMismatch: Bool
    let onSelect: () -> Void
    let onDoubleClick: () -> Void
    let onDrag: () -> NSItemProvider

    var body: some View {
        ZStack {
            // Background layer with content
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    // Thumbnail
                    Group {
                        if let thumbnail = item.thumbnail {
                            Image(nsImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 60)
                                .clipped()
                                .cornerRadius(4)
                        } else {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 100, height: 60)
                                .cornerRadius(4)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )

                    // Aspect mismatch badge
                    if hasAspectMismatch {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(4)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.9))
                            .clipShape(Circle())
                            .padding(4)
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.fileName)
                        .font(.caption2)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(item.resolutionString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 100)
            }
            .padding(4)
            .allowsHitTesting(false)

            // Foreground invisible clickable rectangle
            Rectangle()
                .fill(Color.white.opacity(0.001))  // Tiny bit visible so it gets hit testing
                .onTapGesture(count: 2) {
                    print("Double tap triggered!")
                    onDoubleClick()
                }
                .onTapGesture(count: 1) {
                    print("Single tap triggered!")
                    onSelect()
                }
        }
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onDrag(onDrag)
    }
}

#Preview {
    MediaLibraryView(viewModel: AppViewModel())
        .frame(width: 300, height: 600)
}
