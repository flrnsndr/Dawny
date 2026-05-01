// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import SwiftData

struct AddTaskTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.addtasktoday.title"
    static var description = IntentDescription(
        "intent.addtasktoday.description",
        categoryName: "Tasks",
        searchKeywords: ["add", "today", "focus", "task", "now", "daily"]
    )
    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "intent.addtasktoday.param.title",
        description: "intent.addtasktoday.param.description",
        requestValueDialog: IntentDialog("intent.addtasktoday.requestvalue.title")
    )
    var title: String

    @Parameter(title: "intent.addtasktoday.param.category", description: "intent.addtasktoday.param.category.description")
    var category: CategoryAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) to \(\.$category) for today")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try IntentDataStore.makeContext()
        let task = try IntentDataStore.addTask(
            title: title,
            categoryID: category?.id,
            status: .dailyFocus,
            in: context
        )
        let dialogFormat = String(
            localized: "intent.addtasktoday.dialog",
            defaultValue: "Done. '%@' added to today."
        )
        return .result(dialog: IntentDialog(stringLiteral: String(format: dialogFormat, task.title)))
    }
}

