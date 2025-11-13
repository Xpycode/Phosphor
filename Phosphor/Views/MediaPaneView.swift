//
//  MediaPaneView.swift
//  Phosphor
//
//  Created on 2025-11-13
//  Bottom-left pane showing imported media files
//

import SwiftUI

struct MediaPaneView: View {
    @ObservedObject var project: Project

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MEDIA")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(totalItemCount)")
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(project.mediaBins) { bin in
                        MediaBinRow(bin: bin, project: project)
                    }

                    if project.mediaBins.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No media imported")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var totalItemCount: Int {
        project.mediaBins.reduce(0) { $0 + $1.items.count }
    }
}

#Preview {
    let project = Project()
    let bin = project.defaultMediaBin
    // Add some dummy items for preview
    return MediaPaneView(project: project)
        .frame(width: 250, height: 400)
}
