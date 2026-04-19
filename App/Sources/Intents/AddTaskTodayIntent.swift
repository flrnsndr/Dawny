// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  AddTaskTodayIntent.swift
//  Dawny
//
//  Siri Intent: "Hey Siri, füge X heute zu Dawny hinzu"
//

import AppIntents
import SwiftData

/// Intent zum Hinzufügen eines Tasks direkt zur Daily Focus Liste via Siri
struct AddTaskTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.addtasktoday.title"
    static var description = IntentDescription("intent.addtasktoday.description")
    
    // Öffnet die App nicht
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "intent.addtasktoday.param.title", description: "intent.addtasktoday.param.description")
    var taskTitle: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$taskTitle) to today")
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
            status: .dailyFocus,
            parentBacklogID: backlog.id,
            scheduledDate: Calendar.current.startOfDay(for: Date())
        )
        task.backlog = backlog
        context.insert(task)
        
        try context.save()
        
        let dialogFormat = String(
            localized: "intent.addtasktoday.dialog",
            defaultValue: "Done. '%@' added to today."
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

