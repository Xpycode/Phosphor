//
//  UnifiedToolbar.swift
//  Phosphor
//
//  Created on 2026-02-01
//

import SwiftUI

/// Unified toolbar consolidating playback controls, frame navigation, and zoom controls
/// Layout: [Add Images] ─[Scrubber]─ [▶] [2/35 (40)] ── [Fit All] [🔍 zoom 🔍]
struct UnifiedToolbar: View {
    @ObservedObject var appState: AppState
    let availableWidth: CGFloat
    let onImport: () -> Void

    /// Scrubber value (1-based unmuted frame position)
    @State private var scrubberValue: Double = 1

    /// Track if user is actively scrubbing
    @State private var isScrubbing: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            // Left: Add Images button
            addImagesButton

            Divider()
                .frame(height: 20)

            // Center-left: Frame scrubber
            frameScrubber

            // Center: Play/Pause button
            playPauseButton

            // Center-right: Frame counter
            frameCounter

            Spacer()

            // Right: Zoom controls
            zoomControls
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .underPageBackgroundColor))
        .focusable()
        .onKeyPress(.leftArrow) {
            appState.previousUnmutedFrame()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            appState.nextUnmutedFrame()
            return .handled
        }
        .onKeyPress(.space) {
            appState.togglePlayback()
            return .handled
        }
        .onChange(of: appState.currentUnmutedPosition) { _, newPosition in
            // Sync scrubber with playback (when not actively scrubbing)
            if !isScrubbing, let pos = newPosition {
                scrubberValue = Double(pos)
            }
        }
    }

    // MARK: - Add Images Button

    private var addImagesButton: some View {
        Button(action: onImport) {
            Label("Add Images", systemImage: "plus")
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Frame Scrubber

    private var frameScrubber: some View {
        Group {
            if appState.unmutedFrameCount > 1 {
                HStack(spacing: 4) {
                    Text("Frame")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(
                        value: $scrubberValue,
                        in: 1...Double(appState.unmutedFrameCount),
                        step: 1
                    ) { editing in
                        isScrubbing = editing
                        if !editing {
                            // When done scrubbing, jump to the selected position
                            appState.jumpToUnmutedPosition(Int(scrubberValue))
                        }
                    }
                    .onChange(of: scrubberValue) { _, newValue in
                        if isScrubbing {
                            // Live preview while scrubbing
                            appState.jumpToUnmutedPosition(Int(newValue))
                        }
                    }
                }
                .frame(minWidth: 150, maxWidth: 400)
            } else {
                // Disabled slider for 0-1 frames
                HStack(spacing: 4) {
                    Text("Frame")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: .constant(1), in: 1...1)
                        .disabled(true)
                }
                .frame(minWidth: 150, maxWidth: 400)
            }
        }
    }

    // MARK: - Play/Pause Button

    private var playPauseButton: some View {
        Button {
            appState.togglePlayback()
        } label: {
            Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.bordered)
        .disabled(!appState.canPlay)
        .help(appState.isPlaying ? "Pause (Space)" : "Play (Space)")
    }

    // MARK: - Frame Counter

    /// Format: "current/active (total)"
    /// Example: "2/35 (40)" means frame 2 of 35 active frames, out of 40 total
    private var frameCounter: some View {
        Group {
            if appState.hasFrames {
                HStack(spacing: 2) {
                    // Current unmuted position / total unmuted
                    if let position = appState.currentUnmutedPosition {
                        Text("\(position)/\(appState.unmutedFrameCount)")
                            .font(.system(.body, design: .monospaced))
                    } else {
                        // Current frame is muted
                        Text("-/\(appState.unmutedFrameCount)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    // Total frames (if different from unmuted count)
                    if appState.unmutedFrameCount != appState.frames.count {
                        Text("(\(appState.frames.count))")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minWidth: 80)
            } else {
                Text("0/0")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(minWidth: 80)
            }
        }
    }

    // MARK: - Zoom Controls

    private var zoomControls: some View {
        HStack(spacing: 12) {
            Button("Fit All") {
                appState.fitAllThumbnails(availableWidth: availableWidth)
            }
            .buttonStyle(.bordered)
            .disabled(appState.frames.isEmpty)

            HStack(spacing: 6) {
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Slider(
                    value: $appState.thumbnailWidth,
                    in: AppState.thumbnailWidthRange
                )
                .frame(width: 100)

                Image(systemName: "photo.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack {
        UnifiedToolbar(
            appState: AppState(),
            availableWidth: 800,
            onImport: {}
        )
        Spacer()
    }
}
