//
//  ReorderFramesCommand.swift
//  Phosphor
//
//  Created on 2026-02-01
//

import Foundation

@MainActor
struct ReorderFramesCommand: Command {
    let actionName = "Reorder Frames"
    let sourceIndices: IndexSet
    let destination: Int
    private let originalOrder: [UUID]

    init(from source: IndexSet, to destination: Int, currentFrames: [ImageItem]) {
        self.sourceIndices = source
        self.destination = destination
        self.originalOrder = currentFrames.map { $0.id }
    }

    func execute(on state: AppState) throws {
        state.frames.move(fromOffsets: sourceIndices, toOffset: destination)
    }

    func undo(on state: AppState) throws {
        var restoredFrames: [ImageItem] = []

        for id in originalOrder {
            guard let frame = state.frames.first(where: { $0.id == id }) else {
                throw CommandError.frameNotFound(id)
            }
            restoredFrames.append(frame)
        }

        state.frames = restoredFrames
    }
}
