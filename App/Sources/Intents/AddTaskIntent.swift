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

/// Intent zum Hinzufügen eines Tasks zum Backlog via Siri
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.addtask.title"
    static var description = IntentDescription("intent.addtask.description")
    
    // Öffnet die App nicht
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "intent.addtask.param.title", description: "intent.addtask.param.description")
    var taskTitle: String

    @Parameter(title: "intent.addtask.param.category", description: "intent.addtask.param.category.description")
    var category: CategoryAppEntity?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$taskTitle) to \(\.$category) in backlog")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try IntentDataStore.makeContext()
        let task = try IntentDataStore.addTask(
            title: taskTitle,
            categoryID: category?.id,
            status: .inBacklog,
            in: context
        )
        
        let dialogFormat = String(
            localized: "intent.addtask.dialog",
            defaultValue: "Done. '%@' added to your backlog."
        )
        let dialogText = String(format: dialogFormat, task.title)
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }
}

