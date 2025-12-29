//
//  AddTaskIntent.swift
//  Dawn
//
//  Siri Intent: "Hey Siri, füge X zu Dawn hinzu"
//

import AppIntents
import SwiftData

/// Intent zum Hinzufügen eines Tasks zum Backlog via Siri
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Task zu Dawn hinzufügen"
    static var description = IntentDescription("Fügt einen neuen Task zum Backlog hinzu")
    
    // Öffnet die App nicht
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Task-Titel", description: "Der Name des Tasks")
    var taskTitle: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Füge \(\.$taskTitle) hinzu")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // ModelContainer erstellen (gleiche Konfiguration wie in der App)
        let schema = Schema([Task.self, Backlog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        
        // Finde oder erstelle Default-Backlog
        let backlog = try findOrCreateBacklog(in: context)
        
        // Erstelle Task
        let task = Task(
            title: taskTitle,
            status: .inBacklog,
            parentBacklogID: backlog.id
        )
        task.backlog = backlog
        context.insert(task)
        
        try context.save()
        
        return .result(dialog: "Erledigt! '\(taskTitle)' wurde zum Backlog hinzugefügt.")
    }
    
    /// Findet den Default-Backlog oder erstellt einen neuen
    @MainActor
    private func findOrCreateBacklog(in context: ModelContext) throws -> Backlog {
        let descriptor = FetchDescriptor<Backlog>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        
        let backlogs = try context.fetch(descriptor)
        
        if let existingBacklog = backlogs.first {
            return existingBacklog
        }
        
        // Erstelle neuen Default-Backlog
        let newBacklog = Backlog(title: "Backlog", orderIndex: 0)
        context.insert(newBacklog)
        try context.save()
        
        return newBacklog
    }
}

