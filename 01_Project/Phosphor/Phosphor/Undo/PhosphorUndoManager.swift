//
//  PhosphorUndoManager.swift
//  Phosphor
//
//  Created on 2026-02-01
//

import Foundation

@MainActor
class PhosphorUndoManager: ObservableObject {
    private var undoStack: [Command] = []
    private var redoStack: [Command] = []

    private let maxStackSize = 50

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    var canRedo: Bool {
        !redoStack.isEmpty
    }

    var currentUndoActionName: String {
        undoStack.last?.actionName ?? ""
    }

    var currentRedoActionName: String {
        redoStack.last?.actionName ?? ""
    }

    func perform(_ command: Command, on appState: AppState) throws {
        try command.execute(on: appState)

        undoStack.append(command)
        redoStack.removeAll()

        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }
    }

    func undo(on appState: AppState) throws {
        guard let command = undoStack.popLast() else { return }

        try command.undo(on: appState)
        redoStack.append(command)

        if redoStack.count > maxStackSize {
            redoStack.removeFirst()
        }
    }

    func redo(on appState: AppState) throws {
        guard let command = redoStack.popLast() else { return }

        try command.execute(on: appState)
        undoStack.append(command)

        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }
    }
}
