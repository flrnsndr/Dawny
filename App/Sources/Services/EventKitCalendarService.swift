// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  EventKitCalendarService.swift
//  Dawny
//
//  EventKit-Implementierung des CalendarService
//

import Foundation
import EventKit

/// Konkrete Implementierung des CalendarServiceProtocol mit EventKit
final class EventKitCalendarService: CalendarServiceProtocol {
    // MARK: - Properties
    
    private let eventStore = EKEventStore()
    private var defaultCalendar: EKCalendar?
    
    // MARK: - CalendarServiceProtocol Implementation
    
    func requestAccess() async throws -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            
            if granted {
                // Setze Default-Calendar für Reminders
                defaultCalendar = eventStore.defaultCalendarForNewReminders()
            }
            
            return granted
        } catch {
            throw CalendarServiceError.permissionDenied
        }
    }
    
    func createReminder(title: String, notes: String?, dueDate: Date?) async throws -> String {
        guard let calendar = defaultCalendar ?? eventStore.defaultCalendarForNewReminders() else {
            throw CalendarServiceError.permissionDenied
        }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = calendar
        
        // Setze als All-Day Reminder wenn Datum vorhanden
        if let dueDate = dueDate {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
            reminder.dueDateComponents = components
            reminder.isCompleted = false
        }
        
        do {
            try eventStore.save(reminder, commit: true)
            return stableIdentifier(for: reminder)
        } catch {
            throw CalendarServiceError.saveFailed(underlying: error)
        }
    }
    
    func updateReminder(
        id: String,
        title: String?,
        notes: String?,
        isCompleted: Bool?,
        dueDate: Date?
    ) async throws {
        guard let reminder = try await fetchEKReminder(id: id) else {
            throw CalendarServiceError.reminderNotFound
        }
        
        // Update nur die übergebenen Werte
        if let title = title {
            reminder.title = title
        }
        
        if let notes = notes {
            reminder.notes = notes
        }
        
        if let isCompleted = isCompleted {
            reminder.isCompleted = isCompleted
            if isCompleted {
                reminder.completionDate = Date()
            }
        }
        
        if let dueDate = dueDate {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
            reminder.dueDateComponents = components
        }
        
        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            throw CalendarServiceError.saveFailed(underlying: error)
        }
    }
    
    func deleteReminder(id: String) async throws {
        guard let reminder = try await fetchEKReminder(id: id) else {
            // Nicht gefunden = bereits gelöscht
            return
        }
        
        do {
            try eventStore.remove(reminder, commit: true)
        } catch {
            throw CalendarServiceError.saveFailed(underlying: error)
        }
    }
    
    func fetchReminder(id: String) async throws -> CalendarReminder? {
        guard let ekReminder = try await fetchEKReminder(id: id) else {
            return nil
        }
        
        return convertToCalendarReminder(ekReminder)
    }
    
    func stableIdentifier(forStoredID id: String) async throws -> String? {
        guard let reminder = try await fetchEKReminder(id: id) else {
            return nil
        }

        return stableIdentifier(for: reminder)
    }

    func fetchReminders(from startDate: Date, to endDate: Date) async throws -> [CalendarReminder] {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        return try await withCheckedThrowingContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                guard let reminders = reminders else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Filter nach Datum
                let filtered = reminders.filter { reminder in
                    guard let dueDate = reminder.dueDateComponents?.date else {
                        return false
                    }
                    return dueDate >= startDate && dueDate <= endDate
                }
                
                let calendarReminders = filtered.map { self.convertToCalendarReminder($0) }
                continuation.resume(returning: calendarReminders)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Holt einen EKReminder anhand seiner ID.
    ///
    /// Erst über die geräteübergreifende `calendarItemExternalIdentifier`, dann über die
    /// gerätelokale `calendarItemIdentifier`. Der zweite Weg deckt Verknüpfungen ab, die
    /// vor der Umstellung gespeichert wurden und noch nicht migriert sind.
    private func fetchEKReminder(id: String) async throws -> EKReminder? {
        let externalMatches = eventStore
            .calendarItems(withExternalIdentifier: id)
            .compactMap { $0 as? EKReminder }

        if let reminder = preferredReminder(from: externalMatches) {
            return reminder
        }

        return eventStore.calendarItem(withIdentifier: id) as? EKReminder
    }

    /// Die geräteübergreifend stabile ID einer Erinnerung.
    ///
    /// `calendarItemExternalIdentifier` ist bei iCloud-Erinnerungen auf allen Geräten
    /// dieselbe und fällt bei lokalen Listen laut EventKit-Doku auf die lokale ID zurück.
    /// Für Exchange-Erinnerungen unterscheidet sie sich zwischen Geräten — dort bleibt es
    /// beim bisherigen Verhalten, ein besserer Anker existiert nicht.
    private func stableIdentifier(for reminder: EKReminder) -> String {
        guard let externalID = reminder.calendarItemExternalIdentifier, !externalID.isEmpty else {
            return reminder.calendarItemIdentifier
        }

        return externalID
    }

    /// Wählt deterministisch eine Erinnerung aus, wenn eine externe ID auf mehrere zeigt.
    ///
    /// Das passiert unter anderem bei Wiederholungen und bei mehrfach importierten Listen.
    /// Offene vor erledigten Einträgen, dann das frühere Fälligkeitsdatum, zuletzt die
    /// lokale ID — damit landet jeder Aufruf auf demselben Eintrag.
    private func preferredReminder(from candidates: [EKReminder]) -> EKReminder? {
        candidates.min { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }

            let lhsDue = lhs.dueDateComponents?.date ?? .distantFuture
            let rhsDue = rhs.dueDateComponents?.date ?? .distantFuture
            if lhsDue != rhsDue {
                return lhsDue < rhsDue
            }

            return lhs.calendarItemIdentifier < rhs.calendarItemIdentifier
        }
    }

    /// Konvertiert einen EKReminder zu CalendarReminder
    private func convertToCalendarReminder(_ reminder: EKReminder) -> CalendarReminder {
        CalendarReminder(
            id: stableIdentifier(for: reminder),
            title: reminder.title ?? "",
            notes: reminder.notes,
            isCompleted: reminder.isCompleted,
            dueDate: reminder.dueDateComponents?.date,
            modificationDate: reminder.lastModifiedDate
        )
    }
}
