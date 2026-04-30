// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  DawnyShortcuts.swift
//  Dawny
//
//  App Shortcuts Provider für Siri-Phrasen
//

import AppIntents

/// Definiert die Siri-Phrasen für Dawny
struct DawnyShortcuts: AppShortcutsProvider {
    
    /// Alle verfügbaren App Shortcuts
    static var appShortcuts: [AppShortcut] {
        
        // MARK: - Task zum Backlog hinzufügen
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "New task in \(.applicationName)",
                "Add task in \(.applicationName)",
                "Add something to \(.applicationName)",
                "Remember in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("intent.addtask.shorttitle", defaultValue: "Add Task"),
            systemImageName: "plus.circle"
        )
        
        // MARK: - Task für heute hinzufügen
        AppShortcut(
            intent: AddTaskTodayIntent(),
            phrases: [
                "Today in \(.applicationName)",
                "Add for today in \(.applicationName)",
                "Add today in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("intent.addtasktoday.shorttitle", defaultValue: "Task for Today"),
            systemImageName: "sun.max"
        )
    }
}
