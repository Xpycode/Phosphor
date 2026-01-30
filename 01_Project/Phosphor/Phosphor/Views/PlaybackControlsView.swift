//
//  PlaybackControlsView.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

/// Playback controls: play/pause, frame counter, and frame rate slider
struct PlaybackControlsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 16) {
            // Play/Pause button
            playPauseButton

            // Frame counter
            frameCounter

            Spacer()

            // Frame rate control
            frameRateControl
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
    }

    private var playPauseButton: some View {
        Button {
            appState.togglePlayback()
        } label: {
            Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.bordered)
        .disabled(!appState.hasFrames)
        .keyboardShortcut(.space, modifiers: [])
        .help(appState.isPlaying ? "Pause (Space)" : "Play (Space)")
    }

    private var frameCounter: some View {
        Group {
            if appState.hasFrames {
                Text("\(appState.currentPreviewIndex + 1) / \(appState.frames.count)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            } else {
                Text("0 / 0")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 60)
    }

    private var frameRateControl: some View {
        HStack(spacing: 8) {
            Text("FPS")
                .font(.caption)
                .foregroundColor(.secondary)

            Slider(
                value: $appState.exportSettings.frameRate,
                in: ExportConstants.frameRateRange,
                step: 1
            )
            .frame(width: 100)
            .onChange(of: appState.exportSettings.frameRate) { _, _ in
                restartPlaybackIfNeeded()
            }

            Text("\(Int(appState.exportSettings.frameRate))")
                .font(.system(.caption, design: .monospaced))
                .frame(width: 24, alignment: .trailing)
        }
    }

    /// Restart playback timer when frame rate changes during playback
    private func restartPlaybackIfNeeded() {
        if appState.isPlaying {
            appState.isPlaying = false
            appState.isPlaying = true
        }
    }
}

#Preview {
    PlaybackControlsView(appState: AppState())
        .frame(width: 400)
}
