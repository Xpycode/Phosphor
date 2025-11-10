//
//  PreviewPlayerView.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI

struct PreviewPlayerView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.appAccentColor) private var accentColor
    private let footerHeight: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
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

            // Playback Controls sit directly beneath the preview
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
                    Button(action: { viewModel.previousFrame() }) {
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

                    Button(action: { viewModel.nextFrame() }) {
                        Image(systemName: "forward")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.totalFrames <= 1)
                    .help("Next frame")
                }

                if viewModel.totalFrames > 0, let item = viewModel.currentImageItem {
                    currentFrameTimingControl(for: item)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            footerInfoView
                .padding(.horizontal, 16)
                .frame(height: footerHeight)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

private extension PreviewPlayerView {
    @ViewBuilder
    var footerInfoView: some View {
        if let item = viewModel.currentImageItem {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.fileName)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("\(item.resolutionString) • \(item.fileSizeFormatted)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Frame \(viewModel.currentFrameIndex + 1) of \(max(viewModel.totalFrames, 1))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(item.modificationDate, format: .dateTime
                        .year(.defaultDigits)
                        .month(.abbreviated)
                        .day(.twoDigits))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        } else {
            HStack {
                Text("Select an image to view playback controls and details.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    @ViewBuilder
    func currentFrameTimingControl(for item: ImageItem) -> some View {
        let isCustom = viewModel.customFrameDelays[item.id] != nil && !viewModel.settings.overrideCustomFrameTimings

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Frame Timing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(viewModel.currentFrameDelayValue)) ms")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(isCustom ? .primary : .secondary)
                if viewModel.settings.overrideCustomFrameTimings {
                    Text("Overridden by FPS slider")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else if isCustom {
                    Text("Custom")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("Default")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Slider(
                value: currentFrameDelayBinding,
                in: 10...1000,
                step: 5
            )
            .tint(isCustom ? accentColor : .secondary)
            .disabled(viewModel.settings.overrideCustomFrameTimings)
            .help(viewModel.settings.overrideCustomFrameTimings ? "Disable slider override in Advanced settings to adjust per-frame timing." : "Adjust the duration for this frame.")

            HStack {
                Button("Reset to default") {
                    viewModel.resetCurrentFrameDelay()
                }
                .buttonStyle(.borderless)
                .font(.caption2)
                .disabled(!isCustom || viewModel.settings.overrideCustomFrameTimings)

                Spacer()

                Text("10 ms")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text("1000 ms")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    var currentFrameDelayBinding: Binding<Double> {
        Binding(
            get: { viewModel.currentFrameDelayValue },
            set: { viewModel.setCurrentFrameDelay($0) }
        )
    }
}

#Preview {
    PreviewPlayerView(viewModel: AppViewModel())
        .frame(width: 600, height: 600)
}
