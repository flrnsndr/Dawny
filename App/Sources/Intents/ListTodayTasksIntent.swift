// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import SwiftData

struct ListTodayTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.listtoday.title"
    static var description = IntentDescription(
        "intent.listtoday.description",
        categoryName: "Tasks",
        searchKeywords: ["list", "today", "read", "what", "tasks", "focus"]
    )
    static var openAppWhenRun: Bool = false

    static var parameterSummary: some ParameterSummary {
        Summary("List today's tasks")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try IntentDataStore.makeContext()
        let tasks = try IntentDataStore.todayTasks(in: context)

        if tasks.isEmpty {
            let dialogText = String(
                localized: "intent.listtoday.dialog.empty",
                defaultValue: "There is nothing on your Today list."
            )
            return .result(dialog: IntentDialog(stringLiteral: dialogText))
        }

        let taskList = formattedTaskList(tasks)
        let dialogFormat = String(
            localized: "intent.listtoday.dialog",
            defaultValue: "Today: %@."
        )
        return .result(dialog: IntentDialog(stringLiteral: String(format: dialogFormat, taskList)))
    }

    private func formattedTaskList(_ tasks: [Task]) -> String {
        let visibleTasks = tasks.prefix(6).map(\.title)
        let list = ListFormatter.localizedString(byJoining: Array(visibleTasks))
        let remainingCount = tasks.count - visibleTasks.count

        guard remainingCount > 0 else {
            return list
        }

        let moreFormat = String(
            localized: "intent.listtoday.dialog.more",
            defaultValue: "%@, and %lld more"
        )
        return String(format: moreFormat, list, remainingCount)
    }
}

