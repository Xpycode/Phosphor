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

struct UndoActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct RedoActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct CanUndoKey: FocusedValueKey {
    typealias Value = Bool
}

struct CanRedoKey: FocusedValueKey {
    typealias Value = Bool
}

struct UndoActionNameKey: FocusedValueKey {
    typealias Value = String
}

struct RedoActionNameKey: FocusedValueKey {
    typealias Value = String
}

struct IsImportingKey: FocusedValueKey {
    typealias Value = Bool
}

struct IsExportingKey: FocusedValueKey {
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

    var undoAction: (() -> Void)? {
        get { self[UndoActionKey.self] }
        set { self[UndoActionKey.self] = newValue }
    }

    var redoAction: (() -> Void)? {
        get { self[RedoActionKey.self] }
        set { self[RedoActionKey.self] = newValue }
    }

    var canUndo: Bool? {
        get { self[CanUndoKey.self] }
        set { self[CanUndoKey.self] = newValue }
    }

    var canRedo: Bool? {
        get { self[CanRedoKey.self] }
        set { self[CanRedoKey.self] = newValue }
    }

    var undoActionName: String? {
        get { self[UndoActionNameKey.self] }
        set { self[UndoActionNameKey.self] = newValue }
    }

    var redoActionName: String? {
        get { self[RedoActionNameKey.self] }
        set { self[RedoActionNameKey.self] = newValue }
    }

    var isImporting: Bool? {
        get { self[IsImportingKey.self] }
        set { self[IsImportingKey.self] = newValue }
    }

    var isExporting: Bool? {
        get { self[IsExportingKey.self] }
        set { self[IsExportingKey.self] = newValue }
    }
}

@main
struct PhosphorApp: App {
    @AppStorage("prefersLightMode") private var prefersLightMode = false
    @AppStorage("useOrangeAccent") private var useOrangeAccent = false

    @FocusedValue(\.importAction) var importAction
    @FocusedValue(\.exportAction) var exportAction
    @FocusedValue(\.canExport) var canExport
    @FocusedValue(\.undoAction) var undoAction
    @FocusedValue(\.redoAction) var redoAction
    @FocusedValue(\.canUndo) var canUndo
    @FocusedValue(\.canRedo) var canRedo
    @FocusedValue(\.undoActionName) var undoActionName
    @FocusedValue(\.redoActionName) var redoActionName
    @FocusedValue(\.isImporting) var isImporting
    @FocusedValue(\.isExporting) var isExporting

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
            CommandGroup(replacing: .undoRedo) {
                Button("Undo \(undoActionName ?? "")") {
                    undoAction?()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(canUndo != true || isImporting == true || isExporting == true)

                Button("Redo \(redoActionName ?? "")") {
                    redoAction?()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(canRedo != true || isImporting == true || isExporting == true)
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
