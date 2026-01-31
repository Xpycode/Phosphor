//
//  PhosphorApp.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI

// MARK: - Focused Values for Menu Commands

struct ImportActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct ExportActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct CanExportKey: FocusedValueKey {
    typealias Value = Bool
}

extension FocusedValues {
    var importAction: (() -> Void)? {
        get { self[ImportActionKey.self] }
        set { self[ImportActionKey.self] = newValue }
    }

    var exportAction: (() -> Void)? {
        get { self[ExportActionKey.self] }
        set { self[ExportActionKey.self] = newValue }
    }

    var canExport: Bool? {
        get { self[CanExportKey.self] }
        set { self[CanExportKey.self] = newValue }
    }
}

@main
struct PhosphorApp: App {
    @AppStorage("prefersLightMode") private var prefersLightMode = false
    @AppStorage("useOrangeAccent") private var useOrangeAccent = false

    @FocusedValue(\.importAction) var importAction
    @FocusedValue(\.exportAction) var exportAction
    @FocusedValue(\.canExport) var canExport

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import Images...") {
                    importAction?()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Import Images...") {
                    importAction?()
                }
                .keyboardShortcut("i", modifiers: .command)

                Divider()

                Button("Export") {
                    exportAction?()
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(canExport != true)
            }
            CommandGroup(after: .sidebar) {
                Button("Select Dark Mode") {
                    prefersLightMode = false
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                .disabled(!prefersLightMode)

                Button("Select Light Mode") {
                    prefersLightMode = true
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                .disabled(prefersLightMode)

                Divider()

                Toggle("Use Orange Accent", isOn: $useOrangeAccent)
                    .keyboardShortcut("o", modifiers: [.command, .shift])

                Divider()
            }
        }
    }
}
