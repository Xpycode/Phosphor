//
//  PreviewPlayerView.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI

struct PreviewPlayerView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var lastFiniteLoopCount: Int
    @State private var loopCountText: String
    private let footerHeight: CGFloat = 60
    @AppStorage("useOrangeAccent") private var useOrangeAccent = false
    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        useOrangeAccent ? .orange : Color(nsColor: NSColor.controlAccentColor)
    }

    init(viewModel: AppViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        let initialLoop = viewModel.settings.loopCount == 0 ? 1 : viewModel.settings.loopCount
        let finiteLoop = max(1, initialLoop)
        self._lastFiniteLoopCount = State(initialValue: finiteLoop)
        self._loopCountText = State(initialValue: String(finiteLoop))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
            // let frame height stay at 24
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

                if viewModel.totalFrames > 0 {
                    globalPlaybackControls
                        .padding(.top, 8)
                }

                if viewModel.totalFrames > 0, let item = viewModel.currentImageItem {
                    individualFrameTimingControl(for: item)
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
        .onChange(of: viewModel.settings.loopCount) { _, newValue in
            if newValue != 0 {
                let clamped = max(1, min(newValue, 100))
                lastFiniteLoopCount = clamped
                loopCountText = String(clamped)
            }
        }
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
    var globalPlaybackControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Frame Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(viewModel.settings.frameRate)) FPS")
                        .font(.caption.monospacedDigit())
                }

                Slider(
                    value: steppedBinding(
                        $viewModel.settings.frameRate,
                        step: 1,
                        range: 1...60
                    ),
                    in: 1...60
                )
                .tint(accentColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Playback Delay")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(String(format: "%.0f", viewModel.settings.frameDelay)) ms / \(String(format: "%.1f", viewModel.settings.frameDelay / 10.0)) cs")
                        .font(.caption.monospacedDigit())
                }

                Slider(
                    value: steppedBinding(
                        $viewModel.settings.frameDelay,
                        step: 1,
                        range: (1000.0 / 60.0)...1000.0
                    ),
                    in: (1000.0 / 60.0)...1000.0
                )
                .tint(accentColor)

                if viewModel.hasCustomFrameDelays {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom per-frame timings exist. Override them with the slider or adjust frames individually below.")
                            .font(.caption2)
                            .foregroundColor(viewModel.settings.overrideCustomFrameTimings ? .secondary : .orange)

                        Toggle("Apply slider to custom frames", isOn: $viewModel.settings.overrideCustomFrameTimings)
                            .font(.caption2)
                            .tint(accentColor)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    Text("Loop Count")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("Infinite")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Toggle("", isOn: Binding(
                        get: { viewModel.settings.loopCount == 0 },
                        set: { isInfinite in
                            if isInfinite {
                                if viewModel.settings.loopCount != 0 {
                                    lastFiniteLoopCount = max(1, viewModel.settings.loopCount)
                                    loopCountText = String(lastFiniteLoopCount)
                                }
                                viewModel.settings.loopCount = 0
                            } else {
                                viewModel.settings.loopCount = lastFiniteLoopCount
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: accentColor))

                    TextField("", text: loopCountTextBinding)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 48)
                        .disabled(viewModel.settings.loopCount == 0)
                }

                Text("Loop count applies at export time; preview always loops continuously.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(frameTimingPanelColor)
        )
    }

    func individualFrameTimingControl(for item: ImageItem) -> some View {
        let isCustom = viewModel.customFrameDelays[item.id] != nil && !viewModel.settings.overrideCustomFrameTimings

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Individual Frame Timing — \(item.fileName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Text("\(Int(viewModel.currentFrameDelayValue)) ms")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(isCustom ? .primary : .secondary)
                timingStatusLabel(isCustom: isCustom)
                Text("|")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Button("Reset to default") {
                    viewModel.resetCurrentFrameDelay()
                }
                .buttonStyle(.borderless)
                .font(.caption2)
                .disabled(!isCustom || viewModel.settings.overrideCustomFrameTimings)
            }

            Slider(
                value: currentFrameDelayBinding,
                in: 10...1000
            )
            .tint(isCustom ? accentColor : .secondary)
            .disabled(viewModel.settings.overrideCustomFrameTimings)
            .help(viewModel.settings.overrideCustomFrameTimings ? "Disable slider override in Advanced settings to adjust per-frame timing." : "Adjust the duration for this frame.")

            HStack {
                Text("10 ms")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("1000 ms")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(frameTimingPanelColor)
        )
    }

    func timingStatusLabel(isCustom: Bool) -> some View {
        Group {
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
    }

    var currentFrameDelayBinding: Binding<Double> {
        Binding(
            get: { viewModel.currentFrameDelayValue },
            set: { newValue in
                let clamped = min(max(newValue, 10), 1000)
                let snapped = (clamped / 5).rounded() * 5
                viewModel.setCurrentFrameDelay(snapped)
            }
        )
    }

    private var loopCountTextBinding: Binding<String> {
        Binding(
            get: { loopCountText },
            set: { newValue in
                let filtered = newValue.filter(\.isNumber)
                loopCountText = filtered

                guard let value = Int(filtered) else { return }

                let clamped = max(1, min(value, 100))
                lastFiniteLoopCount = clamped

                if viewModel.settings.loopCount != 0 {
                    viewModel.settings.loopCount = clamped
                }
            }
        )
    }

    private func steppedBinding(
        _ binding: Binding<Double>,
        step: Double,
        range: ClosedRange<Double>
    ) -> Binding<Double> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                let snappedValue = (newValue / step).rounded() * step
                binding.wrappedValue = min(max(snappedValue, range.lowerBound), range.upperBound)
            }
        )
    }

    private var frameTimingPanelColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.04)
        } else {
            return Color.black.opacity(0.03)
        }
    }
}

#Preview {
    PreviewPlayerView(viewModel: AppViewModel())
        .frame(width: 600, height: 600)
}
