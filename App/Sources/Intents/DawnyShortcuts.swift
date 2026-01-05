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
                "Neuer Task in \(.applicationName)",
                "Task hinzufügen in \(.applicationName)",
                "Etwas zu \(.applicationName) hinzufügen",
                "Merken in \(.applicationName)"
            ],
            shortTitle: "Task hinzufügen",
            systemImageName: "plus.circle"
        )
        
        // MARK: - Task für heute hinzufügen
        AppShortcut(
            intent: AddTaskTodayIntent(),
            phrases: [
                "Heute in \(.applicationName)",
                "Task für heute in \(.applicationName)",
                "Heute hinzufügen in \(.applicationName)"
            ],
            shortTitle: "Task für heute",
            systemImageName: "sun.max"
        )
    }
}

