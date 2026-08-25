// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  UITestSupport.swift
//  Dawny
//
//  Stellt beim Start mit `--uitesting` einen deterministischen Zustand her, damit die
//  UI-Tests weder den Welcome-Screen noch den Reminders-Berechtigungsdialog wegräumen
//  müssen. Gegenstück zu `ScreenshotSeeder`, das dasselbe für `--screenshots` tut.
//

#if DEBUG
import Foundation
import SwiftData

enum UITestSupport {
    /// Erkennt, ob die App aus einem UI-Test heraus läuft.
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    /// Tests, die den Welcome-Flow selbst prüfen, holen ihn mit `--welcome-flow`
    /// zurück, den `--uitesting` sonst überspringt.
    static var wantsWelcomeFlow: Bool {
        ProcessInfo.processInfo.arguments.contains("--welcome-flow")
    }

    /// Setzt die Einstellungen, die sonst beim ersten Start Dialoge auslösen.
    /// Muss aus `DawnyApp.init()` laufen, bevor die erste View erscheint, sonst
    /// präsentiert `ContentView` den Welcome-Cover bereits.
    static func prepareForLaunch() {
        if wantsWelcomeFlow {
            // Ausgangszustand wie bei einer Neuinstallation: der Cover erscheint und
            // der Sync-Schalter der iCloud-Seite steht vorbelegt auf „an".
            AppSettings.shared.hasSeenWelcome = false
            AppSettings.shared.hasSeenICloudSyncIntro = false
            AppSettings.shared.iCloudSyncEnabled = false
        } else {
            AppSettings.shared.hasSeenWelcome = true
        }
        // Ohne Sync kein `requestFullAccessToReminders` und damit kein Systemdialog,
        // der den Test blockiert.
        AppSettings.shared.calendarSyncEnabled = false
    }

    /// Leert die Task-Tabelle, damit jeder Test auf derselben kurzen Liste startet.
    /// Die Kategorien bleiben stehen, die legt `CategoryService` deterministisch an.
    static func resetTasks(in context: ModelContext) {
        do {
            for task in try context.fetch(FetchDescriptor<Task>()) {
                context.delete(task)
            }
            try context.save()
        } catch {
            print("⚠️ UITestSupport: Task-Reset fehlgeschlagen: \(error)")
        }
    }
}
#endif
