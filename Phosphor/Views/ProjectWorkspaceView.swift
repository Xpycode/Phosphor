//
//  ProjectWorkspaceView.swift
//  Phosphor
//
//  Created on 2025-11-12
//  Refactored 2025-11-13 for 6-pane layout with progressive disclosure
//

import SwiftUI
import UniformTypeIdentifiers

struct ProjectWorkspaceView: View {
    @StateObject private var project = Project()
    @StateObject private var workspaceState = WorkspaceState()
    @StateObject private var importManager = ImportManager()
    @State private var showNewSequenceSheet = false
    @State private var selectedFrameIDs = Set<UUID>()

    var body: some View {
        ZStack {
            // 6-Pane Layout (3x2 grid)
            HSplitView {
                // LEFT COLUMN
                if workspaceState.showSequences || workspaceState.showMedia {
                    VSplitView {
                        // Top-Left: SEQUENCES
                        if workspaceState.showSequences {
                            SequencesPaneView(project: project)
                                .frame(minHeight: 150, idealHeight: 250)
                        }

                        // Bottom-Left: MEDIA
                        if workspaceState.showMedia {
                            MediaPaneView(project: project)
                                .frame(minHeight: 150, idealHeight: 300)
                        }
                    }
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 350)
                }

                // CENTER COLUMN (always visible)
                VSplitView {
                    // Top-Center: VIEWER (with FPS controls below)
                    VStack(spacing: 0) {
                        PreviewMonitorView(project: project, workspaceState: workspaceState)
                            .frame(minHeight: 300, idealHeight: 500)
                    }

                    // Bottom-Center: TIMELINE + FRAME SETTINGS
                    VStack(spacing: 0) {
                        TimelineView(project: project, selectedFrameIDs: $selectedFrameIDs)
                            .frame(minHeight: 100, idealHeight: 150)

                        Divider()

                        FrameSettingsView(project: project, selectedFrameIDs: selectedFrameIDs)
                            .frame(minHeight: 100, idealHeight: 150)
                    }
                }

                // RIGHT COLUMN
                if workspaceState.showSequenceSettings || workspaceState.showExport {
                    VSplitView {
                        // Top-Right: SEQUENCE SETTINGS
                        if workspaceState.showSequenceSettings {
                            SequenceSettingsPaneView(project: project)
                                .frame(minHeight: 150, idealHeight: 300)
                        }

                        // Bottom-Right: EXPORT
                        if workspaceState.showExport {
                            ExportPanelView(project: project)
                                .frame(minHeight: 150, idealHeight: 300)
                        }
                    }
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
                }
            }

            // Import progress overlay
            if importManager.isImporting {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView(value: importManager.progress) {
                            Text("Importing...")
                                .font(.headline)
                        }
                        .frame(width: 300)
                        .progressViewStyle(.linear)
                        .tint(.orange)

                        Text("\(Int(importManager.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Cancel") {
                            // TODO: Cancel import
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(24)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(radius: 20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .accentColor(.orange)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { importMedia() }) {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

                Button(action: { showNewSequenceSheet = true }) {
                    Label("New Sequence", systemImage: "plus.rectangle.on.folder")
                }

                Divider()

                Button(action: { exportSequence() }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(project.activeSequence == nil)
            }
        }
        .sheet(isPresented: $showNewSequenceSheet) {
            NewSequenceSheet(project: project, isPresented: $showNewSequenceSheet, workspaceState: workspaceState)
        }
        .onAppear {
            // Auto-reveal sequences pane if there are existing sequences
            if !project.sequenceContainers.isEmpty {
                workspaceState.revealSequencesPane()
            }
        }
    }

    // MARK: - Import

    private func importMedia() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = ImageItem.supportedContentTypes

        if panel.runModal() == .OK {
            // Reveal media pane when importing
            workspaceState.revealMediaPane()
            handleImport(urls: panel.urls)
        }
    }

    private func handleImport(urls: [URL]) {
        // Check if any directories
        var directories: [URL] = []
        var files: [URL] = []

        for url in urls {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    directories.append(url)
                } else {
                    files.append(url)
                }
            }
        }

        // Handle directories (create bins)
        for directory in directories {
            let folderName = directory.lastPathComponent
            let bin = project.createMediaBin(name: folderName)

            importManager.isImporting = true
            importManager.progress = 0.0

            Task.detached(priority: .userInitiated) {
                // Find all image files in directory
                if let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) {
                    var allFiles: [URL] = []
                    while let fileURL = enumerator.nextObject() as? URL {
                        if ImageItem.isSupported(url: fileURL) {
                            allFiles.append(fileURL)
                        }
                    }

                    let total = allFiles.count
                    var items: [ImageItem] = []
                    for (index, fileURL) in allFiles.enumerated() {
                        autoreleasepool {
                            if let item = ImageItem.from(url: fileURL) {
                                items.append(item)
                            }
                        }

                        await MainActor.run {
                            importManager.progress = Double(index + 1) / Double(total)
                        }
                    }

                    let loadedItems = items
                    await MainActor.run {
                        bin.addItems(loadedItems)
                    }
                }

                await MainActor.run {
                    importManager.isImporting = false
                    importManager.progress = 0.0
                }
            }
        }

        // Handle loose files
        if !files.isEmpty {
            // Ask which bin
            showBinSelectionAndImport(files: files)
        }
    }

    private func showBinSelectionAndImport(files: [URL]) {
        // For now, just add to default bin
        // TODO: Show modal to select bin or create new one
        let bin = project.defaultMediaBin

        importManager.isImporting = true
        importManager.progress = 0.0

        Task.detached(priority: .userInitiated) {
            var items: [ImageItem] = []
            let total = files.count

            for (index, url) in files.enumerated() {
                autoreleasepool {
                    if let item = ImageItem.from(url: url) {
                        items.append(item)
                    }
                }

                await MainActor.run {
                    importManager.progress = Double(index + 1) / Double(total)
                }
            }

            let loadedItems = items
            await MainActor.run {
                bin.addItems(loadedItems)
                importManager.isImporting = false
                importManager.progress = 0.0
            }
        }
    }

    // MARK: - Export

    private func exportSequence() {
        guard let sequence = project.activeSequence else { return }

        // Reveal export pane when exporting
        workspaceState.revealExportPane()

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(sequence.name).gif"
        panel.allowedContentTypes = [.gif]

        if panel.runModal() == .OK, let url = panel.url {
            // TODO: Wire up to actual exporter
            print("Would export sequence '\(sequence.name)' to \(url)")
        }
    }
}

// MARK: - Preview Monitor

struct PreviewMonitorView: View {
    @ObservedObject var project: Project
    @ObservedObject var workspaceState: WorkspaceState
    @State private var currentFrameIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var playbackTimer: Timer?

    private var sequence: Sequence? {
        project.activeSequence
    }

    private var currentFrame: SequenceFrame? {
        guard let seq = sequence, currentFrameIndex < seq.frames.count else { return nil }
        return seq.frames[currentFrameIndex]
    }

    private var currentImage: NSImage? {
        guard let frame = currentFrame,
              let item = project.image(for: frame.imageID) else { return nil }
        return NSImage.loadedNormalizingOrientation(from: item.url)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("VIEWER")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if let seq = sequence {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(seq.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Preview area
            GeometryReader { geometry in
                ZStack {
                    if let image = currentImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "film")
                                .font(.system(size: 64))
                                .foregroundStyle(.tertiary)
                            Text("No Preview")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(nsColor: .textBackgroundColor))
            }

            Divider()

            // Playback controls
            if let seq = sequence, seq.frames.count > 1 {
                VStack(spacing: 8) {
                    // Scrubber
                    HStack(spacing: 8) {
                        Text("\(currentFrameIndex + 1)")
                            .font(.caption.monospacedDigit())
                            .frame(width: 30, alignment: .trailing)

                        Slider(
                            value: Binding(
                                get: { Double(currentFrameIndex) },
                                set: { currentFrameIndex = Int($0) }
                            ),
                            in: 0...Double(seq.frames.count - 1),
                            step: 1
                        )

                        Text("\(seq.frames.count)")
                            .font(.caption.monospacedDigit())
                            .frame(width: 30, alignment: .leading)
                    }

                    // Buttons
                    HStack(spacing: 12) {
                        Button(action: previousFrame) {
                            Image(systemName: "backward")
                        }
                        .buttonStyle(.plain)

                        Button(action: togglePlayback) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)

                        Button(action: nextFrame) {
                            Image(systemName: "forward")
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    // FPS / Delay Controls
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Frame Rate")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                TextField("FPS", value: Binding(
                                    get: { seq.frameRate },
                                    set: { project.activeSequence?.frameRate = $0 }
                                ), format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                Text("fps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Frame Delay")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Text("\(Int(seq.frameDelay))")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .frame(width: 40, alignment: .trailing)
                                Text("ms")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button(action: {
                            workspaceState.toggleSequenceSettings()
                        }) {
                            Label("More Settings", systemImage: "gearshape")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .onDisappear {
            stopPlayback()
        }
    }

    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard let seq = sequence, !seq.frames.isEmpty else { return }
        isPlaying = true
        scheduleNextFrame()
    }

    private func stopPlayback() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func scheduleNextFrame() {
        guard let seq = sequence, isPlaying else { return }
        let delay = currentFrame?.customDelay ?? seq.frameDelay
        let interval = max(0.01, delay / 1000.0)

        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            nextFrame()
            scheduleNextFrame()
        }
    }

    private func nextFrame() {
        guard let seq = sequence else { return }
        currentFrameIndex = (currentFrameIndex + 1) % seq.frames.count
    }

    private func previousFrame() {
        guard let seq = sequence else { return }
        currentFrameIndex = (currentFrameIndex - 1 + seq.frames.count) % seq.frames.count
    }
}

// MARK: - Export Panel

struct ExportPanelView: View {
    @ObservedObject var project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Export")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let seq = project.activeSequence {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sequence")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(seq.name)
                                .font(.body)

                            Divider()

                            Text("Canvas")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(seq.width) × \(seq.height)")
                                .font(.body)

                            Divider()

                            Text("Frames")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(seq.enabledFrames.count) frames")
                                .font(.body)

                            Divider()

                            Text("Export settings coming soon...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding()
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("Select a sequence to export")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Import Manager

class ImportManager: ObservableObject {
    @Published var isImporting = false
    @Published var progress: Double = 0.0
}

#Preview {
    ProjectWorkspaceView()
}
