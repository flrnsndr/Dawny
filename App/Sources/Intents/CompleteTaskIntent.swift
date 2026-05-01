// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import SwiftData

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.complete.title"
    static var description = IntentDescription(
        "intent.complete.description",
        categoryName: "Tasks",
        searchKeywords: ["complete", "done", "finish", "mark", "task", "erledigen"]
    )
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

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try IntentDataStore.makeContext()
        let completedTask = try IntentDataStore.completeTask(taskID: task.id, in: context)
        let dialogFormat = String(
            localized: "intent.complete.dialog",
            defaultValue: "Done. '%@' is completed."
        )
        return .result(dialog: IntentDialog(stringLiteral: String(format: dialogFormat, completedTask.title)))
    }
}

