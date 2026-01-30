//
//  TimelineToolbar.swift
//  Phosphor
//
//  Created on 2026-01-30
//

import SwiftUI

struct TimelineToolbar: View {
    @ObservedObject var appState: AppState
    let availableWidth: CGFloat
    let onImport: () -> Void

    var body: some View {
        HStack {
            // Left: Import button
            Button(action: onImport) {
                Label("Import", systemImage: "plus")
            }
            .buttonStyle(.bordered)

            Spacer()

            // Right: Fit All + Zoom slider
            HStack(spacing: 12) {
                Button("Fit All") {
                    appState.fitAllThumbnails(availableWidth: availableWidth)
                }
                .buttonStyle(.bordered)
                .disabled(appState.frames.isEmpty)

                HStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(
                        value: $appState.thumbnailWidth,
                        in: AppState.thumbnailWidthRange
                    )
                    .frame(width: 100)

                    Image(systemName: "photo.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview {
    TimelineToolbar(
        appState: AppState(),
        availableWidth: 800,
        onImport: {}
    )
}
