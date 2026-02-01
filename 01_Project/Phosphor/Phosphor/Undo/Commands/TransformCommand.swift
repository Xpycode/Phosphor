//
//  TransformCommand.swift
//  Phosphor
//
//  Created on 2026-02-01
//

import Foundation

@MainActor
struct TransformCommand: Command {
    let actionName: String
    let frameID: UUID
    let oldTransform: FrameTransform
    let newTransform: FrameTransform

    init(frameID: UUID, oldTransform: FrameTransform, newTransform: FrameTransform, actionName: String = "Transform Frame") {
        self.frameID = frameID
        self.oldTransform = oldTransform
        self.newTransform = newTransform
        self.actionName = actionName
    }

    func execute(on state: AppState) throws {
        guard let index = state.frames.firstIndex(where: { $0.id == frameID }) else {
            throw CommandError.frameNotFound(frameID)
        }
        state.frames[index].transform = newTransform
    }

    func undo(on state: AppState) throws {
        guard let index = state.frames.firstIndex(where: { $0.id == frameID }) else {
            throw CommandError.frameNotFound(frameID)
        }
        state.frames[index].transform = oldTransform
    }
}
