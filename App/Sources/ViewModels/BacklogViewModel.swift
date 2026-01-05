//
//  BacklogViewModel.swift
//  Dawny
//
//  ViewModel für Backlog-Management
//

import Foundation
import SwiftData
import SwiftUI
import Observation

@Observable
final class BacklogViewModel {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let syncEngine: SyncEngine
    let settings: AppSettings
    
    var backlogs: [Backlog] = []
    var currentBacklog: Backlog?
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Initializer
    
    init(modelContext: ModelContext, syncEngine: SyncEngine, settings: AppSettings = .shared) {
        self.modelContext = modelContext
        self.syncEngine = syncEngine
        self.settings = settings
        loadBacklogs()
    }
    
    // MARK: - Backlog Management
    
    /// Lädt alle Backlogs
    func loadBacklogs() {
        let descriptor = FetchDescriptor<Backlog>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        
        do {
            backlogs = try modelContext.fetch(descriptor)
            
            // Setze ersten Backlog als current falls keiner gesetzt
            if currentBacklog == nil {
                currentBacklog = backlogs.first
            }
            
            // Falls keine Backlogs existieren, erstelle Default-Backlog
            if backlogs.isEmpty {
                createDefaultBacklog()
            }
        } catch {
            errorMessage = "Fehler beim Laden der Backlogs: \(error.localizedDescription)"
        }
    }
    
    /// Erstellt einen neuen Backlog
    func createBacklog(title: String) {
        let backlog = Backlog(
            title: title,
            orderIndex: backlogs.count
        )
        
        modelContext.insert(backlog)
        
        do {
            try modelContext.save()
            backlogs.append(backlog)
            
            if currentBacklog == nil {
                currentBacklog = backlog
            }
        } catch {
            errorMessage = "Fehler beim Erstellen des Backlogs: \(error.localizedDescription)"
        }
    }
    
    /// Erstellt den Default-Backlog beim ersten Start
    private func createDefaultBacklog() {
        createBacklog(title: "Backlog")
    }
    
    /// Löscht einen Backlog
    func deleteBacklog(_ backlog: Backlog) {
        modelContext.delete(backlog)
        
        do {
            try modelContext.save()
            loadBacklogs()
        } catch {
            errorMessage = "Fehler beim Löschen des Backlogs: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Task Management
    
    /// Fügt einen neuen Task zum aktuellen Backlog hinzu
    func addTask(title: String, notes: String? = nil, category: TaskCategory? = nil) {
        guard let backlog = currentBacklog else {
            errorMessage = "Kein Backlog ausgewählt"
            return
        }
        
        // Bestimme die Kategorie basierend auf Einstellungen
        let taskCategory: TaskCategory?
        if let explicitCategory = category {
            taskCategory = explicitCategory
        } else if settings.showCategories {
            taskCategory = settings.defaultCategory
        } else {
            taskCategory = nil
        }
        
        // Ermittle den nächsten categoryOrderIndex
        let tasksInCategory = tasksByCategory[taskCategory ?? .uncategorized] ?? []
        let maxOrderIndex = tasksInCategory.map { $0.categoryOrderIndex }.max() ?? -1
        
        let task = backlog.addTask(title: title, notes: notes)
        task.category = taskCategory
        task.categoryOrderIndex = maxOrderIndex + 1
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Fehler beim Erstellen des Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Löscht einen Task
    func deleteTask(_ task: Task) async {
        // Falls Task im Kalender, entfernen
        if task.isSyncedToCalendar {
            await syncEngine.removeTaskFromCalendar(task)
        }
        
        modelContext.delete(task)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Fehler beim Löschen des Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Markiert einen Task als abgeschlossen
    func completeTask(_ task: Task) async {
        task.complete()
        
        // Sync zu Kalender falls verbunden
        if task.isSyncedToCalendar {
            await syncEngine.syncTaskToCalendar(task)
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Fehler beim Abschließen des Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Verschiebt einen Task zu Daily Focus
    func moveTaskToDailyFocus(_ task: Task) async {
        let today = Calendar.current.startOfDay(for: Date())
        task.moveToDailyFocus(date: today)
        
        // Sync zu Kalender
        await syncEngine.syncTaskToCalendar(task)
        
        do {
            try modelContext.save()
            // Aktualisiere Backlog-Liste damit der Task verschwindet
            loadBacklogs()
        } catch {
            errorMessage = "Fehler beim Verschieben des Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Aktualisiert einen Task
    func updateTask(_ task: Task, title: String, notes: String?) async {
        task.title = title
        task.notes = notes
        task.modifiedAt = Date()
        
        // Sync zu Kalender falls verbunden
        if task.isSyncedToCalendar {
            await syncEngine.syncTaskToCalendar(task)
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Fehler beim Aktualisieren des Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Verschiebt Task zurück ins Backlog
    func moveTaskToBacklog(_ task: Task) async {
        // Entferne aus Kalender falls synchronisiert
        if task.isSyncedToCalendar {
            await syncEngine.removeTaskFromCalendar(task)
        }
        
        task.resetToBacklog()
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Fehler beim Verschieben des Tasks: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    /// Alle Tasks im aktuellen Backlog
    var backlogTasks: [Task] {
        currentBacklog?.backlogTasks ?? []
    }
    
    /// Anzahl der Tasks im Backlog
    var taskCount: Int {
        currentBacklog?.taskCount ?? 0
    }
    
    // MARK: - Category Management
    
    /// Tasks gruppiert nach Kategorie (sortiert)
    var tasksByCategory: [TaskCategory: [Task]] {
        var result: [TaskCategory: [Task]] = [:]
        
        for task in backlogTasks {
            let category = task.category ?? .uncategorized
            if result[category] == nil {
                result[category] = []
            }
            result[category]?.append(task)
        }
        
        // Sortiere Tasks innerhalb jeder Kategorie nach categoryOrderIndex
        for category in result.keys {
            result[category]?.sort { $0.categoryOrderIndex < $1.categoryOrderIndex }
        }
        
        return result
    }
    
    /// Alle Kategorien die angezeigt werden sollen (sortiert)
    var visibleCategories: [TaskCategory] {
        let allCategories = TaskCategory.sorted
        
        return allCategories.filter { category in
            // Unkategorisiert nur zeigen wenn Tasks vorhanden
            if category == .uncategorized {
                return (tasksByCategory[category]?.isEmpty == false)
            }
            // Andere Kategorien immer zeigen
            return true
        }
    }
    
    /// Verschiebt einen Task in eine andere Kategorie
    func moveTask(_ task: Task, toCategory category: TaskCategory) {
        let targetCategory = category == .uncategorized ? nil : category
        task.category = targetCategory
        task.modifiedAt = Date()
        
        // Setze categoryOrderIndex ans Ende der Zielkategorie
        let tasksInCategory = tasksByCategory[category] ?? []
        let maxOrderIndex = tasksInCategory.map { $0.categoryOrderIndex }.max() ?? -1
        task.categoryOrderIndex = maxOrderIndex + 1
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Fehler beim Verschieben des Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Ordnet Tasks innerhalb einer Kategorie neu an
    func reorderTasks(in category: TaskCategory, fromOffsets source: IndexSet, toOffset destination: Int) {
        guard var tasks = tasksByCategory[category] else { return }
        
        tasks.move(fromOffsets: source, toOffset: destination)
        
        // Aktualisiere categoryOrderIndex für alle Tasks in dieser Kategorie
        for (index, task) in tasks.enumerated() {
            task.categoryOrderIndex = index
            task.modifiedAt = Date()
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Fehler beim Neuordnen der Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Migriert bestehende Tasks ohne Kategorie zu "Unkategorisiert"
    /// Wird aufgerufen wenn Kategorien zum ersten Mal aktiviert werden
    func migrateUncategorizedTasks() {
        let tasksWithoutCategory = backlogTasks.filter { $0.category == nil }
        
        // Diese bleiben auf nil (= uncategorized), werden aber in der UI als "Unkategorisiert" angezeigt
        // Nichts zu tun - die Logik behandelt nil als .uncategorized
        
        if !tasksWithoutCategory.isEmpty {
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Fehler bei der Migration: \(error.localizedDescription)"
            }
        }
    }
}
