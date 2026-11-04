// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  WidgetDataSource.swift
//  DawnyWidgets
//
//  Liest den geteilten SwiftData-Store (App Group) und baut die Wert-Snapshots
//  für die Timelines. STRIKT read-only: kein save(), kein initializeCategories.
//

import Foundation
import SwiftData

@MainActor
enum WidgetDataSource {

    /// True, wenn der geteilte Store nutzbar ist. Sonst zeigt das Widget „Öffne Dawny".
    nonisolated static var isAvailable: Bool { AppGroup.isMigrated }

    /// Konfigurierte Reset-Stunde aus der geteilten Suite (ohne MainActor lesbar).
    nonisolated static var resetHour: Int {
        AppGroup.defaults.object(forKey: AppSettings.Keys.resetHour) as? Int ?? 3
    }

    private static func context() throws -> ModelContext {
        try IntentDataStore.makeContext()
    }

    private static func allLiveTasks(in context: ModelContext) throws -> [Task] {
        try context.fetch(FetchDescriptor<Task>()).filter { !$0.isDeleted }
    }

    private static func plannerOutcome(for task: Task, referenceDate: Date) -> ResetOutcome {
        ResetOutcomePlanner.outcome(
            for: task.resetPlanInput,
            referenceDate: referenceDate,
            makeItCountThreshold: AppSettings.shared.makeItCountThreshold,
            calendar: .current
        )
    }

    // MARK: - Reset-Timing

    /// True, wenn die Reset-Schwelle überschritten ist, der Reset aber (App zu) noch nicht lief.
    static func isResetPending(now: Date) -> Bool {
        let lastReset = AppGroup.defaults.object(forKey: "DawnyLastResetDate") as? Date ?? .distantPast
        let threshold = ResetSchedule.lastThreshold(
            before: now, resetHour: AppSettings.shared.resetHour, calendar: .current
        )
        return lastReset < threshold
    }

    // MARK: - Heute

    static func todaySnapshot(now: Date) throws -> TodaySnapshot {
        let context = try context()
        let all = try allLiveTasks(in: context)
        let resetHour = AppSettings.shared.resetHour

        let open = all
            .filter { $0.status == .dailyFocus && !$0.isCompleted }
            .sorted { $0.sortPriority > $1.sortPriority }
            .map { task in
                WidgetTask(
                    id: task.id,
                    title: task.title,
                    isCompleted: false,
                    willArchiveAtNextReset: plannerOutcome(for: task, referenceDate: now) == .archive(.makeItCount)
                )
            }

        let completed = all
            .filter { $0.isCompletedToday }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .map { WidgetTask(id: $0.id, title: $0.title, isCompleted: true) }

        return TodaySnapshot(openTasks: open, completedTasks: completed, resetHour: resetHour)
    }

    // MARK: - Backlog

    /// - Parameter asIf: Wenn true, wird der Stand NACH dem fälligen Reset berechnet
    ///   (Auto-Tidy-Kandidaten raus, zurückkehrende Heute-Aufgaben rein).
    static func backlogSnapshot(now: Date, asIf: Bool) throws -> BacklogSnapshot {
        let context = try context()
        let all = try allLiveTasks(in: context)
        let categories = try context.fetch(
            FetchDescriptor<Category>(sortBy: [SortDescriptor(\.orderIndex)])
        )

        // Zurückkehrende Heute-Aufgaben nach Kategorie-ID gruppieren (nur im As-ob-Modus).
        var returningByCategory: [UUID: [Task]] = [:]
        if asIf {
            for task in all where task.status == .dailyFocus && !task.isCompleted {
                if case .returnToBacklog = plannerOutcome(for: task, referenceDate: now),
                   let categoryID = task.category?.id {
                    returningByCategory[categoryID, default: []].append(task)
                }
            }
        }

        var sections: [WidgetCategorySection] = []
        for category in categories {
            var backlogTasks = all.filter { $0.status == .inBacklog && $0.category?.id == category.id }

            if asIf {
                // Auto-Tidy-Kandidaten entfernen.
                backlogTasks.removeAll { plannerOutcome(for: $0, referenceDate: now) == .archive(.autoTidy) }
                // Zurückkehrende Heute-Aufgaben oben anfügen (Reset setzt sortPriority = now).
                backlogTasks = (returningByCategory[category.id] ?? []) + backlogTasks
            }

            backlogTasks.sort { $0.sortPriority > $1.sortPriority }
            guard !backlogTasks.isEmpty else { continue }

            let icon = category.displayIconName
            sections.append(
                WidgetCategorySection(
                    id: category.id,
                    name: category.displayName,
                    iconName: icon,
                    openCount: backlogTasks.count,
                    tasks: backlogTasks.map {
                        WidgetTask(id: $0.id, title: $0.title, categoryIconName: icon)
                    }
                )
            )
        }

        let storedIndex = AppGroup.defaults.integer(forKey: WidgetDefaultsKey.backlogCategoryIndex)
        let clampedIndex = sections.isEmpty ? 0 : max(0, min(storedIndex, sections.count - 1))
        return BacklogSnapshot(sections: sections, selectedSectionIndex: clampedIndex)
    }

    // MARK: - Archiv

    static func archiveSnapshot(now: Date, asIf: Bool) throws -> ArchiveSnapshot {
        let context = try context()
        let all = try allLiveTasks(in: context)
        let lastVisit = AppSettings.shared.lastArchiveVisitDate

        var tasks = all
            .filter { $0.status == .archived }
            .sorted { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) }
            .map { task in
                WidgetTask(
                    id: task.id,
                    title: task.title,
                    archivedAt: task.archivedAt,
                    isNew: task.isNewInArchive(since: lastVisit)
                )
            }

        if asIf {
            let threshold = ResetSchedule.lastThreshold(
                before: now, resetHour: AppSettings.shared.resetHour, calendar: .current
            )
            let predicted = all.compactMap { task -> WidgetTask? in
                guard case .archive = plannerOutcome(for: task, referenceDate: now) else { return nil }
                return WidgetTask(id: task.id, title: task.title, archivedAt: threshold, isNew: true)
            }
            tasks = predicted + tasks
        }

        return ArchiveSnapshot(tasks: tasks)
    }
}

/// Keys in den geteilten UserDefaults, die nur die Widgets betreffen.
enum WidgetDefaultsKey {
    static let backlogCategoryIndex = "DawnyWidgetBacklogCategoryIndex"
}
