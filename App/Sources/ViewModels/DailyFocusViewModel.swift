// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  DailyFocusViewModel.swift
//  Dawny
//
//  ViewModel für Daily Focus View
//

import Foundation
import SwiftData
import Observation
import SwiftUI

@Observable
final class DailyFocusViewModel {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let syncEngine: SyncEngine
    private let resetEngine: ResetEngine
    
    var dailyTasks: [Task] = []
    var isLoading = false
    var isSyncing = false
    var errorMessage: String?
    var lastSyncDate: Date?
    
    // MARK: - Initializer
    
    init(modelContext: ModelContext, syncEngine: SyncEngine, resetEngine: ResetEngine) {
        self.modelContext = modelContext
        self.syncEngine = syncEngine
        self.resetEngine = resetEngine
        loadDailyTasks()
    }
    
    // MARK: - Task Loading
    
    /// Leert die angezeigte Liste sofort (z. B. vor Debug-Massenlöschen), damit kein `TaskRowView` noch auf Task-Objekte zeigt.
    func clearTasksFromDisplayOnly() {
        dailyTasks = []
    }
    
    /// Liefert einen frischen `Task` aus dem aktuellen Kontext (wichtig nach
    /// Löschungen / Saves, damit kein abgelöstes `PersistentModel` verwendet wird).
    private func task(withID id: UUID) -> Task? {
        var descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    /// Lädt alle Daily Focus Tasks für heute
    func loadDailyTasks() {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.sortPriority, order: .reverse)]
        )
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            let settings = AppSettings.shared
            
            var tasks = allTasks.filter { $0.status == .dailyFocus }
            
            if settings.showCompletedTasksInToday {
                let completedToday = allTasks.filter { $0.isCompletedToday }
                tasks.append(contentsOf: completedToday)
            }
            
            dailyTasks = tasks
        } catch {
            let format = String(
                localized: "error.daily_focus.load_tasks",
                defaultValue: "Failed to load tasks: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Aktualisiert die Task-Liste (Pull-to-Refresh)
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        await resetEngine.checkAndPerformResetIfNeeded()
        await syncWithCalendar()
        loadDailyTasks()
    }
    
    // MARK: - Task Actions
    
    /// Markiert einen Task als abgeschlossen
    func completeTask(_ task: Task) async {
        await completeTask(taskID: task.id)
    }

    /// Wie `completeTask(_:)`, aber nur mit UUID – holt den Task immer frisch aus dem
    /// `ModelContext` (vermeidet abgelöste Referenzen aus `ForEach`-Closures).
    ///
    /// Calendar-Sync erst **nach** `save()` + `loadDailyTasks()`, damit kein
    /// `await`-Yield SwiftUI die Chance gibt, mit veralteten Referenzen zu rendern.
    func completeTask(taskID: UUID) async {
        guard let t = self.task(withID: taskID) else { return }
        let wasRecurring = t.isRecurring

        t.complete()

        if wasRecurring {
            let clone = Task(
                title: t.title,
                notes: t.notes,
                status: .inBacklog,
                parentBacklogID: t.parentBacklogID,
                sortPriority: Date(),
                category: t.category
            )
            clone.backlog = t.backlog
            if clone.backlog == nil {
                let parentID = t.parentBacklogID
                var backlogDescriptor = FetchDescriptor<Backlog>(predicate: #Predicate<Backlog> { $0.id == parentID })
                backlogDescriptor.fetchLimit = 1
                if let backlog = try? modelContext.fetch(backlogDescriptor).first {
                    clone.backlog = backlog
                }
            }
            modelContext.insert(clone)
            t.recurringCloneID = clone.id
        }

        let needsCalendarSync = t.isSyncedToCalendar
        let taskID = t.id

        do {
            try modelContext.save()
            loadDailyTasks()
        } catch {
            let format = String(
                localized: "error.daily_focus.complete_task",
                defaultValue: "Failed to complete task: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
            return
        }

        if needsCalendarSync, let fresh = self.task(withID: taskID) {
            await syncEngine.syncTaskToCalendar(fresh)
        }
    }

    /// Markiert einen erledigten Task wieder als offen
    func uncompleteTask(_ task: Task) async {
        await uncompleteTask(taskID: task.id)
    }

    /// Erledigten Task wieder öffnen.
    ///
    /// Clone-Delete + Parent-Änderung in **einem** `save()`,
    /// `loadDailyTasks()` **sofort** danach (kein `await` dazwischen).
    /// Calendar-Sync erst NACH dem UI-Refresh.
    func uncompleteTask(taskID: UUID) async {
        guard let task = self.task(withID: taskID) else { return }

        if let cloneID = task.recurringCloneID, let clone = self.task(withID: cloneID) {
            modelContext.delete(clone)
        }

        task.recurringCloneID = nil
        task.isCompleted = false
        task.status = .dailyFocus
        task.modifiedAt = Date()

        let needsCalendarSync = task.isSyncedToCalendar

        do {
            try modelContext.save()
            loadDailyTasks()
            HapticFeedback.success()
        } catch {
            let format = String(
                localized: "error.daily_focus.uncomplete_task",
                defaultValue: "Failed to reopen task: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
            return
        }

        if needsCalendarSync, let fresh = self.task(withID: taskID) {
            await syncEngine.syncTaskToCalendar(fresh)
        }
    }
    
    /// Entfernt einen Task aus Daily Focus zurück ins Backlog
    func removeFromDailyFocus(_ task: Task) async {
        let needsCalendarRemove = task.isSyncedToCalendar
        let taskID = task.id

        task.resetToBacklog()
        
        do {
            try modelContext.save()
            loadDailyTasks()
        } catch {
            let format = String(
                localized: "error.daily_focus.remove_from_today",
                defaultValue: "Failed to remove task from today: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
            return
        }

        if needsCalendarRemove, let fresh = self.task(withID: taskID) {
            await syncEngine.removeTaskFromCalendar(fresh)
        }
    }
    
    /// Löscht einen Task komplett
    func deleteTask(_ task: Task) async {
        if task.isSyncedToCalendar {
            await syncEngine.removeTaskFromCalendar(task)
        }
        
        modelContext.delete(task)
        
        do {
            try modelContext.save()
            loadDailyTasks()
        } catch {
            let format = String(
                localized: "error.daily_focus.delete_task",
                defaultValue: "Failed to delete task: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Verschiebt Tasks innerhalb der offenen Tasks (Drag & Drop)
    func moveTasks(from source: IndexSet, to destination: Int) {
        var tasks = openTasks
        guard !source.isEmpty else { return }
        
        var itemsToMove: [Task] = []
        let sortedIndices = source.sorted(by: >)
        for index in sortedIndices {
            itemsToMove.insert(tasks.remove(at: index), at: 0)
        }
        let maxSourceIndex = sortedIndices.last!
        let insertIndex = destination > maxSourceIndex ? destination - itemsToMove.count : destination
        for (index, item) in itemsToMove.enumerated() {
            tasks.insert(item, at: insertIndex + index)
        }
        
        let base = Date()
        for (index, task) in tasks.enumerated() {
            task.sortPriority = base.addingTimeInterval(-Double(index) * 0.001)
            task.modifiedAt = Date()
        }
        
        do {
            try modelContext.save()
            let completed = dailyTasks.filter(\.isCompleted)
            dailyTasks = tasks + completed
            HapticFeedback.light()
        } catch {
            let format = String(
                localized: "error.daily_focus.reorder_tasks",
                defaultValue: "Failed to reorder tasks: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Aktualisiert einen Task
    func updateTask(_ task: Task, title: String, notes: String?) async {
        task.title = title
        task.notes = notes
        task.modifiedAt = Date()
        
        if task.isSyncedToCalendar {
            await syncEngine.syncTaskToCalendar(task)
        }
        
        do {
            try modelContext.save()
        } catch {
            let format = String(
                localized: "error.daily_focus.update_task",
                defaultValue: "Failed to update task: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    // MARK: - Sync
    
    /// Synchronisiert mit dem Kalender
    func syncWithCalendar() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        await syncEngine.syncAllDailyFocusTasks()
        lastSyncDate = Date()
    }
    
    // MARK: - Computed Properties
    
    var openTaskCount: Int {
        dailyTasks.filter { !$0.isCompleted }.count
    }
    
    var completedTaskCount: Int {
        dailyTasks.filter { $0.isCompleted }.count
    }
    
    var progressPercentage: Double {
        guard !dailyTasks.isEmpty else { return 0 }
        return Double(completedTaskCount) / Double(dailyTasks.count)
    }
    
    var openTasks: [Task] {
        dailyTasks.filter { !$0.isCompleted }
    }
    
    var completedTasks: [Task] {
        dailyTasks.filter { $0.isCompleted }
    }
}
