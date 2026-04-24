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

    @Published private(set) var canUndo: Bool = false
    @Published private(set) var canRedo: Bool = false
    @Published private(set) var currentUndoActionName: String = ""
    @Published private(set) var currentRedoActionName: String = ""

    func perform(_ command: Command, on appState: AppState) throws {
        try command.execute(on: appState)

        undoStack.append(command)
        redoStack.removeAll()

        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }

        refreshState()
    }

    func undo(on appState: AppState) throws {
        guard let command = undoStack.popLast() else { return }

        try command.undo(on: appState)
        redoStack.append(command)

        if redoStack.count > maxStackSize {
            redoStack.removeFirst()
        }

        refreshState()
    }

    func redo(on appState: AppState) throws {
        guard let command = redoStack.popLast() else { return }

        try command.execute(on: appState)
        undoStack.append(command)

        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }

        refreshState()
    }

    private func refreshState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
        currentUndoActionName = undoStack.last?.actionName ?? ""
        currentRedoActionName = redoStack.last?.actionName ?? ""
    }
}
