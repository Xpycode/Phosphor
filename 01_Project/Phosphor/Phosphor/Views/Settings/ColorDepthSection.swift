//
//  ColorDepthSection.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

struct ColorDepthSection: View {
    @ObservedObject var settings: ExportSettings

    var body: some View {
        if settings.format == .gif {
            GroupBox("Color Depth") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Reduce color depth", isOn: $settings.colorDepthEnabled)

                    if settings.colorDepthEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Levels")
                                    .font(.subheadline)
                                Spacer()
                                Text("~\(settings.approximateColorCount) colors")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }

                            Slider(
                                value: $settings.colorDepthLevels,
                                in: 2...30,
                                step: 1
                            )
                        }

                        Text("Reduces file size by limiting the color palette")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    ColorDepthSection(settings: {
        let s = ExportSettings()
        s.colorDepthEnabled = true
        return s
    }())
    .padding()
    .frame(width: 300)
}
