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
                "Remember in \(.applicationName)",
                "Neue Aufgabe in \(.applicationName)",
                "Aufgabe in \(.applicationName) hinzufügen",
                "Etwas in \(.applicationName) merken"
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
                "Add task to today in \(.applicationName)",
                "Heute in \(.applicationName)",
                "Aufgabe für heute in \(.applicationName)",
                "Aufgabe für heute in \(.applicationName) hinzufügen"
            ],
            shortTitle: LocalizedStringResource("intent.addtasktoday.shorttitle", defaultValue: "Task for Today"),
            systemImageName: "sun.max"
        )

        // MARK: - Backlog-Task zu heute verschieben
        AppShortcut(
            intent: MoveTaskToTodayIntent(),
            phrases: [
                "Move \(\.$task) to today in \(.applicationName)",
                "Plan \(\.$task) for today in \(.applicationName)",
                "\(\.$task) auf heute in \(.applicationName)",
                "\(\.$task) für heute in \(.applicationName) planen"
            ],
            shortTitle: LocalizedStringResource("intent.movetoday.shorttitle", defaultValue: "Move to Today"),
            systemImageName: "sun.max.fill"
        )

        // MARK: - Task abschließen
        AppShortcut(
            intent: CompleteTaskIntent(),
            phrases: [
                "Mark \(\.$task) done in \(.applicationName)",
                "Complete \(\.$task) in \(.applicationName)",
                "\(\.$task) in \(.applicationName) erledigen",
                "\(\.$task) in \(.applicationName) abschließen"
            ],
            shortTitle: LocalizedStringResource("intent.complete.shorttitle", defaultValue: "Complete Task"),
            systemImageName: "checkmark.circle"
        )

        // MARK: - Heute-Liste vorlesen
        AppShortcut(
            intent: ListTodayTasksIntent(),
            phrases: [
                "What's on my \(.applicationName) today",
                "List today's tasks in \(.applicationName)",
                "Was steht heute in \(.applicationName) an"
            ],
            shortTitle: LocalizedStringResource("intent.listtoday.shorttitle", defaultValue: "Today List"),
            systemImageName: "list.bullet"
        )
    }
}
