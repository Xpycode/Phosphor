//
//  QualitySection.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

struct QualitySection: View {
    @ObservedObject var settings: ExportSettings

    var body: some View {
        if settings.format == .gif {
            GroupBox("Quality") {
                VStack(alignment: .leading, spacing: 8) {
                    // Quality slider with percentage display
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Quality")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(settings.quality * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        Slider(
                            value: $settings.quality,
                            in: ExportConstants.qualityRange,
                            step: 0.05
                        )
                    }

                    // Dithering toggle
                    Toggle("Enable Dithering", isOn: $settings.enableDithering)

                    Text("Dithering reduces color banding")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
}

#Preview {
    QualitySection(settings: ExportSettings())
        .frame(width: 300)
        .padding()
}
