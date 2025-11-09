//
//  FileListView.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isTargeted = false
    @State private var draggingItem: ImageItem?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Text("Images")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Spacer()
                    Text("\(viewModel.sortedImages.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .frame(height: 44)

            Divider()

            // Sort Order Picker
            HStack(spacing: 8) {
                Text("Sort")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("", selection: $viewModel.settings.sortOrder) {
                    Text("File Name").tag(SortOrder.fileName)
                    Text("Modified").tag(SortOrder.modificationDate)
                    Text("Manual").tag(SortOrder.manual)
                }
                .labelsHidden()
                .pickerStyle(.segmented)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .padding(.bottom, 6)

            // File List
            if viewModel.imageItems.isEmpty {
                emptyStateView
            } else if viewModel.settings.sortOrder == .manual {
                manualReorderList
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.sortedImages.enumerated()), id: \.element.id) { index, item in
                            FileItemRow(
                                item: item,
                                index: index,
                                viewModel: viewModel,
                                isManualMode: false
                            )
                            .contentShape(Rectangle())
                        }
                    }
                }
            }

            Divider()

            // Bottom Toolbar
            HStack {
                Button(action: importImages) {
                    Label("Add Images", systemImage: "plus")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(action: viewModel.clearAll) {
                    Label("Clear All", systemImage: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.imageItems.isEmpty)
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
        .overlay {
            if isTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .padding(4)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Images")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Drag and drop images here\nor click Add Images")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button(action: importImages) {
                Label("Add Images", systemImage: "plus")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func importImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = ImageItem.supportedContentTypes

        if panel.runModal() == .OK {
            viewModel.addImages(from: panel.urls)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []

        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url {
                        DispatchQueue.main.async {
                            urls.append(url)
                            if urls.count == providers.count {
                                viewModel.addImages(from: urls)
                            }
                        }
                    }
                }
            }
        }

        return true
    }
}

private struct ClearListBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 13.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

private extension FileListView {
    var manualReorderList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.imageItems.enumerated()), id: \.element.id) { index, item in
                    FileItemRow(
                        item: item,
                        index: index,
                        viewModel: viewModel,
                        isManualMode: true
                    )
                    .contentShape(Rectangle())
                    .onDrag {
                        draggingItem = item
                        return NSItemProvider(object: NSString(string: item.id.uuidString))
                    }
                    .onDrop(
                        of: [.text],
                        delegate: ManualDropDelegate(
                            viewModel: viewModel,
                            targetItem: item,
                            draggingItem: $draggingItem
                        )
                    )
                }
            }
        }
    }
}

struct FileItemRow: View {
    let item: ImageItem
    let index: Int
    @ObservedObject var viewModel: AppViewModel
    var isManualMode: Bool = false
    private let rowHeight: CGFloat = 72

    private var thumbnailWidth: CGFloat {
        let height = item.resolution.height
        guard height > 0 else { return rowHeight }
        let ratio = item.resolution.width / height
        let width = rowHeight * CGFloat(ratio)
        // Prevent extreme panoramas from taking over the row
        return min(max(width, rowHeight * 0.6), rowHeight * 3)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Frame Number / Drag Handle (in manual mode)
            Text("#\(index + 1)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isManualMode ? .primary : .secondary)
                .frame(width: 28, alignment: .leading)
                .contentShape(Rectangle())
                .opacity(isManualMode ? 1.0 : 0.6)

            // Thumbnail
            if let thumbnail = item.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailWidth, height: rowHeight)
                    .clipped()
                    .cornerRadius(4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: thumbnailWidth, height: rowHeight)
                    .cornerRadius(4)
            }

            // File Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.fileName)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    Text(item.resolutionString)
                    Text("•")
                    Text(item.fileSizeFormatted)
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Remove Button
            Button(action: {
                viewModel.removeImage(item)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove image")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(minHeight: rowHeight)
        .background(viewModel.currentFrameIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.seekToFrame(index)
        }
    }
}

// MARK: - View Extension for Conditional Modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

private struct ManualDropDelegate: DropDelegate {
    let viewModel: AppViewModel
    let targetItem: ImageItem
    @Binding var draggingItem: ImageItem?

    func dropEntered(info: DropInfo) {
        guard
            let draggingItem,
            draggingItem != targetItem,
            let fromIndex = viewModel.imageItems.firstIndex(of: draggingItem),
            let toIndex = viewModel.imageItems.firstIndex(of: targetItem)
        else { return }

        viewModel.moveItems(
            from: IndexSet(integer: fromIndex),
            to: toIndex > fromIndex ? toIndex + 1 : toIndex
        )
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

#Preview {
    FileListView(viewModel: AppViewModel())
        .frame(width: 300, height: 600)
}
