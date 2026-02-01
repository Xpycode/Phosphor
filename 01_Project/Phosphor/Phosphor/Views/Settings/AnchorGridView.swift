//
//  AnchorGridView.swift
//  Phosphor
//
//  Created on 2026-01-31
//

import SwiftUI

/// 3x3 grid of position preset buttons
struct AnchorGridView: View {
    @ObservedObject var appState: AppState

    /// Current anchor based on current offset and image/canvas sizes
    private var currentAnchor: PositionAnchor? {
        guard let frame = appState.selectedFrame,
              let image = NSImage(contentsOf: frame.url) else {
            return nil
        }

        let canvasSize = appState.exportSettings.effectiveCanvasSize
        let imageSize = image.size
        let scale = frame.transform.scale
        let offsetX = frame.transform.offsetX
        let offsetY = frame.transform.offsetY

        return PositionAnchor.detect(
            offsetX: offsetX,
            offsetY: offsetY,
            imageSize: imageSize,
            canvasSize: canvasSize,
            scale: scale
        )
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                anchorButton(.topLeft)
                anchorButton(.topCenter)
                anchorButton(.topRight)
            }

            HStack(spacing: 6) {
                anchorButton(.middleLeft)
                anchorButton(.center)
                anchorButton(.middleRight)
            }

            HStack(spacing: 6) {
                anchorButton(.bottomLeft)
                anchorButton(.bottomCenter)
                anchorButton(.bottomRight)
            }
        }
    }

    private func anchorButton(_ anchor: PositionAnchor) -> some View {
        Button(action: { applyAnchor(anchor) }) {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(currentAnchor == anchor ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.1))

                Circle()
                    .fill(currentAnchor == anchor ? Color.accentColor : Color.primary)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 28, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(currentAnchor == anchor ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(anchor.description)
    }

    private func applyAnchor(_ anchor: PositionAnchor) {
        guard let frame = appState.selectedFrame,
              let image = NSImage(contentsOf: frame.url) else {
            return
        }

        let canvasSize = appState.exportSettings.effectiveCanvasSize
        let imageSize = image.size
        let scale = frame.transform.scale

        appState.applyAnchorPreset(
            anchor,
            imageSize: imageSize,
            canvasSize: canvasSize,
            scale: scale
        )
    }
}

#Preview {
    AnchorGridView(appState: {
        let state = AppState()
        return state
    }())
    .padding()
}
