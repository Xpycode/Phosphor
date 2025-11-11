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
    private let footerHeight: CGFloat = 60
    @AppStorage("useOrangeAccent") private var useOrangeAccent = false

    private var accentColor: Color {
        useOrangeAccent ? .orange : Color(nsColor: NSColor.controlAccentColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Images")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
            // let frame height stay at 24
                .frame(height: 24)

            Divider()

            // Sort Order Picker
            HStack {
                Spacer()

                HStack(spacing: 8) {
                   

                Picker("", selection: $viewModel.settings.sortOrder) {
                    Text("File Name").tag(SortOrder.fileName)
                    Text("Modified").tag(SortOrder.modificationDate)
                    Text("Manual").tag(SortOrder.manual)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .tint(accentColor)
                }

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

            // Bottom Toolbar / Import Progress
            if viewModel.isImporting {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        ProgressView(value: viewModel.importProgress)
                            .progressViewStyle(.linear)

                        Button(action: viewModel.cancelImport) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.body)
                        }
                        .buttonStyle(.plain)
                        .frame(height: 20, alignment: .center)
                        .help("Cancel import")
                    }

                    Text("Importing images… \(Int(viewModel.importProgress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .frame(height: footerHeight)
            } else {
                HStack {
                    Button(action: importImages) {
                        Label("Add Images", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    Text("\(viewModel.sortedImages.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(action: viewModel.clearAll) {
                        Label("Clear All", systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.imageItems.isEmpty)
                }
                .padding(.horizontal, 16)
                .frame(height: footerHeight)
            }
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
        guard !providers.isEmpty else { return false }

        var collectedURLs: [URL] = []
        var completedProviders = 0

        func finalizeIfNeeded() {
            completedProviders += 1
            if completedProviders == providers.count, !collectedURLs.isEmpty {
                viewModel.addImages(from: collectedURLs)
            }
        }

        for provider in providers {
            guard provider.canLoadObject(ofClass: URL.self) else {
                DispatchQueue.main.async {
                    finalizeIfNeeded()
                }
                continue
            }

            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                DispatchQueue.main.async {
                    if let url {
                        collectedURLs.append(url)
                    }
                    finalizeIfNeeded()
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
    private let thumbnailCanvasSize = CGSize(width: 120, height: 72)
    private let rowHeight: CGFloat = 84

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
            thumbnailCanvas

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

                let isOutlier = viewModel.isAspectOutlier(item)
                HStack(spacing: 4) {
                    Image(systemName: isOutlier ? "exclamationmark.triangle.fill" : "aspectratio")
                        .font(.system(size: 9))
                    Text("Aspect \(viewModel.aspectRatioLabel(for: item))")
                        .font(.system(size: 10))
                }
                .foregroundColor(isOutlier ? .orange : .secondary)
                .help(aspectHelpText(isOutlier: isOutlier))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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

    private func aspectHelpText(isOutlier: Bool) -> String {
        if isOutlier, let dominant = viewModel.dominantAspectLabel {
            return "Dominant aspect \(dominant). This frame will be cropped to match."
        } else {
            return "Matches dominant aspect ratio."
        }
    }
}

private extension FileItemRow {
    var thumbnailCanvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.12))

            if let thumbnail = item.thumbnail {
                let displaySize = thumbnailDisplaySize(for: thumbnail.size)
                Image(nsImage: thumbnail)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: displaySize.width, height: displaySize.height)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: thumbnailCanvasSize.width, height: thumbnailCanvasSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    func thumbnailDisplaySize(for originalSize: CGSize) -> CGSize {
        guard originalSize.width > 0, originalSize.height > 0 else {
            return thumbnailCanvasSize
        }

        let widthScale = thumbnailCanvasSize.width / originalSize.width
        let heightScale = thumbnailCanvasSize.height / originalSize.height
        let scale = min(1, min(widthScale, heightScale))

        return CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
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
