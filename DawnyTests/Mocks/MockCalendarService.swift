// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  MockCalendarService.swift
//  DawnyTests
//
//  Mock-Implementierung für testbare Kalender-Interaktion
//

import Foundation
@testable import Dawny

final class MockCalendarService: CalendarServiceProtocol {
    // MARK: - Mock State

    /// Erinnerungen, abgelegt unter ihrer geräteübergreifend stabilen ID.
    var reminders: [String: CalendarReminder] = [:]

    /// Bildet gerätelokale Alt-IDs auf die stabile ID ab — wie EventKit, das eine
    /// `calendarItemIdentifier` weiterhin auflöst, aber nur auf dem Gerät, das sie kennt.
    var legacyIdentifiers: [String: String] = [:]

    var shouldGrantAccess = true
    var shouldFailOperations = false
    
    // MARK: - Tracking
    
    var accessRequestCount = 0
    var createCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var fetchCallCount = 0
    var stableIdentifierCallCount = 0
    
    // MARK: - CalendarServiceProtocol
    
    func requestAccess() async throws -> Bool {
        accessRequestCount += 1
        
        if shouldFailOperations {
            throw CalendarServiceError.permissionDenied
        }
        
        return shouldGrantAccess
    }
    
    func createReminder(title: String, notes: String?, dueDate: Date?) async throws -> String {
        createCallCount += 1
        
        if shouldFailOperations {
            throw CalendarServiceError.saveFailed(underlying: NSError(domain: "MockError", code: -1))
        }
        
        let id = UUID().uuidString
        let reminder = CalendarReminder(
            id: id,
            title: title,
            notes: notes,
            isCompleted: false,
            dueDate: dueDate,
            modificationDate: Date()
        )
        
        reminders[id] = reminder
        return id
    }
    
    func updateReminder(
        id: String,
        title: String?,
        notes: String?,
        isCompleted: Bool?,
        dueDate: Date?
    ) async throws {
        updateCallCount += 1
        
        if shouldFailOperations {
            throw CalendarServiceError.saveFailed(underlying: NSError(domain: "MockError", code: -1))
        }
        
        guard let resolvedID = resolve(id), var reminder = reminders[resolvedID] else {
            throw CalendarServiceError.reminderNotFound
        }
        
        // Update fields
        if let title = title {
            reminder = CalendarReminder(
                id: reminder.id,
                title: title,
                notes: reminder.notes,
                isCompleted: reminder.isCompleted,
                dueDate: reminder.dueDate,
                modificationDate: Date()
            )
        }
        
        if let notes = notes {
            reminder = CalendarReminder(
                id: reminder.id,
                title: reminder.title,
                notes: notes,
                isCompleted: reminder.isCompleted,
                dueDate: reminder.dueDate,
                modificationDate: Date()
            )
        }
        
        if let isCompleted = isCompleted {
            reminder = CalendarReminder(
                id: reminder.id,
                title: reminder.title,
                notes: reminder.notes,
                isCompleted: isCompleted,
                dueDate: reminder.dueDate,
                modificationDate: Date()
            )
        }
        
        if let dueDate = dueDate {
            reminder = CalendarReminder(
                id: reminder.id,
                title: reminder.title,
                notes: reminder.notes,
                isCompleted: reminder.isCompleted,
                dueDate: dueDate,
                modificationDate: Date()
            )
        }
        
        reminders[resolvedID] = reminder
    }
    
    func deleteReminder(id: String) async throws {
        deleteCallCount += 1
        
        if shouldFailOperations {
            throw CalendarServiceError.saveFailed(underlying: NSError(domain: "MockError", code: -1))
        }
        
        guard let resolvedID = resolve(id) else { return }
        reminders.removeValue(forKey: resolvedID)
    }
    
    func fetchReminder(id: String) async throws -> CalendarReminder? {
        fetchCallCount += 1
        
        if shouldFailOperations {
            throw CalendarServiceError.fetchFailed(underlying: NSError(domain: "MockError", code: -1))
        }
        
        guard let resolvedID = resolve(id) else { return nil }
        return reminders[resolvedID]
    }

    func stableIdentifier(forStoredID id: String) async throws -> String? {
        stableIdentifierCallCount += 1

        if shouldFailOperations {
            throw CalendarServiceError.fetchFailed(underlying: NSError(domain: "MockError", code: -1))
        }

        return resolve(id)
    }
    
    func fetchReminders(from startDate: Date, to endDate: Date) async throws -> [CalendarReminder] {
        fetchCallCount += 1
        
        if shouldFailOperations {
            throw CalendarServiceError.fetchFailed(underlying: NSError(domain: "MockError", code: -1))
        }
        
        return reminders.values.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return dueDate >= startDate && dueDate <= endDate
        }
    }
    
    // MARK: - Helper Methods

    /// Simuliert eine Verknüpfung aus der Zeit vor der Umstellung: Die Aufgabe hält eine
    /// gerätelokale ID, die nur dieses Gerät auf die Erinnerung auflösen kann.
    func registerLegacyIdentifier(_ legacyID: String, for stableID: String) {
        legacyIdentifiers[legacyID] = stableID
    }

    /// Löst eine gespeicherte ID auf: stabile ID direkt, Alt-ID über die Zuordnung.
    private func resolve(_ id: String) -> String? {
        if reminders[id] != nil {
            return id
        }

        guard let mapped = legacyIdentifiers[id], reminders[mapped] != nil else {
            return nil
        }

        return mapped
    }

    func reset() {
        reminders.removeAll()
        legacyIdentifiers.removeAll()
        shouldGrantAccess = true
        shouldFailOperations = false
        accessRequestCount = 0
        createCallCount = 0
        updateCallCount = 0
        deleteCallCount = 0
        fetchCallCount = 0
        stableIdentifierCallCount = 0
    }
}
