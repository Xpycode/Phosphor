//
//  PhosphorApp.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI

@main
struct PhosphorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
