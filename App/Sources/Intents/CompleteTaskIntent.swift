// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import SwiftData

/// Intent zum Abschließen eines Tasks via Siri.
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.complete.title"
    static var description = IntentDescription("intent.complete.description")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "intent.complete.param.task", description: "intent.complete.param.task.description")
    var task: TaskAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$task) as done")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try IntentDataStore.makeContext()
        let completedTask = try IntentDataStore.completeTask(taskID: task.id, in: context)
        await IntentDataStore.syncTaskIfNeeded(completedTask, in: context)

        let dialogFormat = String(
            localized: "intent.complete.dialog",
            defaultValue: "Done. '%@' is completed."
        )
        let dialogText = String(format: dialogFormat, completedTask.title)
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }
}
