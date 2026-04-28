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

/// Intent zum Hinzufügen eines Tasks direkt zur Daily Focus Liste via Siri
struct AddTaskTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.addtasktoday.title"
    static var description = IntentDescription("intent.addtasktoday.description")
    
    // Öffnet die App nicht
    static var openAppWhenRun: Bool = false
    
    @Parameter(
        title: "intent.addtasktoday.param.title",
        description: "intent.addtasktoday.param.description",
        requestValueDialog: IntentDialog("intent.addtasktoday.requestvalue.title")
    )
    var taskTitle: String

    @Parameter(title: "intent.addtasktoday.param.category", description: "intent.addtasktoday.param.category.description")
    var category: CategoryAppEntity?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$taskTitle) to \(\.$category) for today")
    }
    
    @Dependency
    var dataStore: any TaskDataStoring

    @Dependency
    var syncEngine: SyncEngine

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let task = try dataStore.addTask(
            title: taskTitle,
            categoryID: category?.id,
            status: .dailyFocus
        )
        await syncEngine.syncTaskToCalendar(task)
        
        let dialogFormat = String(
            localized: "intent.addtasktoday.dialog",
            defaultValue: "Done. '%@' added to today."
        )
        let dialogText = String(format: dialogFormat, task.title)
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }
}

