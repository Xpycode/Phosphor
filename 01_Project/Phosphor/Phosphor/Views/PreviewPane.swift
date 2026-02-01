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

    /// Track the base offset when drag begins
    @State private var dragBaseOffset: CGPoint = .zero
    /// Track if a drag is currently active
    @State private var isDragging: Bool = false

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
    }

    // MARK: - Original Preview (no canvas scaling)

    @ViewBuilder
    private func originalPreview(frame: ImageItem) -> some View {
        GeometryReader { geometry in
            if let nsImage = NSImage(contentsOf: frame.url) {
                let fittedSize = calculateFittedSize(
                    imageSize: nsImage.size,
                    availableSize: geometry.size,
                    margin: 0.9
                )

                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: fittedSize.width, height: fittedSize.height)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                imageLoadError
            }
        }
    }

    /// Calculate fitted size for an image within available space
    private func calculateFittedSize(imageSize: CGSize, availableSize: CGSize, margin: CGFloat) -> CGSize {
        let availableAspect = availableSize.width / availableSize.height
        let imageAspect = imageSize.width / imageSize.height

        if imageAspect > availableAspect {
            return CGSize(
                width: availableSize.width * margin,
                height: availableSize.width * margin / imageAspect
            )
        } else {
            return CGSize(
                width: availableSize.height * margin * imageAspect,
                height: availableSize.height * margin
            )
        }
    }

    // MARK: - Canvas Preview (with Fit/Fill)

    @ViewBuilder
    private func canvasPreview(frame: ImageItem, aspectRatio: CGFloat) -> some View {
        GeometryReader { geometry in
            // Calculate canvas frame size to fit within the preview area
            let previewCanvasSize = calculateCanvasSize(
                aspectRatio: aspectRatio,
                availableSize: geometry.size
            )

            // Calculate scale factor for transform preview
            let actualCanvasSize = settings.resolvedCanvasSize ?? CGSize(width: 100, height: 100)
            let previewScale = previewCanvasSize.width / actualCanvasSize.width

            ZStack {
                // Canvas background (visible in Fit mode as letterbox)
                if settings.scaleMode == .fit {
                    canvasBackground
                        .frame(width: previewCanvasSize.width, height: previewCanvasSize.height)
                }

                // The image with transforms
                if let nsImage = NSImage(contentsOf: frame.url) {
                    canvasImage(
                        nsImage: nsImage,
                        frame: frame,
                        previewCanvasSize: previewCanvasSize,
                        actualCanvasSize: actualCanvasSize,
                        previewScale: previewScale
                    )
                } else {
                    imageLoadError
                }

                // Canvas border indicator
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: previewCanvasSize.width, height: previewCanvasSize.height)
            }
            .frame(width: previewCanvasSize.width, height: previewCanvasSize.height)
            .clipped()
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    /// Calculate filled/fitted image size for canvas
    private func calculateCanvasImageSize(
        imageSize: CGSize,
        canvasSize: CGSize,
        scaleMode: ScaleMode
    ) -> CGSize {
        let imageAspect = imageSize.width / imageSize.height
        let canvasAspect = canvasSize.width / canvasSize.height

        if scaleMode == .fill {
            // Fill: image covers canvas, may extend beyond
            if imageAspect > canvasAspect {
                return CGSize(
                    width: canvasSize.height * imageAspect,
                    height: canvasSize.height
                )
            } else {
                return CGSize(
                    width: canvasSize.width,
                    height: canvasSize.width / imageAspect
                )
            }
        } else {
            // Fit: image fits within canvas, may have letterbox
            if imageAspect > canvasAspect {
                return CGSize(
                    width: canvasSize.width,
                    height: canvasSize.width / imageAspect
                )
            } else {
                return CGSize(
                    width: canvasSize.height * imageAspect,
                    height: canvasSize.height
                )
            }
        }
    }

    /// Image fitted to canvas with transforms applied correctly
    @ViewBuilder
    private func canvasImage(
        nsImage: NSImage,
        frame: ImageItem,
        previewCanvasSize: CGSize,
        actualCanvasSize: CGSize,
        previewScale: CGFloat
    ) -> some View {
        let transform = frame.transform
        let imageSize = nsImage.size
        let canDrag = appState.selectedFrameIndex != nil

        // Calculate fitted image size (how big the image is after aspectRatio fill/fit)
        let fittedSize = calculateCanvasImageSize(
            imageSize: imageSize,
            canvasSize: actualCanvasSize,
            scaleMode: settings.scaleMode
        )

        // Apply user scale on top of the fitted size
        let scaledSize = CGSize(
            width: fittedSize.width * transform.scale / 100,
            height: fittedSize.height * transform.scale / 100
        )

        // Calculate max pan offset (how much extra image extends beyond canvas)
        let maxPanX = max(0, (scaledSize.width - actualCanvasSize.width) / 2)
        let maxPanY = max(0, (scaledSize.height - actualCanvasSize.height) / 2)

        // Clamp offset to valid range
        let clampedOffsetX = max(-maxPanX, min(maxPanX, transform.offsetX))
        let clampedOffsetY = max(-maxPanY, min(maxPanY, transform.offsetY))

        // Scale to preview coordinates
        let previewOffsetX = clampedOffsetX * previewScale
        let previewOffsetY = clampedOffsetY * previewScale
        let previewScaledSize = CGSize(
            width: scaledSize.width * previewScale,
            height: scaledSize.height * previewScale
        )

        Image(nsImage: nsImage)
            .resizable()
            .frame(width: previewScaledSize.width, height: previewScaledSize.height)
            .rotationEffect(.degrees(Double(transform.rotation)))
            .offset(x: previewOffsetX, y: previewOffsetY)
            .frame(width: previewCanvasSize.width, height: previewCanvasSize.height)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                canDrag ? DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragBaseOffset = CGPoint(x: transform.offsetX, y: transform.offsetY)
                        }
                        // Live update with bounds clamping
                        let rawX = dragBaseOffset.x + value.translation.width / previewScale
                        let rawY = dragBaseOffset.y + value.translation.height / previewScale
                        appState.updateSelectedFrameOffset(x: rawX, y: rawY)
                    }
                    .onEnded { _ in
                        isDragging = false
                    } : nil
            )
            .onHover { hovering in
                if canDrag {
                    if hovering {
                        NSCursor.openHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
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
        // Simple placeholder - detailed instructions are in the timeline below
        Image(systemName: "photo.on.rectangle.angled")
            .font(.system(size: 48))
            .foregroundColor(.secondary.opacity(0.5))
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
