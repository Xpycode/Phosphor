//
//  ExportFailedView.swift
//  Phosphor
//
//  Error screen when export fails
//

import SwiftUI

struct ExportFailedView: View {
    let error: String
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)

                Text("Export Failed")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Divider()

            Button("Done") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .padding()
        }
    }
}

#Preview {
    ExportFailedView(
        error: "File could not be written to the selected location.",
        onDone: {}
    )
    .frame(width: 400, height: 300)
}
