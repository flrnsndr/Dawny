// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  AddTaskIntent.swift
//  Dawny
//
//  Siri Intent: "Hey Siri, füge X zu Dawny hinzu"
//

import AppIntents
import SwiftData

/// Intent zum Hinzufügen eines Tasks zum Backlog via Siri
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.addtask.title"
    static var description = IntentDescription("intent.addtask.description")
    
    // Öffnet die App nicht
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "intent.addtask.param.title", description: "intent.addtask.param.description")
    var taskTitle: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$taskTitle) to backlog")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // ModelContainer erstellen (gleiche Konfiguration wie in der App)
        let schema = Schema([Task.self, Backlog.self, Category.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        
        // Initialisiere Kategorien falls nötig
        let categoryService = CategoryService(modelContext: context)
        categoryService.initializeDefaultCategories()
        
        // Finde oder erstelle Default-Backlog
        let backlog = try findOrCreateBacklog(in: context)
        
        // Erstelle Task
        let task = Task(
            title: taskTitle,
            status: .inBacklog,
            parentBacklogID: backlog.id
        )
        task.backlog = backlog
        
        // Wenn Kategorien aktiviert sind, weise Standard-Kategorie zu
        let settings = AppSettings.shared
        if settings.showCategories {
            if let defaultCategory = categoryService.getCategory(type: settings.defaultCategoryType) {
                task.category = defaultCategory
            }
        }
        
        context.insert(task)
        
        try context.save()
        
        let dialogFormat = String(
            localized: "intent.addtask.dialog",
            defaultValue: "Done. '%@' added to your backlog."
        )
        let dialogText = String(format: dialogFormat, taskTitle)
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
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
        let backlogTitle = String(localized: "backlog.default.title", defaultValue: "Backlog")
        let newBacklog = Backlog(title: backlogTitle, orderIndex: 0)
        context.insert(newBacklog)
        try context.save()
        
        return newBacklog
    }
}

