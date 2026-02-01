//
//  Command.swift
//  Phosphor
//
//  Created on 2026-02-01
//

import Foundation

@MainActor
protocol Command {
    var actionName: String { get }
    func execute(on state: AppState) throws
    func undo(on state: AppState) throws
}
