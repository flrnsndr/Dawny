//
//  UITestWorkflowRunner.swift
//  Dawny
//
//  Nur DEBUG: legt Testtasks an und verschiebt pro Kategorie einen Task nach „Heute“.
//

#if DEBUG

import Foundation

@MainActor
enum UITestWorkflowRunner {
    /// Führt den Standard-UI-Testworkflow aus (Kategorien müssen in den Einstellungen aktiv sein).
    static func run(
        backlogViewModel: BacklogViewModel,
        dailyFocusViewModel: DailyFocusViewModel?,
        settings: AppSettings,
        selectTodayTab: @escaping () -> Void
    ) async {
        guard settings.showCategories else { return }

        backlogViewModel.loadCategories()

        let defaultType = settings.defaultCategoryType
        guard let defaultCategory = backlogViewModel.categories.first(where: { $0.categoryType == defaultType }) else {
            return
        }

        /// Fortlaufende Nummer nur für diese Workflow-Befüllung – eindeutige Titel (kein doppeltes „Testtask 4 …“).
        var workflowTitleIndex = 1

        for _ in 1...3 {
            backlogViewModel.addTask(
                title: "Testtask \(workflowTitleIndex) Standardkategorie",
                notes: nil,
                category: defaultCategory
            )
            workflowTitleIndex += 1
        }

        let otherTypes = TaskCategory.allCases.filter { $0 != .uncategorized && $0 != defaultType }
        for categoryType in otherTypes {
            guard let category = backlogViewModel.categories.first(where: { $0.categoryType == categoryType }) else {
                continue
            }
            let label = category.name
            backlogViewModel.addTask(
                title: "Testtask \(workflowTitleIndex) \(label)",
                notes: nil,
                category: category
            )
            workflowTitleIndex += 1
            backlogViewModel.addTask(
                title: "Testtask \(workflowTitleIndex) \(label)",
                notes: nil,
                category: category
            )
            workflowTitleIndex += 1
        }

        backlogViewModel.loadCategories()

        // Pro Kategorie (mit mindestens einem Backlog-Task) einen Task nach „Heute“.
        for category in backlogViewModel.categories.sorted() {
            let candidates = backlogViewModel.getTasksForCategory(category).sorted()
            guard let taskToMove = candidates.first else { continue }
            await backlogViewModel.moveTaskToDailyFocus(taskToMove)
        }

        dailyFocusViewModel?.loadDailyTasks()
        selectTodayTab()
    }
}

#endif
