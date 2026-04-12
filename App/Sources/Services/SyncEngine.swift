//
//  SyncEngine.swift
//  Dawny
//
//  Engine für bidirektionale Synchronisation mit EventKit
//

import Foundation
import SwiftData
import EventKit
import Combine

/// SyncEngine - Verantwortlich für Kalender-Synchronisation
@MainActor
final class SyncEngine {
    // MARK: - Properties
    
    private let calendarService: CalendarServiceProtocol
    private let modelContext: ModelContext
    private var observerTask: _Concurrency.Task<Void, Never>?
    private var syncInProgress = false
    private var lastSyncDate = Date()
    private let debounceInterval: TimeInterval = 1.0
    
    // MARK: - Initializer
    
    init(calendarService: CalendarServiceProtocol, modelContext: ModelContext) {
        self.calendarService = calendarService
        self.modelContext = modelContext
    }
    
    deinit {
        observerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Startet das Beobachten von Kalender-Änderungen
    func startObserving() async {
        // Registriere für EventStore-Änderungen
        observerTask = _Concurrency.Task {
            for await _ in NotificationCenter.default.notifications(named: .EKEventStoreChanged) {
                await handleCalendarChanged()
            }
        }
        
        // Initiale Sync
        await syncFromCalendar()
    }
    
    /// Stoppt das Beobachten
    func stopObserving() {
        observerTask?.cancel()
        observerTask = nil
    }
    
    /// Synchronisiert einen Task zum Kalender (App → Calendar)
    func syncTaskToCalendar(_ task: Task) async {
        // Prüfe ob Kalender-Sync aktiviert ist
        guard AppSettings.shared.calendarSyncEnabled else {
            return
        }
        
        guard task.shouldSyncToCalendar else {
            // Task soll nicht mehr synchronisiert werden
            if task.isSyncedToCalendar {
                await removeTaskFromCalendar(task)
            }
            return
        }
        
        do {
            if let existingID = task.externalReminderID {
                // Update existierenden Reminder
                try await calendarService.updateReminder(
                    id: existingID,
                    title: task.title,
                    notes: task.notes,
                    isCompleted: task.isCompleted,
                    dueDate: task.scheduledDate
                )
                print("✅ Updated reminder in calendar: \(task.title)")
            } else {
                // Erstelle neuen Reminder
                let reminderID = try await calendarService.createReminder(
                    title: task.title,
                    notes: task.notes,
                    dueDate: task.scheduledDate
                )
                task.linkToCalendar(reminderID: reminderID)
                try modelContext.save()
                print("✅ Created reminder in calendar: \(task.title)")
            }
        } catch {
            print("❌ Failed to sync task to calendar: \(error)")
        }
    }
    
    /// Entfernt nur den EventKit-Reminder (ohne SwiftData-Task). Für Debug-Massenlöschen nach DB-Delete.
    func deleteReminderFromCalendarOnly(id: String) async {
        do {
            try await calendarService.deleteReminder(id: id)
        } catch {
            print("⚠️ deleteReminderFromCalendarOnly(\(id)): \(error)")
        }
    }
    
    /// Entfernt einen Task aus dem Kalender
    func removeTaskFromCalendar(_ task: Task) async {
        guard let reminderID = task.externalReminderID else {
            return
        }
        
        do {
            try await calendarService.deleteReminder(id: reminderID)
            task.unlinkFromCalendar()
            try modelContext.save()
            print("✅ Removed reminder from calendar: \(task.title)")
        } catch {
            print("❌ Failed to remove reminder from calendar: \(error)")
        }
    }
    
    /// Synchronisiert alle Daily Focus Tasks
    func syncAllDailyFocusTasks() async {
        let tasks = fetchDailyFocusTasks()
        
        for task in tasks {
            await syncTaskToCalendar(task)
        }
    }
    
    // MARK: - Private Methods
    
    /// Handler für Kalender-Änderungen (Calendar → App)
    private func handleCalendarChanged() async {
        // Prüfe ob Kalender-Sync aktiviert ist
        guard AppSettings.shared.calendarSyncEnabled else {
            return
        }
        
        // Debouncing: Nicht zu oft synchronisieren
        let timeSinceLastSync = Date().timeIntervalSince(lastSyncDate)
        if timeSinceLastSync < debounceInterval {
            return
        }
        
        await syncFromCalendar()
    }
    
    /// Synchronisiert Änderungen vom Kalender zur App
    private func syncFromCalendar() async {
        // Prüfe ob Kalender-Sync aktiviert ist
        guard AppSettings.shared.calendarSyncEnabled else {
            return
        }
        
        guard !syncInProgress else { return }
        syncInProgress = true
        defer { syncInProgress = false }
        
        lastSyncDate = Date()
        
        let tasks = fetchDailyFocusTasks()
        
        for task in tasks {
            guard let reminderID = task.externalReminderID else {
                continue
            }
            
            do {
                guard let calendarReminder = try await calendarService.fetchReminder(id: reminderID) else {
                    // Reminder wurde im Kalender gelöscht
                    await handleReminderDeleted(task: task)
                    continue
                }
                
                // Prüfe auf Änderungen und löse Konflikte
                await resolveConflicts(task: task, calendarReminder: calendarReminder)
                
            } catch {
                print("❌ Failed to fetch reminder \(reminderID): \(error)")
            }
        }
        
        // Save Context
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save sync changes: \(error)")
        }
    }
    
    /// Löst Konflikte zwischen App und Kalender
    /// Strategie: Last-Write-Wins basierend auf Timestamps
    private func resolveConflicts(task: Task, calendarReminder: CalendarReminder) async {
        var hasChanges = false
        
        // Vergleiche Timestamps
        let calendarModDate = calendarReminder.modificationDate ?? Date.distantPast
        let taskModDate = task.modifiedAt
        
        // Calendar ist neuer = Calendar gewinnt
        let calendarIsNewer = calendarModDate > taskModDate
        
        // 1. Prüfe Completion-Status
        if calendarReminder.isCompleted != task.isCompleted {
            if calendarIsNewer {
                // Calendar sagt: completed
                if calendarReminder.isCompleted {
                    task.complete()
                    hasChanges = true
                    print("📥 Task marked as completed from calendar: \(task.title)")
                }
            } else {
                // App ist neuer, sync zu Calendar
                await syncTaskToCalendar(task)
            }
        }
        
        // 2. Prüfe Datum-Änderung
        if let calendarDueDate = calendarReminder.dueDate,
           let taskScheduledDate = task.scheduledDate {
            
            let calendar = Calendar.current
            let calendarDay = calendar.startOfDay(for: calendarDueDate)
            let taskDay = calendar.startOfDay(for: taskScheduledDate)
            
            if calendarDay != taskDay && calendarIsNewer {
                // User hat Datum im Kalender geändert
                // Task verlässt Daily Focus und wird für neues Datum geplant
                task.scheduleFor(date: calendarDueDate)
                hasChanges = true
                print("📥 Task rescheduled from calendar: \(task.title) to \(calendarDueDate)")
            }
        }
        
        // 3. Prüfe Titel-Änderung
        if calendarReminder.title != task.title && calendarIsNewer {
            task.title = calendarReminder.title
            hasChanges = true
            print("📥 Task title updated from calendar: \(task.title)")
        }
        
        // 4. Prüfe Notes-Änderung
        if calendarReminder.notes != task.notes && calendarIsNewer {
            task.notes = calendarReminder.notes
            hasChanges = true
            print("📥 Task notes updated from calendar")
        }
        
        if hasChanges {
            task.modifiedAt = Date()
        }
    }
    
    /// Handler wenn Reminder im Kalender gelöscht wurde
    private func handleReminderDeleted(task: Task) async {
        // MVP: Automatisch aus DailyFocus entfernen
        print("📥 Reminder deleted in calendar, moving task to backlog: \(task.title)")
        task.unlinkFromCalendar()
        task.resetToBacklog()
    }
    
    /// Holt alle Daily Focus Tasks aus dem Context
    private func fetchDailyFocusTasks() -> [Task] {
        let descriptor = FetchDescriptor<Task>()
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            // Filter manuell nach status (Predicates mit Enums funktionieren nicht gut)
            return allTasks.filter { $0.status == .dailyFocus }
        } catch {
            print("❌ Failed to fetch daily focus tasks: \(error)")
            return []
        }
    }
}

// MARK: - NotificationCenter Extension

extension NotificationCenter {
    func notifications(named name: Notification.Name) -> AsyncStream<Notification> {
        AsyncStream { continuation in
            let observer = addObserver(forName: name, object: nil, queue: nil) { notification in
                continuation.yield(notification)
            }
            
            continuation.onTermination = { _ in
                self.removeObserver(observer)
            }
        }
    }
}
