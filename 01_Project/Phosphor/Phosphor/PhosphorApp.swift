//
//  PhosphorApp.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import SwiftUI

@main
struct PhosphorApp: App {
    @AppStorage("prefersLightMode") private var prefersLightMode = false
    @AppStorage("useOrangeAccent") private var useOrangeAccent = false

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .sidebar) {
                Button("Select Dark Mode") {
                    prefersLightMode = false
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                .disabled(!prefersLightMode)

                Button("Select Light Mode") {
                    prefersLightMode = true
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                .disabled(prefersLightMode)

                Divider()

                Toggle("Use Orange Accent", isOn: $useOrangeAccent)
                    .keyboardShortcut("o", modifiers: [.command, .shift])

                Divider()
            }
        }
    }
}
