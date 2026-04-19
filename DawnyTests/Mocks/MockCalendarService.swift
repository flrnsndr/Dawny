// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

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
    
    var reminders: [String: CalendarReminder] = [:]
    var shouldGrantAccess = true
    var shouldFailOperations = false
    
    // MARK: - Tracking
    
    var accessRequestCount = 0
    var createCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var fetchCallCount = 0
    
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
        
        guard var reminder = reminders[id] else {
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
        
        reminders[id] = reminder
    }
    
    func deleteReminder(id: String) async throws {
        deleteCallCount += 1
        
        if shouldFailOperations {
            throw CalendarServiceError.saveFailed(underlying: NSError(domain: "MockError", code: -1))
        }
        
        reminders.removeValue(forKey: id)
    }
    
    func fetchReminder(id: String) async throws -> CalendarReminder? {
        fetchCallCount += 1
        
        if shouldFailOperations {
            throw CalendarServiceError.fetchFailed(underlying: NSError(domain: "MockError", code: -1))
        }
        
        return reminders[id]
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
    
    func reset() {
        reminders.removeAll()
        shouldGrantAccess = true
        shouldFailOperations = false
        accessRequestCount = 0
        createCallCount = 0
        updateCallCount = 0
        deleteCallCount = 0
        fetchCallCount = 0
    }
}
