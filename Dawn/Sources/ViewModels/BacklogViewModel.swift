//
//  BacklogViewModel.swift
//  Dawn
//
//  ViewModel für Backlog-Management
//

import Foundation
import SwiftData
import Observation

@Observable
final class BacklogViewModel {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let syncEngine: SyncEngine
    
    var backlogs: [Backlog] = []
    var currentBacklog: Backlog?
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Initializer
    
    init(modelContext: ModelContext, syncEngine: SyncEngine) {
        self.modelContext = modelContext
        self.syncEngine = syncEngine
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
    func addTask(title: String, notes: String? = nil) {
        guard let backlog = currentBacklog else {
            errorMessage = "Kein Backlog ausgewählt"
            return
        }
        
        _ = backlog.addTask(title: title, notes: notes)
        
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
}
