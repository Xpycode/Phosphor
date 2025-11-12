//
//  ProjectSidebarView.swift
//  Phosphor
//
//  Created on 2025-11-12
//

import SwiftUI

struct ProjectSidebarView: View {
    @ObservedObject var project: Project
    @State private var selectedMediaBinID: UUID?
    @State private var selectedSequenceID: UUID?

    var body: some View {
        List(selection: $selectedSequenceID) {
            // MEDIA Section
            Section(header: Text("MEDIA").font(.caption).fontWeight(.semibold)) {
                ForEach(project.mediaBins) { bin in
                    MediaBinRow(bin: bin, project: project)
                }
            }

            // SEQUENCES Section
            Section(header: Text("SEQUENCES").font(.caption).fontWeight(.semibold)) {
                ForEach(project.sequenceContainers) { container in
                    SequenceContainerRow(container: container, project: project)
                }

                if project.sequenceContainers.isEmpty {
                    Text("No sequences")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .italic()
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 200, idealWidth: 250)
        .onChange(of: selectedSequenceID) { _, newValue in
            project.activeSequenceID = newValue
        }
    }
}

// MARK: - Media Bin Row

struct MediaBinRow: View {
    @ObservedObject var bin: MediaBin
    @ObservedObject var project: Project

    var body: some View {
        DisclosureGroup(isExpanded: $bin.isExpanded) {
            ForEach(bin.items) { item in
                MediaItemRow(item: item)
                    .onDrag {
                        NSItemProvider(object: item.id.uuidString as NSString)
                    }
            }

            if bin.items.isEmpty {
                Text("Empty")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .italic()
            }
        } label: {
            HStack {
                Image(systemName: "folder")
                Text(bin.name)
                Spacer()
                Text("\(bin.items.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MediaItemRow: View {
    let item: ImageItem

    var body: some View {
        HStack(spacing: 8) {
            if let thumbnail = item.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 30)
                    .clipped()
                    .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(.caption)
                    .lineLimit(1)
                Text(item.resolutionString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Sequence Container Row

struct SequenceContainerRow: View {
    @ObservedObject var container: SequenceContainer
    @ObservedObject var project: Project

    var body: some View {
        if container.isBin {
            // Bin (folder) with multiple sequences
            DisclosureGroup(isExpanded: $container.isExpanded) {
                ForEach(container.sequences) { sequence in
                    SequenceRow(sequence: sequence, project: project)
                }
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text(container.name)
                    Spacer()
                    Text("\(container.sequences.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } else {
            // Loose sequence (not in bin)
            ForEach(container.sequences) { sequence in
                SequenceRow(sequence: sequence, project: project)
            }
        }
    }
}

struct SequenceRow: View {
    @ObservedObject var sequence: Sequence
    @ObservedObject var project: Project

    var isActive: Bool {
        project.activeSequenceID == sequence.id
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "film")
                .foregroundColor(isActive ? .accentColor : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(sequence.name)
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
                    .lineLimit(1)

                Text("\(sequence.width)×\(sequence.height) • \(Int(sequence.frameRate)) fps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(sequence.enabledFrames.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            project.activeSequenceID = sequence.id
        }
    }
}

#Preview {
    let project = Project()
    let _ = project.defaultMediaBin
    let _ = project.createSequence(name: "Test Sequence", width: 1920, height: 1080, frameRate: 24, fitMode: .fill)
    return ProjectSidebarView(project: project)
        .frame(width: 250, height: 600)
}
