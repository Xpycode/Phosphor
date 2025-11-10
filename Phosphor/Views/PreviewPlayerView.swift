//
//  PreviewPlayerView.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI

struct PreviewPlayerView: View {
    @ObservedObject var viewModel: AppViewModel
    private let footerHeight: CGFloat = 60
    @AppStorage("useOrangeAccent") private var useOrangeAccent = false

    private var accentColor: Color {
        useOrangeAccent ? .orange : Color(nsColor: NSColor.controlAccentColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
            // let frame hight stay at 24
                .frame(height: 24)

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
            VStack(spacing: 4) {
                // Scrubber
                if viewModel.totalFrames > 1 {
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
                        .tint(accentColor)

                        Text("\(viewModel.totalFrames)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .leading)
                    }
                    .padding(.top, 4)
                } else if viewModel.totalFrames == 1 {
                    HStack {
                        Spacer()
                        Text("Single frame loaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                // Playback Controls
                HStack(spacing: 12) {
                    Button(action: viewModel.previousFrame) {
                        Image(systemName: "backward")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.totalFrames <= 1)
                    .help("Previous frame")

                    Button(action: viewModel.togglePlayback) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.totalFrames <= 1)
                    .help(viewModel.isPlaying ? "Pause" : "Play")

                    Button(action: viewModel.nextFrame) {
                        Image(systemName: "forward")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.totalFrames <= 1)
                    .help("Next frame")
                }
            }
            .padding(.horizontal, 16)
            .frame(height: footerHeight)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    PreviewPlayerView(viewModel: AppViewModel())
        .frame(width: 600, height: 600)
}
