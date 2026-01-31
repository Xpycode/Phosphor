//
//  FormatSelectionSection.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

struct FormatSelectionSection: View {
    @ObservedObject var settings: ExportSettings

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Picker("", selection: $settings.format) {
                    ForEach(ExportFormat.implementedFormats, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text("Output: .\(settings.format.fileExtension)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        } label: {
            Text("Export Format")
                .font(.headline)
        }
    }
}

#Preview {
    FormatSelectionSection(settings: ExportSettings())
        .frame(width: 300)
        .padding()
}
