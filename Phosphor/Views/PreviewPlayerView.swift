//
//  PreviewPlayerView.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI

struct PreviewPlayerView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Preview")
                    .font(.headline)
                Spacer()
                if viewModel.totalFrames > 0 {
                    Text("Frame \(viewModel.currentFrameIndex + 1) of \(viewModel.totalFrames)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            // Preview Area
            GeometryReader { geometry in
                ZStack {
                    if let image = viewModel.currentImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo")
                                .font(.system(size: 64))
                                .foregroundStyle(.tertiary)

                            Text("No Preview")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .background(Color(NSColor.textBackgroundColor))

            Divider()

            // Controls
            VStack(spacing: 12) {
                // Scrubber
                if viewModel.totalFrames > 0 {
                    HStack(spacing: 8) {
                        Text("\(viewModel.currentFrameIndex + 1)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)

                        Slider(
                            value: Binding(
                                get: { Double(viewModel.currentFrameIndex) },
                                set: { viewModel.seekToFrame(Int($0)) }
                            ),
                            in: 0...Double(max(0, viewModel.totalFrames - 1)),
                            step: 1
                        )
                        .disabled(viewModel.totalFrames <= 1)

                        Text("\(viewModel.totalFrames)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .leading)
                    }
                }

                // Playback Controls
                HStack(spacing: 16) {
                    Button(action: viewModel.previousFrame) {
                        Image(systemName: "backward.frame")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.totalFrames <= 1)
                    .help("Previous frame")

                    Button(action: viewModel.togglePlayback) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.totalFrames <= 1)
                    .help(viewModel.isPlaying ? "Pause" : "Play")

                    Button(action: viewModel.nextFrame) {
                        Image(systemName: "forward.frame")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.totalFrames <= 1)
                    .help("Next frame")
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    PreviewPlayerView(viewModel: AppViewModel())
        .frame(width: 600, height: 600)
}
