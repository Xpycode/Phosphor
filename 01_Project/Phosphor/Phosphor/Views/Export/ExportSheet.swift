//
//  ExportSheet.swift
//  Phosphor
//
//  Main sheet orchestrator for export workflow
//

import SwiftUI

struct ExportSheet: View {
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool
    @State private var exportState: ExportState = .configuring

    var body: some View {
        VStack(spacing: 0) {
            switch exportState {
            case .configuring:
                ExportSettingsView(appState: appState, onExport: startExport)
            case .exporting(let progress):
                ExportProgressView(progress: progress, onCancel: cancelExport)
            case .completed(let url):
                ExportCompleteView(url: url, onShowInFinder: { showInFinder(url) }, onDone: dismiss)
            case .failed(let error):
                ExportFailedView(error: error, onDone: dismiss)
            case .idle:
                EmptyView()
            }
        }
        .frame(width: 400, height: 380)
        .interactiveDismissDisabled(exportState.isExporting)
    }

    private func startExport() {
        let panel = NSSavePanel()
        panel.title = "Export \(appState.exportSettings.format.rawValue)"
        panel.allowedContentTypes = [appState.exportSettings.format.utType]
        panel.nameFieldStringValue = "animation.\(appState.exportSettings.format.fileExtension)"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            Task { @MainActor in
                await executeExport(to: url)
            }
        }
    }

    private func executeExport(to url: URL) async {
        exportState = .exporting(progress: 0.0)

        do {
            try await appState.executeExportWithProgress(to: url, frames: appState.unmutedFrames) { progress in
                exportState = .exporting(progress: progress)
            }
            exportState = .completed(url: url)
        } catch {
            exportState = .failed(error: error.localizedDescription)
        }
    }

    private func cancelExport() {
        exportState = .configuring
    }

    private func showInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }

    private func dismiss() {
        isPresented = false
    }
}
