//
//  CalendarServiceProtocol.swift
//  Dawn
//
//  Protocol für testbare EventKit-Interaktionen
//

import Foundation
import EventKit

/// Repräsentiert einen Reminder aus dem Kalender
struct CalendarReminder {
    let id: String
    let title: String
    let notes: String?
    let isCompleted: Bool
    let dueDate: Date?
    let modificationDate: Date?
}

/// Fehlertypen für Calendar-Operationen
enum CalendarServiceError: Error {
    case permissionDenied
    case reminderNotFound
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
}

/// Protokoll zur Abstraktion von EventKit-Operationen
/// Ermöglicht Mocking in Tests ohne echten Kalender-Zugriff
protocol CalendarServiceProtocol {
    /// Fordert Zugriff auf Reminders an
    func requestAccess() async throws -> Bool
    
    /// Erstellt einen neuen Reminder im Kalender
    func createReminder(title: String, notes: String?, dueDate: Date?) async throws -> String
    
    /// Aktualisiert einen existierenden Reminder
    func updateReminder(id: String, title: String?, notes: String?, isCompleted: Bool?, dueDate: Date?) async throws
    
    /// Löscht einen Reminder aus dem Kalender
    func deleteReminder(id: String) async throws
    
    /// Holt einen Reminder anhand seiner ID
    func fetchReminder(id: String) async throws -> CalendarReminder?
    
    /// Holt alle Reminders für einen bestimmten Zeitraum
    func fetchReminders(from startDate: Date, to endDate: Date) async throws -> [CalendarReminder]
}
