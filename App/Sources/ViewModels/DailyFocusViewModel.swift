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
    
    /// Leert die angezeigte Liste sofort (z. B. vor Debug-Massenlöschen), damit kein `TaskRowView` noch auf Task-Objekte zeigt.
    func clearTasksFromDisplayOnly() {
        dailyTasks = []
    }
    
    /// Lädt alle Daily Focus Tasks für heute
    func loadDailyTasks() {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.sortPriority, order: .reverse)]
        )
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            let settings = AppSettings.shared
            
            // Filter: Aktive Daily Focus Tasks
            var tasks = allTasks.filter { $0.status == .dailyFocus }
            
            // Füge erledigte Tasks hinzu, wenn Einstellung aktiviert ist
            if settings.showCompletedTasksInToday {
                let completedToday = allTasks.filter { $0.isCompletedToday }
                tasks.append(contentsOf: completedToday)
            }
            
            dailyTasks = tasks
        } catch {
            errorMessage = "Fehler beim Laden der Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Aktualisiert die Task-Liste (Pull-to-Refresh)
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        // Prüfe ob Reset nötig
        await resetEngine.checkAndPerformResetIfNeeded()
        
        // Sync mit Kalender
        await syncWithCalendar()
        
        // Reload Tasks
        loadDailyTasks()
    }
    
    // MARK: - Task Actions
    
    /// Markiert einen Task als abgeschlossen
    func completeTask(_ task: Task) async {
        task.complete()
        
        // Sync zu Kalender
        if task.isSyncedToCalendar {
            await syncEngine.syncTaskToCalendar(task)
        }
        
        do {
            try modelContext.save()
            loadDailyTasks()
        } catch {
            errorMessage = "Fehler beim Abschließen des Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Markiert einen erledigten Task wieder als offen
    func uncompleteTask(_ task: Task) async {
        task.isCompleted = false
        task.status = .dailyFocus
        task.modifiedAt = Date()
        
        // Sync zu Kalender falls vorher synchronisiert
        if task.isSyncedToCalendar {
            await syncEngine.syncTaskToCalendar(task)
        }
        
        do {
            try modelContext.save()
            loadDailyTasks()
            HapticFeedback.success()
        } catch {
            errorMessage = "Fehler beim Wiedereröffnen des Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Entfernt einen Task aus Daily Focus zurück ins Backlog
    func removeFromDailyFocus(_ task: Task) async {
        // Entferne aus Kalender
        if task.isSyncedToCalendar {
            await syncEngine.removeTaskFromCalendar(task)
        }
        
        task.resetToBacklog()
        
        do {
            try modelContext.save()
            loadDailyTasks()
        } catch {
            errorMessage = "Fehler beim Entfernen des Tasks: \(error.localizedDescription)"
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
            errorMessage = "Fehler beim Löschen des Tasks: \(error.localizedDescription)"
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
            errorMessage = "Fehler beim Sortieren der Tasks: \(error.localizedDescription)"
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
            errorMessage = "Fehler beim Aktualisieren des Tasks: \(error.localizedDescription)"
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
    
    /// Anzahl der noch offenen Tasks
    var openTaskCount: Int {
        dailyTasks.filter { !$0.isCompleted }.count
    }
    
    /// Anzahl der abgeschlossenen Tasks
    var completedTaskCount: Int {
        dailyTasks.filter { $0.isCompleted }.count
    }
    
    /// Fortschritt in Prozent
    var progressPercentage: Double {
        guard !dailyTasks.isEmpty else { return 0 }
        return Double(completedTaskCount) / Double(dailyTasks.count)
    }
    
    /// Offene Tasks
    var openTasks: [Task] {
        dailyTasks.filter { !$0.isCompleted }
    }
    
    /// Abgeschlossene Tasks
    var completedTasks: [Task] {
        dailyTasks.filter { $0.isCompleted }
    }
}
