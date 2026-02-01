//
//  FrameThumbnailView.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

struct FrameThumbnailView: View {
    let imageItem: ImageItem
    let index: Int
    let isSelected: Bool
    let isMuted: Bool
    let thumbnailWidth: CGFloat
    let onDelete: () -> Void
    let onToggleMute: () -> Void

    @State private var isHovered = false

    /// Thumbnail height maintains 4:3 aspect ratio
    private var thumbnailHeight: CGFloat {
        thumbnailWidth * 0.75
    }

    var body: some View {
        VStack(spacing: 4) {
            // Thumbnail area
            ZStack(alignment: .topTrailing) {
                Group {
                    if let thumbnail = imageItem.thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                            Image(systemName: "questionmark")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: thumbnailWidth, height: thumbnailHeight)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )

                // Muted overlay
                if isMuted {
                    ZStack {
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .cornerRadius(4)

                        Image(systemName: "eye.slash")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(width: thumbnailWidth, height: thumbnailHeight)
                }

                // Transform badge
                if !imageItem.transform.isIdentity {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 16, height: 16)

                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white)
                            }
                            .padding(4)
                        }
                        Spacer()
                    }
                    .frame(width: thumbnailWidth, height: thumbnailHeight)
                }

                // Hover action buttons
                if isHovered {
                    HStack(spacing: 4) {
                        // Mute/Unmute button
                        Button(action: onToggleMute) {
                            ZStack {
                                Circle()
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .frame(width: 20, height: 20)

                                Image(systemName: isMuted ? "eye" : "eye.slash")
                                    .font(.system(size: 10))
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())

                        // Delete button
                        Button(action: onDelete) {
                            ZStack {
                                Circle()
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .frame(width: 20, height: 20)

                                Image(systemName: "trash")
                                    .font(.system(size: 10))
                                    .foregroundColor(.red)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                    }
                    .padding(4)
                }
            }
            .onHover { isHovered = $0 }

            // Frame number
            Text("\(index + 1)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview("Selected") {
    FrameThumbnailView(
        imageItem: previewImageItem(),
        index: 0,
        isSelected: true,
        isMuted: false,
        thumbnailWidth: 80,
        onDelete: {},
        onToggleMute: {}
    )
    .padding()
}

#Preview("Unselected") {
    FrameThumbnailView(
        imageItem: previewImageItem(),
        index: 4,
        isSelected: false,
        isMuted: false,
        thumbnailWidth: 80,
        onDelete: {},
        onToggleMute: {}
    )
    .padding()
}

#Preview("Muted") {
    FrameThumbnailView(
        imageItem: previewImageItem(),
        index: 2,
        isSelected: false,
        isMuted: true,
        thumbnailWidth: 80,
        onDelete: {},
        onToggleMute: {}
    )
    .padding()
}

private func previewImageItem() -> ImageItem {
    ImageItem(
        url: URL(fileURLWithPath: "/tmp/test.png"),
        thumbnail: nil,
        resolution: CGSize(width: 100, height: 100),
        fileSize: 1024,
        modificationDate: Date()
    )
}
