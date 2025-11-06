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

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Images")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.sortedImages.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 8)

            // Sort Order Buttons
            HStack(spacing: 4) {
                Text("Sort:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(action: { viewModel.settings.sortOrder = .fileName }) {
                    Label("Name", systemImage: "textformat.abc")
                        .font(.caption)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(viewModel.settings.sortOrder == .fileName ? .accentColor : .secondary)
                .help("Sort by file name")

                Button(action: { viewModel.settings.sortOrder = .modificationDate }) {
                    Label("Date", systemImage: "calendar")
                        .font(.caption)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(viewModel.settings.sortOrder == .modificationDate ? .accentColor : .secondary)
                .help("Sort by modification date")

                Button(action: { viewModel.settings.sortOrder = .manual }) {
                    Label("Manual", systemImage: "hand.point.up.left")
                        .font(.caption)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(viewModel.settings.sortOrder == .manual ? .accentColor : .secondary)
                .help("Manual order")

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // File List
            if viewModel.imageItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.sortedImages.enumerated()), id: \.element.id) { index, item in
                            FileItemRow(item: item, index: index, viewModel: viewModel)
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
        panel.allowedContentTypes = [.image]

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

struct FileItemRow: View {
    let item: ImageItem
    let index: Int
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnail = item.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
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

            // Frame Number
            Text("#\(index + 1)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)

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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(viewModel.currentFrameIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.seekToFrame(index)
        }
    }
}

#Preview {
    FileListView(viewModel: AppViewModel())
        .frame(width: 300, height: 600)
}
