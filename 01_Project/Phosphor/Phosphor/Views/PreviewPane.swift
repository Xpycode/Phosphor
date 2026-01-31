//
//  PreviewPane.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

struct PreviewPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings: ExportSettings

    /// The frame currently being displayed
    private var displayedFrame: ImageItem? {
        guard appState.hasFrames else { return nil }
        let index = appState.currentPreviewIndex
        guard appState.frames.indices.contains(index) else { return nil }
        return appState.frames[index]
    }

    /// Whether canvas scaling is active (not Original mode)
    private var isCanvasActive: Bool {
        settings.canvasMode != .original
    }

    /// Canvas aspect ratio (width / height)
    private var canvasAspectRatio: CGFloat? {
        guard isCanvasActive,
              let size = settings.resolvedCanvasSize,
              size.height > 0 else { return nil }
        return size.width / size.height
    }

    var body: some View {
        ZStack {
            Color(NSColor.controlBackgroundColor)

            if let frame = displayedFrame {
                if isCanvasActive, let aspectRatio = canvasAspectRatio {
                    canvasPreview(frame: frame, aspectRatio: aspectRatio)
                } else {
                    originalPreview(frame: frame)
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            PlaybackControlsView(appState: appState)
        }
    }

    // MARK: - Original Preview (no canvas scaling)

    @ViewBuilder
    private func originalPreview(frame: ImageItem) -> some View {
        GeometryReader { geometry in
            if let nsImage = NSImage(contentsOf: frame.url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                imageLoadError
            }
        }
    }

    // MARK: - Canvas Preview (with Fit/Fill)

    @ViewBuilder
    private func canvasPreview(frame: ImageItem, aspectRatio: CGFloat) -> some View {
        GeometryReader { geometry in
            // Calculate canvas frame size to fit within the preview area
            let canvasSize = calculateCanvasSize(
                aspectRatio: aspectRatio,
                availableSize: geometry.size
            )

            ZStack {
                // Canvas background (visible in Fit mode as letterbox)
                if settings.scaleMode == .fit {
                    canvasBackground
                        .frame(width: canvasSize.width, height: canvasSize.height)
                }

                // The image, scaled according to mode
                if let nsImage = NSImage(contentsOf: frame.url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: settings.scaleMode == .fill ? .fill : .fit)
                        .frame(width: canvasSize.width, height: canvasSize.height)
                        .clipped()
                } else {
                    imageLoadError
                }

                // Canvas border indicator
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: canvasSize.width, height: canvasSize.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    /// Calculate the canvas frame size that fits within available space
    private func calculateCanvasSize(aspectRatio: CGFloat, availableSize: CGSize) -> CGSize {
        let availableAspect = availableSize.width / availableSize.height

        if aspectRatio > availableAspect {
            // Canvas is wider than available space - constrain by width
            let width = availableSize.width * 0.9  // 90% to leave some margin
            return CGSize(width: width, height: width / aspectRatio)
        } else {
            // Canvas is taller than available space - constrain by height
            let height = availableSize.height * 0.9
            return CGSize(width: height * aspectRatio, height: height)
        }
    }

    /// Background for letterbox (Fit mode)
    @ViewBuilder
    private var canvasBackground: some View {
        if settings.useAutoBackgroundColor {
            // Show a neutral dark background for preview (actual export will sample corner pixel)
            Color(NSColor.darkGray)
        } else {
            Color(settings.fitBackgroundColor)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Images", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Import images to create an animated GIF or APNG")
        }
    }

    // MARK: - Error State

    private var imageLoadError: some View {
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

#Preview {
    PreviewPane(appState: AppState(), settings: ExportSettings())
}
