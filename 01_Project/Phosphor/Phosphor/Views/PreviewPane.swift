//
//  PreviewPane.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

struct PreviewPane: View {
    @ObservedObject var appState: AppState

    /// The frame currently being displayed
    private var displayedFrame: ImageItem? {
        guard appState.hasFrames else { return nil }
        let index = appState.currentPreviewIndex
        guard appState.frames.indices.contains(index) else { return nil }
        return appState.frames[index]
    }

    var body: some View {
        ZStack {
            Color(NSColor.controlBackgroundColor)

            if let frame = displayedFrame {
                framePreview(frame)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            PlaybackControlsView(appState: appState)
        }
    }

    @ViewBuilder
    private func framePreview(_ frame: ImageItem) -> some View {
        GeometryReader { geometry in
            if let nsImage = NSImage(contentsOf: frame.url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                // Fallback if image fails to load
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text("Could not load image")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Import images to preview")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    PreviewPane(appState: AppState())
}
