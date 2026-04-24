//
//  ApplyTransformToAllCommand.swift
//  Phosphor
//
//  Created on 2026-04-24
//

import Foundation

@MainActor
struct ApplyTransformToAllCommand: Command {
    let actionName = "Apply Transform to All"
    let newTransform: FrameTransform
    let previousTransforms: [UUID: FrameTransform]

    init(newTransform: FrameTransform, frames: [ImageItem]) {
        self.newTransform = newTransform
        self.previousTransforms = Dictionary(
            uniqueKeysWithValues: frames.map { ($0.id, $0.transform) }
        )
    }

    func execute(on state: AppState) throws {
        for index in state.frames.indices {
            state.frames[index].transform = newTransform
        }
    }

    func undo(on state: AppState) throws {
        for index in state.frames.indices {
            if let original = previousTransforms[state.frames[index].id] {
                state.frames[index].transform = original
            }
        }
    }
}
