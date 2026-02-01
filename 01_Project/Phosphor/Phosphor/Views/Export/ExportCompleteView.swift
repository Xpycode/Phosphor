//
//  ExportCompleteView.swift
//  Phosphor
//
//  Success screen after export completion
//

import SwiftUI

struct ExportCompleteView: View {
    let url: URL
    let onShowInFinder: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Export Complete")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(url.lastPathComponent)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Divider()

            HStack(spacing: 12) {
                Button("Show in Finder") {
                    onShowInFinder()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Done") {
                    onDone()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }
}

#Preview {
    ExportCompleteView(
        url: URL(fileURLWithPath: "/Users/test/animation.gif"),
        onShowInFinder: {},
        onDone: {}
    )
    .frame(width: 400, height: 300)
}
