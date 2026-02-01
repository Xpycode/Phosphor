//
//  ToggleMuteCommand.swift
//  Phosphor
//
//  Created on 2026-02-01
//

import Foundation

@MainActor
struct ToggleMuteCommand: Command {
    let actionName = "Toggle Mute"
    let frameID: UUID

    init(frameID: UUID) {
        self.frameID = frameID
    }

    func execute(on state: AppState) throws {
        guard let index = state.frames.firstIndex(where: { $0.id == frameID }) else {
            throw CommandError.frameNotFound(frameID)
        }
        state.frames[index].isMuted.toggle()
    }

    func undo(on state: AppState) throws {
        guard let index = state.frames.firstIndex(where: { $0.id == frameID }) else {
            throw CommandError.frameNotFound(frameID)
        }
        state.frames[index].isMuted.toggle()
    }
}
