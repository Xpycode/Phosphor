//
//  DeleteFrameCommand.swift
//  Phosphor
//
//  Created on 2026-02-01
//

import Foundation

@MainActor
struct DeleteFrameCommand: Command {
    let actionName = "Delete Frame"
    let frameID: UUID
    let frame: ImageItem
    let originalIndex: Int

    init(frame: ImageItem, at index: Int) {
        self.frameID = frame.id
        self.frame = frame
        self.originalIndex = index
    }

    func execute(on state: AppState) throws {
        guard let index = state.frames.firstIndex(where: { $0.id == frameID }) else {
            throw CommandError.frameNotFound(frameID)
        }
        state.frames.remove(at: index)
    }

    func undo(on state: AppState) throws {
        let insertIndex = min(originalIndex, state.frames.count)
        state.frames.insert(frame, at: insertIndex)
    }
}
