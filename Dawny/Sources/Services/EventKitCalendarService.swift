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
            return reminder.calendarItemIdentifier
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
    
    /// Holt einen EKReminder anhand seiner ID
    private func fetchEKReminder(id: String) async throws -> EKReminder? {
        guard let calendarItem = eventStore.calendarItem(withIdentifier: id) else {
            return nil
        }
        
        return calendarItem as? EKReminder
    }
    
    /// Konvertiert einen EKReminder zu CalendarReminder
    private func convertToCalendarReminder(_ reminder: EKReminder) -> CalendarReminder {
        CalendarReminder(
            id: reminder.calendarItemIdentifier,
            title: reminder.title ?? "",
            notes: reminder.notes,
            isCompleted: reminder.isCompleted,
            dueDate: reminder.dueDateComponents?.date,
            modificationDate: reminder.lastModifiedDate
        )
    }
}
