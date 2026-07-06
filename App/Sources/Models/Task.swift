// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  Task.swift
//  Dawny
//
//  SwiftData Model für Tasks
//

import Foundation
import SwiftData

// MARK: - ArchiveReason

enum ArchiveReason: String, Codable {
    case makeItCount  // dailyFocus → archived nach Make-It-Count-Threshold
    case autoTidy     // backlog → archived nach Kategorie-Lifespan
    case manual       // User hat selbst archiviert
}

// MARK: - Task

@Model
final class Task {
    // MARK: - Stored Properties
    
    /// Eindeutige ID des Tasks
    var id: UUID
    
    /// Titel/Beschreibung des Tasks
    var title: String
    
    /// Optional: Zusätzliche Notizen
    var notes: String?
    
    /// Aktueller Status im Lifecycle
    var status: TaskStatus
    
    /// ID des Parent-Backlogs (wichtig für Reset)
    var parentBacklogID: UUID
    
    /// Optional: Geplantes Datum (nur wenn scheduled oder dailyFocus)
    var scheduledDate: Date?
    
    /// Optional: ID des verknüpften EKReminder
    var externalReminderID: String?
    
    /// Sortier-Priorität (für Backlog-Anordnung)
    /// Bei Reset wird dies auf Date() gesetzt, um Tasks nach oben zu bringen
    var sortPriority: Date
    
    /// Erstellungsdatum (unveränderlich)
    var createdAt: Date
    
    /// Letztes Änderungsdatum (für Sync-Konfliktauflösung)
    var modifiedAt: Date
    
    /// Flag ob Task abgeschlossen ist
    var isCompleted: Bool

    /// Setzt `complete`/`uncomplete` für wiederkehrende Aufgaben mit dem
    /// erzeugten Backlog-Clone in Verbindung.
    var recurringCloneID: UUID? = nil

    /// Zählt, wie oft der Task im Heute-Tab lag und beim täglichen Reset noch nicht erledigt war.
    /// Wird bei manuellem Zurücklegen und bei Unarchivierung auf 0 gesetzt.
    var resetCount: Int = 0

    /// Zeitpunkt der Archivierung (nil wenn nicht archiviert)
    var archivedAt: Date? = nil

    /// Grund der Archivierung — nil wenn nicht archiviert
    var archiveReason: ArchiveReason? = nil

    /// True = User hat dieses archivierte Item bereits im Review-Overlay gesehen.
    /// Default true, damit existierende Archive beim ersten Update nicht alle im Overlay auftauchen.
    var archiveReviewed: Bool = true

    /// Zeitpunkt der manuellen Erledigung (nil wenn nicht oder noch nicht erledigt)
    var completedAt: Date? = nil

    /// Auto-Tidy: Zeitpunkt, seit dem der Task ununterbrochen im Backlog liegt.
    /// Wird beim Eingang ins Backlog gesetzt und beim Verschieben in Daily/Scheduled/Archive genillt.
    var enteredBacklogAt: Date? = nil

    // MARK: - Relationships
    
    /// Referenz zum Parent-Backlog
    var backlog: Backlog?
    
    /// Optional: Kategorie für Backlog-Organisation
    var category: Category?
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        status: TaskStatus = .inBacklog,
        parentBacklogID: UUID,
        scheduledDate: Date? = nil,
        externalReminderID: String? = nil,
        sortPriority: Date = Date(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isCompleted: Bool = false,
        recurringCloneID: UUID? = nil,
        category: Category? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.status = status
        self.parentBacklogID = parentBacklogID
        self.scheduledDate = scheduledDate
        self.externalReminderID = externalReminderID
        self.sortPriority = sortPriority
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isCompleted = isCompleted
        self.recurringCloneID = recurringCloneID
        self.category = category
        self.enteredBacklogAt = (status == .inBacklog) ? Date() : nil
    }
    
    // MARK: - Computed Properties
    
    /// Prüft ob der Task resettet werden muss (nicht abgeschlossen in dailyFocus)
    var needsReset: Bool {
        status == .dailyFocus && !isCompleted
    }
    
    /// Gibt an ob der Task synchronisiert werden soll
    var shouldSyncToCalendar: Bool {
        status.shouldSyncToCalendar
    }
    
    /// Gibt an ob der Task mit dem Kalender verknüpft ist
    var isSyncedToCalendar: Bool {
        externalReminderID != nil
    }
    
    /// Prüft ob der Task heute erledigt wurde (für Anzeige im Heute-Tab)
    var isCompletedToday: Bool {
        guard isCompleted, let scheduledDate = scheduledDate else { return false }
        return Calendar.current.isDateInToday(scheduledDate)
    }

    /// True, wenn der Task in einer als wiederkehrend markierten Kategorie liegt.
    var isRecurring: Bool {
        category?.isRecurring == true
    }

    // MARK: - Methods
    
    /// Markiert den Task als abgeschlossen
    func complete() {
        isCompleted = true
        status = .completed
        completedAt = Date()
        modifiedAt = Date()
    }
    
    /// Setzt den Task zurück ins Backlog (für 3-AM-Reset oder manuell).
    /// `resetCount` wird hier NICHT zurückgesetzt – das macht der ResetEngine-Aufrufer
    /// nur beim manuellen Zurücklegen, nicht beim automatischen Reset.
    func resetToBacklog() {
        status = .inBacklog
        scheduledDate = nil
        sortPriority = Date() // Move to top
        modifiedAt = Date()
        enteredBacklogAt = Date()
    }

    /// Archiviert den Task nach wiederholtem Nicht-Erledigen (Make it count), Auto-Tidy oder manuell.
    func archive(reason: ArchiveReason) {
        status = .archived
        archivedAt = Date()
        scheduledDate = nil
        modifiedAt = Date()
        enteredBacklogAt = nil
        archiveReason = reason
        archiveReviewed = (reason == .manual)
    }

    /// Unarchiviert den Task zurück ins Backlog. Setzt resetCount auf 0.
    func unarchiveToBacklog() {
        status = .inBacklog
        archivedAt = nil
        archiveReason = nil
        archiveReviewed = true
        resetCount = 0
        sortPriority = Date()
        modifiedAt = Date()
        enteredBacklogAt = Date()
    }

    /// Unarchiviert den Task direkt in den Daily Focus. Setzt resetCount auf 0.
    func unarchiveToDailyFocus(date: Date) {
        status = .dailyFocus
        scheduledDate = date
        archivedAt = nil
        archiveReason = nil
        archiveReviewed = true
        resetCount = 0
        modifiedAt = Date()
        enteredBacklogAt = nil
    }

    /// Verschiebt den Task in Daily Focus
    func moveToDailyFocus(date: Date) {
        status = .dailyFocus
        scheduledDate = date
        modifiedAt = Date()
        enteredBacklogAt = nil
    }

    /// Plant den Task für ein zukünftiges Datum (nur via SyncEngine, keine User-UI)
    func scheduleFor(date: Date) {
        status = .scheduled
        scheduledDate = date
        modifiedAt = Date()
        enteredBacklogAt = nil
    }
    
    /// Entfernt die Kalender-Verknüpfung
    func unlinkFromCalendar() {
        externalReminderID = nil
        modifiedAt = Date()
    }
    
    /// Verknüpft mit einem Kalender-Reminder
    func linkToCalendar(reminderID: String) {
        externalReminderID = reminderID
        modifiedAt = Date()
    }
}

// MARK: - Comparable

extension Task: Comparable {
    static func < (lhs: Task, rhs: Task) -> Bool {
        // Primär nach sortPriority (neuere = höher)
        if lhs.sortPriority != rhs.sortPriority {
            return lhs.sortPriority > rhs.sortPriority
        }
        // Sekundär nach Erstellungsdatum (ältere = höher für gleiche Priority)
        return lhs.createdAt < rhs.createdAt
    }
}
