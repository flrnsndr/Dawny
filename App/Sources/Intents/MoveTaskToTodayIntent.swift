// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import SwiftData

/// Intent zum Verschieben eines Backlog-Tasks in die heutige Fokusliste.
struct MoveTaskToTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.movetoday.title"
    static var description = IntentDescription("intent.movetoday.description")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "intent.movetoday.param.task", description: "intent.movetoday.param.task.description")
    var task: TaskAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Move \(\.$task) to today")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try IntentDataStore.makeContext()
        let movedTask = try IntentDataStore.moveTaskToToday(taskID: task.id, in: context)
        await IntentDataStore.syncTaskIfNeeded(movedTask, in: context)

        let dialogFormat = String(
            localized: "intent.movetoday.dialog",
            defaultValue: "Done. '%@' moved to today."
        )
        let dialogText = String(format: dialogFormat, movedTask.title)
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }
}
