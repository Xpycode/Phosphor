//
//  TimingSection.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

struct TimingSection: View {
    @ObservedObject var settings: ExportSettings

    var body: some View {
        GroupBox("Timing") {
            VStack(alignment: .leading, spacing: 8) {
                // Frame Rate Slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Frame Rate")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(settings.frameRate)) fps")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                    Slider(
                        value: $settings.frameRate,
                        in: ExportConstants.frameRateRange,
                        step: 1
                    )
                    .onChange(of: settings.frameRate) { _, _ in
                        settings.updateDelayFromFrameRate()
                    }
                }

                // Loop Count Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Loop Count")
                        .font(.subheadline)

                    Picker("", selection: $settings.loopCount) {
                        Text("Forever").tag(0)

                        ForEach(1...10, id: \.self) { count in
                            Text("\(count) \(count == 1 ? "time" : "times")").tag(count)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            }
            .padding(.top, 4)
        }
    }
}

#Preview {
    TimingSection(settings: ExportSettings())
        .padding()
        .frame(width: 300)
}
