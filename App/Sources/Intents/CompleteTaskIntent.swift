// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents

/// Intent zum Abschließen eines Tasks via Siri.
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.complete.title"
    static var description = IntentDescription("intent.complete.description")
    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "intent.complete.param.task",
        description: "intent.complete.param.task.description",
        requestValueDialog: IntentDialog("intent.complete.requestvalue.task")
    )
    var task: TaskAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$task) as done")
    }

    @Dependency
    var dataStore: any TaskDataStoring

    @Dependency
    var syncEngine: SyncEngine

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let completedTask = try dataStore.completeTask(taskID: task.id)
        await syncEngine.syncTaskToCalendar(completedTask)

        let dialogFormat = String(
            localized: "intent.complete.dialog",
            defaultValue: "Done. '%@' is completed."
        )
        let dialogText = String(format: dialogFormat, completedTask.title)
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }
}
