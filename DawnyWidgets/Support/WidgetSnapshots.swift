// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  WidgetSnapshots.swift
//  DawnyWidgets
//
//  Reine Wert-Typen für die Widget-Timelines. Bewusst KEINE SwiftData-Objekte —
//  Timeline-Entries werden über Prozess-/Aktorgrenzen serialisiert.
//

import Foundation

/// Eine einzelne Aufgabe im Widget.
struct WidgetTask: Identifiable, Hashable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    /// True, wenn diese (Heute-)Aufgabe beim nächsten Reset ins Archiv wandert (Make-It-Count).
    let willArchiveAtNextReset: Bool
    /// SF-Symbol der Kategorie (für Backlog-Zeilen), sonst nil.
    let categoryIconName: String?
    /// Nur Archiv: Zeitpunkt der Archivierung.
    let archivedAt: Date?
    /// Nur Archiv: „neu seit letztem Besuch" → oranger Punkt.
    let isNew: Bool

    init(
        id: UUID,
        title: String,
        isCompleted: Bool = false,
        willArchiveAtNextReset: Bool = false,
        categoryIconName: String? = nil,
        archivedAt: Date? = nil,
        isNew: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.willArchiveAtNextReset = willArchiveAtNextReset
        self.categoryIconName = categoryIconName
        self.archivedAt = archivedAt
        self.isNew = isNew
    }
}

/// Eine Kategorie-Sektion im Backlog-Widget.
struct WidgetCategorySection: Identifiable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let openCount: Int
    let tasks: [WidgetTask]
}

/// Momentaufnahme für das Heute-Widget.
struct TodaySnapshot: Hashable {
    let openTasks: [WidgetTask]
    let completedTasks: [WidgetTask]
    let resetHour: Int

    var openCount: Int { openTasks.count }
    var completedCount: Int { completedTasks.count }
    var totalCount: Int { openTasks.count + completedTasks.count }

    static let placeholder = TodaySnapshot(
        openTasks: [
            WidgetTask(id: UUID(), title: "E-Mails beantworten"),
            WidgetTask(id: UUID(), title: "Sport"),
            WidgetTask(id: UUID(), title: "Einkaufen", willArchiveAtNextReset: true)
        ],
        completedTasks: [WidgetTask(id: UUID(), title: "Kaffee kochen", isCompleted: true)],
        resetHour: 3
    )
}

/// Momentaufnahme für das Backlog-Widget.
struct BacklogSnapshot: Hashable {
    let sections: [WidgetCategorySection]
    /// Index der aktuell im Medium gezeigten Kategorie (Chevron-Navigation).
    let selectedSectionIndex: Int

    var totalCount: Int { sections.reduce(0) { $0 + $1.openCount } }

    static let placeholder = BacklogSnapshot(
        sections: [
            WidgetCategorySection(
                id: UUID(), name: "Quick", iconName: "bolt.fill", openCount: 3,
                tasks: [
                    WidgetTask(id: UUID(), title: "Rechnung zahlen", categoryIconName: "bolt.fill"),
                    WidgetTask(id: UUID(), title: "Termin buchen", categoryIconName: "bolt.fill")
                ]
            )
        ],
        selectedSectionIndex: 0
    )
}

/// Momentaufnahme für das Archiv-Widget.
struct ArchiveSnapshot: Hashable {
    let tasks: [WidgetTask]

    var newCount: Int { tasks.filter(\.isNew).count }

    static let placeholder = ArchiveSnapshot(
        tasks: [
            WidgetTask(id: UUID(), title: "Alte Idee", archivedAt: Date().addingTimeInterval(-9 * 3600), isNew: true),
            WidgetTask(id: UUID(), title: "Notiz", archivedAt: Date().addingTimeInterval(-11 * 3600), isNew: true)
        ]
    )
}
