//
//  ImportFramesCommand.swift
//  Phosphor
//
//  Created on 2026-02-01
//

import Foundation

@MainActor
struct ImportFramesCommand: Command {
    let actionName = "Import Frames"
    let frames: [ImageItem]
    private var importedFrameIDs: [UUID] = []

    init(frames: [ImageItem]) {
        self.frames = frames
        self.importedFrameIDs = frames.map { $0.id }
    }

    func execute(on state: AppState) throws {
        state.frames.append(contentsOf: frames)
    }

    func undo(on state: AppState) throws {
        state.frames.removeAll { frame in
            importedFrameIDs.contains(frame.id)
        }
    }
}
