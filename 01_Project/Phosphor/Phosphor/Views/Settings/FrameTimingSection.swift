//
//  FrameTimingSection.swift
//  Phosphor
//
//  Created on 2026-02-01
//

import SwiftUI

struct FrameTimingSection: View {
    @ObservedObject var appState: AppState
    @AppStorage("frameTimingSectionExpanded") private var isExpanded: Bool = false

    private var hasSelection: Bool {
        appState.selectedFrameIndex != nil
    }

    private var selectedFrame: ImageItem? {
        appState.selectedFrame
    }

    private var hasCustomDelay: Bool {
        selectedFrame?.customDelay != nil
    }

    var body: some View {
        if hasSelection {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    timingSlider
                    resetButton
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Text("Frame Timing")
                        .font(.headline)
                    if hasCustomDelay {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var timingSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Delay")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(currentDelay)) ms")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { currentDelay },
                    set: { updateDelay($0) }
                ),
                in: 10...2000,
                step: 10
            )

            HStack {
                Text("10 ms")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("2000 ms")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var resetButton: some View {
        if hasCustomDelay {
            Button("Reset to Global") {
                resetToGlobal()
            }
            .buttonStyle(.bordered)
        }
    }

    private var currentDelay: Double {
        selectedFrame?.customDelay ?? appState.exportSettings.frameDelay
    }

    private func updateDelay(_ value: Double) {
        guard let index = appState.selectedFrameIndex else { return }
        appState.frames[index].customDelay = value
    }

    private func resetToGlobal() {
        guard let index = appState.selectedFrameIndex else { return }
        appState.frames[index].customDelay = nil
    }
}

#Preview {
    FrameTimingSection(appState: AppState())
        .frame(width: 280)
        .padding()
}
