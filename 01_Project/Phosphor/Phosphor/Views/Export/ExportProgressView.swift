//
//  ExportProgressView.swift
//  Phosphor
//
//  Progress indicator during export
//

import SwiftUI

struct ExportProgressView: View {
    let progress: Double
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 300)

                Text("Exporting... \(Int(progress * 100))%")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Divider()

            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding()
        }
    }
}

#Preview {
    ExportProgressView(progress: 0.65, onCancel: {})
        .frame(width: 400, height: 300)
}
