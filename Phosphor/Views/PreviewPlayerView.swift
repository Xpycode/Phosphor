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
                    if viewModel.currentItemIsVideo, let item = viewModel.currentImageItem {
                        VideoPlayerView(
                            url: item.url,
                            currentTime: $viewModel.currentVideoTime,
                            isPlaying: $viewModel.isPlaying,
                            duration: item.duration ?? 0.0
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let image = viewModel.currentImage {
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
                if viewModel.currentItemIsVideo {
                    // Video time scrubber with in/out markers
                    HStack(spacing: 8) {
                        Text(formatTime(viewModel.currentVideoTime))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .trailing)

                        ZStack(alignment: .leading) {
                            // Background slider
                            Slider(
                                value: $viewModel.currentVideoTime,
                                in: 0...max(0, viewModel.currentVideoDuration)
                            )
                            .tint(accentColor)

                            // In/Out point markers
                            GeometryReader { geo in
                                let duration = max(0.001, viewModel.currentVideoDuration)

                                // In point marker (green)
                                if let inPt = viewModel.inPoint {
                                    let position = (inPt / duration) * geo.size.width
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: 3, height: 20)
                                        .offset(x: position - 1.5, y: -2)
                                }

                                // Out point marker (red)
                                if let outPt = viewModel.outPoint {
                                    let position = (outPt / duration) * geo.size.width
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: 3, height: 20)
                                        .offset(x: position - 1.5, y: -2)
                                }

                                // Selected range highlight
                                if let inPt = viewModel.inPoint, let outPt = viewModel.outPoint {
                                    let startPos = (inPt / duration) * geo.size.width
                                    let endPos = (outPt / duration) * geo.size.width
                                    Rectangle()
                                        .fill(Color.accentColor.opacity(0.2))
                                        .frame(width: endPos - startPos, height: 8)
                                        .offset(x: startPos, y: 4)
                                }
                            }
                        }

                        Text(formatTime(viewModel.currentVideoDuration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .leading)
                    }
                    .padding(.top, 4)
                } else if viewModel.totalFrames > 1 {
                    // Frame scrubber for images
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
                    if !viewModel.currentItemIsVideo {
                        Button(action: viewModel.previousFrame) {
                            Image(systemName: "backward")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.totalFrames <= 1)
                        .help("Previous frame")
                    }

                    Button(action: viewModel.togglePlayback) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.currentItemIsVideo && viewModel.totalFrames <= 1)
                    .help(viewModel.isPlaying ? "Pause" : "Play")

                    if !viewModel.currentItemIsVideo {
                        Button(action: viewModel.nextFrame) {
                            Image(systemName: "forward")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.totalFrames <= 1)
                        .help("Next frame")
                    }
                }

                // In/Out Point Controls (Video only)
                if viewModel.currentItemIsVideo {
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.vertical, 4)

                        HStack(spacing: 12) {
                            // In Point controls
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Button(action: viewModel.setInPoint) {
                                        Label("Set In", systemImage: "arrowtriangle.right.fill")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(.green)

                                    if viewModel.inPoint != nil {
                                        Button(action: viewModel.clearInPoint) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(.secondary)
                                        .help("Clear in point")
                                    }
                                }

                                if let inPt = viewModel.inPoint {
                                    Button(action: viewModel.seekToInPoint) {
                                        Text("In: \(formatTime(inPt))")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Spacer()

                            // Out Point controls
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 6) {
                                    if viewModel.outPoint != nil {
                                        Button(action: viewModel.clearOutPoint) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(.secondary)
                                        .help("Clear out point")
                                    }

                                    Button(action: viewModel.setOutPoint) {
                                        Label("Set Out", systemImage: "arrowtriangle.left.fill")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(.red)
                                }

                                if let outPt = viewModel.outPoint {
                                    Button(action: viewModel.seekToOutPoint) {
                                        Text("Out: \(formatTime(outPt))")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Clear all button
                        if viewModel.inPoint != nil || viewModel.outPoint != nil {
                            Button(action: viewModel.clearInOutPoints) {
                                Label("Clear All Points", systemImage: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
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
    func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "00:00" }
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

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
}

#Preview {
    PreviewPlayerView(viewModel: AppViewModel())
        .frame(width: 600, height: 600)
}
