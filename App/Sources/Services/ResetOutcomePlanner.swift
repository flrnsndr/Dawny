// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ResetOutcomePlanner.swift
//  Dawny
//
//  Reine Entscheidungslogik des nächtlichen Resets — ohne Seiteneffekte.
//  Einzige Quelle der Wahrheit für „was passiert mit einem Task beim Reset".
//  `ResetEngine` wendet die Ergebnisse an (Mutation), die Widget-Extension
//  nutzt sie read-only für die „Als-ob"-Vorschau nach der Reset-Schwelle.
//

import Foundation

/// Was der Reset mit einem einzelnen Task tut.
enum ResetOutcome: Equatable {
    /// Wird archiviert (Make-It-Count aus Heute, oder Auto-Tidy aus dem Backlog).
    case archive(ArchiveReason)
    /// Geht zurück ins Backlog. `incrementsResetCount == false` für wiederkehrende Tasks.
    case returnToBacklog(incrementsResetCount: Bool)
    /// Keine Änderung.
    case none
}

/// Reiner Wert-Snapshot der für die Reset-Entscheidung relevanten Task-Felder.
struct ResetPlanInput {
    var status: TaskStatus
    var isCompleted: Bool
    var isRecurring: Bool
    var categoryAutoArchiveDays: Int?
    var resetCount: Int
    var enteredBacklogAt: Date?
}

enum ResetOutcomePlanner {
    /// Bestimmt das Reset-Ergebnis für einen Task. Verhaltensgleich zu
    /// `ResetEngine.performReset` (Heute-Pfad) und `archiveStaleBacklogTasks` (Auto-Tidy).
    static func outcome(
        for input: ResetPlanInput,
        referenceDate: Date,
        makeItCountThreshold: Int,
        calendar: Calendar
    ) -> ResetOutcome {
        switch input.status {
        case .inBacklog:
            // Auto-Tidy: abgelaufene, nicht-wiederkehrende Backlog-Tasks archivieren.
            guard
                !input.isCompleted,
                !input.isRecurring,
                let days = input.categoryAutoArchiveDays,
                let enteredAt = input.enteredBacklogAt
            else { return .none }
            let cutoff = calendar.date(byAdding: .day, value: days, to: enteredAt) ?? enteredAt
            return cutoff <= referenceDate ? .archive(.autoTidy) : .none

        case .dailyFocus:
            guard !input.isCompleted else { return .none }
            // Wiederkehrende Tasks gehen immer zurück ins Backlog, nie ins Archiv (Kerninvariante).
            if input.isRecurring {
                return .returnToBacklog(incrementsResetCount: false)
            }
            // Nicht-wiederkehrend: Zähler (gedanklich) erhöhen, ab Schwelle archivieren.
            return input.resetCount + 1 >= makeItCountThreshold
                ? .archive(.makeItCount)
                : .returnToBacklog(incrementsResetCount: true)

        default:
            return .none
        }
    }
}

/// Berechnung der Reset-Zeitpunkte. Extrahiert aus `ResetEngine.calculateLastResetThreshold`,
/// damit die Widget-Provider erkennen können, ob ein Reset überfällig ist und wann der nächste ansteht.
enum ResetSchedule {
    /// Letzter Reset-Schwellwert vor `date` (heute um `resetHour`, oder gestern falls davor).
    static func lastThreshold(before date: Date, resetHour: Int, calendar: Calendar) -> Date {
        let currentHour = calendar.component(.hour, from: date)
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = resetHour
        components.minute = 0
        components.second = 0

        guard var resetToday = calendar.date(from: components) else { return date }
        if currentHour < resetHour {
            resetToday = calendar.date(byAdding: .day, value: -1, to: resetToday) ?? resetToday
        }
        return resetToday
    }

    /// Nächster anstehender Reset-Schwellwert nach `date`.
    static func nextThreshold(after date: Date, resetHour: Int, calendar: Calendar) -> Date {
        let last = lastThreshold(before: date, resetHour: resetHour, calendar: calendar)
        return calendar.date(byAdding: .day, value: 1, to: last) ?? last
    }
}

extension Task {
    /// Wert-Snapshot für den `ResetOutcomePlanner`.
    var resetPlanInput: ResetPlanInput {
        ResetPlanInput(
            status: status,
            isCompleted: isCompleted,
            isRecurring: isRecurring,
            categoryAutoArchiveDays: category?.autoArchiveDays,
            resetCount: resetCount,
            enteredBacklogAt: enteredBacklogAt
        )
    }
}
