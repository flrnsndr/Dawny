//
//  DailyFocusViewModel.swift
//  Dawn
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
    
    /// Lädt alle Daily Focus Tasks für heute
    func loadDailyTasks() {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.sortPriority, order: .reverse)]
        )
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            // Filter manuell nach Status
            dailyTasks = allTasks.filter { $0.status == .dailyFocus }
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
        // Arbeite mit einer Kopie der offenen Tasks
        var tasks = openTasks
        tasks.move(fromOffsets: source, toOffset: destination)
        
        // Aktualisiere sortPriority basierend auf neuer Reihenfolge
        // Neuere Dates = höhere Priorität, also setzen wir sie absteigend
        let now = Date()
        for (index, task) in tasks.enumerated() {
            // Nutze negative Zeitintervalle für absteigende Sortierung
            task.sortPriority = now.addingTimeInterval(Double(-index))
            task.modifiedAt = Date()
        }
        
        do {
            try modelContext.save()
            loadDailyTasks()
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
