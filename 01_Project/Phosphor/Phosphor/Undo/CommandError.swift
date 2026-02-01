//
//  CommandError.swift
//  Phosphor
//
//  Created on 2026-02-01
//

import Foundation

enum CommandError: LocalizedError {
    case frameNotFound(UUID)
    case operationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .frameNotFound(let id): return "Frame no longer exists (ID: \(id.uuidString.prefix(8)))"
        case .operationFailed(let error): return error.localizedDescription
        }
    }
}
