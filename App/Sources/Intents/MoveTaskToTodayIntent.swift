// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import SwiftData

struct MoveTaskToTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.movetoday.title"
    static var description = IntentDescription(
        "intent.movetoday.description",
        categoryName: "Tasks",
        searchKeywords: ["move", "today", "focus", "schedule", "plan", "task"]
    )
    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "intent.movetoday.param.task",
        description: "intent.movetoday.param.task.description",
        requestValueDialog: IntentDialog("intent.movetoday.requestvalue.task")
    )
    var task: TaskAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Move \(\.$task) to today")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try IntentDataStore.makeContext()
        let movedTask = try IntentDataStore.moveTaskToToday(taskID: task.id, in: context)
        let dialogFormat = String(
            localized: "intent.movetoday.dialog",
            defaultValue: "Done. '%@' moved to today."
        )
        return .result(dialog: IntentDialog(stringLiteral: String(format: dialogFormat, movedTask.title)))
    }
}

