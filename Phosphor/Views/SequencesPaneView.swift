//
//  SequencesPaneView.swift
//  Phosphor
//
//  Created on 2025-11-13
//  Top-left pane showing all sequences in the project
//

import SwiftUI

struct SequencesPaneView: View {
    @ObservedObject var project: Project

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SEQUENCES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(sequenceCount)")
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
                    ForEach(project.sequenceContainers) { container in
                        SequenceContainerRow(container: container, project: project)
                    }

                    if project.sequenceContainers.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "film")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No sequences")
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

    private var sequenceCount: Int {
        project.sequenceContainers.reduce(0) { $0 + $1.sequences.count }
    }
}

#Preview {
    let project = Project()
    let _ = project.createSequence(name: "Instagram Square", width: 1080, height: 1080, frameRate: 10, fitMode: .fill)
    let _ = project.createSequence(name: "Story", width: 1080, height: 1920, frameRate: 15, fitMode: .fill)
    return SequencesPaneView(project: project)
        .frame(width: 250, height: 400)
}
