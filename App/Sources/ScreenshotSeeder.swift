// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ScreenshotSeeder.swift
//  Dawny
//
//  Seeds deterministic SwiftData content when the app is launched with the
//  `--screenshots` argument. Used exclusively by the App Store screenshot
//  workflow (scripts/take-screenshots.sh + DawnyUITests/ScreenshotTests).
//

#if DEBUG
import Foundation
import SwiftData

enum ScreenshotSeeder {
    /// Erkennt, ob die App im Screenshot-Modus läuft.
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshots")
    }

    /// Synchronously prepares AppSettings before any view appears. Must be called
    /// from `DawnyApp.init()` so the Welcome cover does not present.
    static func prepareForLaunch() {
        AppSettings.shared.hasSeenWelcome = true
        AppSettings.shared.calendarSyncEnabled = false
        AppSettings.shared.showCategories = true
        AppSettings.shared.showCompletedTasksInToday = true
        AppSettings.shared.hasNewArchivedTasks = false
    }

    /// Wipes existing tasks and seeds the deterministic content used in the App Store screenshots.
    /// Must run after `CategoryService.initializeDefaultCategories()` so categories exist.
    static func seed(into context: ModelContext) {
        // Bundle.preferredLocalizations follows AppleLanguages directly, so seed
        // content matches whatever the UI is rendering. Locale.current can lag
        // behind AppleLanguages launch overrides.
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        let isGerman = preferred.hasPrefix("de")

        do {
            let existing = try context.fetch(FetchDescriptor<Task>())
            for task in existing {
                context.delete(task)
            }

            let backlog = try fetchOrCreateBacklog(in: context)
            let categories = try context.fetch(FetchDescriptor<Category>())

            func category(_ type: TaskCategory) -> Category? {
                categories.first { $0.categoryType == type }
            }

            let recurring = categories.first(where: { $0.isRecurring })

            seedBacklog(backlog: backlog, category: category, isGerman: isGerman, in: context)
            seedRecurring(backlog: backlog, recurring: recurring, isGerman: isGerman, in: context)
            seedToday(backlog: backlog, isGerman: isGerman, in: context)
            seedArchive(backlog: backlog, isGerman: isGerman, in: context)

            try context.save()
        } catch {
            print("⚠️ ScreenshotSeeder failed: \(error)")
        }
    }

    // MARK: - Backlog

    private static func seedBacklog(
        backlog: Backlog,
        category: (TaskCategory) -> Category?,
        isGerman: Bool,
        in context: ModelContext
    ) {
        let items: [(String, TaskCategory)] = isGerman ? [
            ("Konzerttickets kaufen 🎫", .quick),
            ("Toms Nachricht beantworten 💬", .nextFewDays),
            ("Rezept abholen", .nextFewDays),
            ("Geburtstagsessen buchen 🎂", .nextFewWeeks),
            ("Neue Bilder einrahmen 🖼️", .nextFewWeeks),
            ("Sommerurlaub planen ☀️", .nextFewMonths),
            ("Reisepass verlängern", .nextFewMonths),
            ("Neuen Kühlschrank kaufen", .nextFewMonths)
        ] : [
            ("Get concert tickets 🎫", .quick),
            ("Reply to Tom's message 💬", .nextFewDays),
            ("Pick up prescription", .nextFewDays),
            ("Book birthday dinner 🎂", .nextFewWeeks),
            ("Frame and hang new pictures 🖼️", .nextFewWeeks),
            ("Plan summer vacation ☀️", .nextFewMonths),
            ("Renew passport", .nextFewMonths),
            ("Buy a new fridge", .nextFewMonths)
        ]

        for (index, item) in items.enumerated() {
            let task = Task(
                title: item.0,
                status: .inBacklog,
                parentBacklogID: backlog.id,
                sortPriority: Date().addingTimeInterval(TimeInterval(-index)),
                category: category(item.1)
            )
            task.backlog = backlog
            context.insert(task)
        }
    }

    // MARK: - Recurring

    private static func seedRecurring(
        backlog: Backlog,
        recurring: Category?,
        isGerman: Bool,
        in context: ModelContext
    ) {
        guard let recurring else { return }
        let titles = isGerman
            ? ["Haus putzen", "15 Min Dehnen"]
            : ["Clean the house", "15 min stretch break"]

        for (index, title) in titles.enumerated() {
            let task = Task(
                title: title,
                status: .inBacklog,
                parentBacklogID: backlog.id,
                sortPriority: Date().addingTimeInterval(TimeInterval(-100 - index)),
                category: recurring
            )
            task.backlog = backlog
            context.insert(task)
        }
    }

    // MARK: - Today

    private static func seedToday(backlog: Backlog, isGerman: Bool, in context: ModelContext) {
        let openTitle = isGerman ? "Keller aufräumen 🏠" : "Clean basement 🏠"
        let open = Task(
            title: openTitle,
            status: .dailyFocus,
            parentBacklogID: backlog.id,
            scheduledDate: Date()
        )
        open.backlog = backlog
        context.insert(open)

        let completedTitles = isGerman ? [
            "Auto zur Inspektion bringen 🚗",
            "Paket abholen 📦",
            "Einkaufen gehen 🛒",
            "Mit dem Hund rausgehen 🐕"
        ] : [
            "Take car in for inspection 🚗",
            "Pick up package 📦",
            "Get groceries 🛒",
            "Walk the dog 🐕"
        ]

        let now = Date()
        for (index, title) in completedTitles.enumerated() {
            let task = Task(
                title: title,
                status: .completed,
                parentBacklogID: backlog.id,
                scheduledDate: now,
                isCompleted: true
            )
            task.completedAt = now.addingTimeInterval(TimeInterval(-index * 600))
            task.modifiedAt = task.completedAt ?? now
            task.backlog = backlog
            context.insert(task)
        }
    }

    // MARK: - Archive

    private static func seedArchive(backlog: Backlog, isGerman: Bool, in context: ModelContext) {
        let titles = isGerman ? [
            "Einladung zu Carlas Hochzeit bestätigen ❤️",
            "Arzttermin machen",
            "Nervigen Newsletter abbestellen",
            "YouTube 'Später ansehen'-Liste aufräumen",
            "iPhone-Backup machen (wirklich!)",
            "Fast-identische Selfies löschen",
            "Sonnenfenster putzen",
            "Kabelsalat hinter dem TV bändigen"
        ] : [
            "RSVP to Carla's wedding ❤️",
            "Make doctor's appointment",
            "Finally unsubscribe from that annoying newsletter",
            "Clean up the YouTube 'Watch later' list",
            "Make an iPhone backup (for real!)",
            "Delete nearly identical selfies from gallery",
            "Clean the window that gets full sun",
            "Tame the cable mess behind the TV"
        ]

        let calendar = Calendar.current
        let now = Date()
        for (index, title) in titles.enumerated() {
            let task = Task(
                title: title,
                status: .archived,
                parentBacklogID: backlog.id
            )
            let archivedAt = calendar.date(
                byAdding: .hour,
                value: -(index + 1) * 24 - 5,
                to: now
            ) ?? now
            task.archivedAt = archivedAt
            task.modifiedAt = archivedAt
            task.archiveReason = .makeItCount
            task.archiveReviewed = true
            task.backlog = backlog
            context.insert(task)
        }
    }

    // MARK: - Helpers

    private static func fetchOrCreateBacklog(in context: ModelContext) throws -> Backlog {
        let existing = try context.fetch(FetchDescriptor<Backlog>(sortBy: [SortDescriptor(\.orderIndex)]))
        if let first = existing.first {
            return first
        }
        let title = String(localized: "backlog.default.title", defaultValue: "Backlog")
        let backlog = Backlog(title: title, orderIndex: 0)
        context.insert(backlog)
        return backlog
    }
}
#endif
