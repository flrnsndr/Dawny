//
//  Task.swift
//  Dawny
//
//  SwiftData Model für Tasks
//

import Foundation
import SwiftData

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
        self.category = category
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
    
    // MARK: - Methods
    
    /// Markiert den Task als abgeschlossen
    func complete() {
        isCompleted = true
        status = .completed
        modifiedAt = Date()
    }
    
    /// Setzt den Task zurück ins Backlog (für 3-AM-Reset)
    func resetToBacklog() {
        status = .inBacklog
        scheduledDate = nil
        sortPriority = Date() // Move to top
        modifiedAt = Date()
    }
    
    /// Verschiebt den Task in Daily Focus
    func moveToDailyFocus(date: Date) {
        status = .dailyFocus
        scheduledDate = date
        modifiedAt = Date()
    }
    
    /// Plant den Task für ein zukünftiges Datum
    func scheduleFor(date: Date) {
        status = .scheduled
        scheduledDate = date
        modifiedAt = Date()
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
