// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents

/// Intent zum Vorlesen der heutigen offenen Tasks.
struct ListTodayTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.listtoday.title"
    static var description = IntentDescription("intent.listtoday.description")
    static var openAppWhenRun: Bool = false

    static var parameterSummary: some ParameterSummary {
        Summary("List today's tasks")
    }

    @Dependency
    var dataStore: any TaskDataStoring

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let tasks = try dataStore.todayTasks()

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
        let dialogText = String(format: dialogFormat, taskList)
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
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
