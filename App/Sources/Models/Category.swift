// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  Category.swift
//  Dawny
//
//  SwiftData Model für Backlog-Kategorien
//

import Foundation
import SwiftData

@Model
final class Category {
    // MARK: - Stored Properties

    // Inline-Defaults sind CloudKit-Pflicht — siehe Hinweis in `Task`.

    /// Eindeutige ID
    var id: UUID = UUID()

    /// Kategorie-Typ (Enum)
    var categoryType: TaskCategory = TaskCategory.custom

    /// Name der Kategorie (lokalisiert, kann überschrieben werden)
    var name: String = ""

    /// SF Symbol Icon-Name
    var iconName: String = ""

    /// Sortierungs-Index (für konfigurierbare Reihenfolge)
    var orderIndex: Int = 0

    /// Flag ob dies die "Unkategorisiert"-Kategorie ist
    var isUncategorized: Bool = false

    /// Markiert, dass der Nutzer den Namen manuell überschrieben hat.
    /// Solange `false`, wird `categoryType.displayName` (lokalisiert) angezeigt.
    var isNameCustomized: Bool = false

    /// Markiert, dass der Nutzer das Symbol manuell überschrieben hat.
    /// Solange `false`, wird `categoryType.iconName` als Default verwendet.
    var isIconCustomized: Bool = false

    /// Wenn true, verhalten sich Tasks in dieser Kategorie „wiederkehrend”
    /// (siehe Heute-Backlog-Clone-Logik).
    var isRecurring: Bool = false

    /// Auto-Tidy: Anzahl Tage im Backlog, nach denen Tasks automatisch archiviert werden.
    /// nil = deaktiviert. Recurring-Kategorien ignorieren diesen Wert.
    var autoArchiveDays: Int? = nil

    /// Erstellungsdatum
    var createdAt: Date = Date()

    // MARK: - Relationships

    /// Alle Tasks in dieser Kategorie
    // Optional, weil CloudKit ausnahmslos optionale Relationships verlangt.
    // Siehe Hinweis in `Backlog`.
    @Relationship(deleteRule: .nullify, inverse: \Task.category)
    var tasks: [Task]? = []
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        categoryType: TaskCategory,
        name: String? = nil,
        iconName: String? = nil,
        orderIndex: Int? = nil,
        isUncategorized: Bool = false,
        isNameCustomized: Bool = false,
        isIconCustomized: Bool = false,
        isRecurring: Bool = false,
        autoArchiveDays: Int? = nil,
        createdAt: Date = Date(),
        tasks: [Task] = []
    ) {
        self.id = id
        self.categoryType = categoryType
        self.name = name ?? categoryType.displayName
        self.iconName = iconName ?? categoryType.iconName
        self.orderIndex = orderIndex ?? categoryType.defaultOrderIndex
        self.isUncategorized = isUncategorized || (categoryType == .uncategorized)
        self.isNameCustomized = isNameCustomized
        self.isIconCustomized = isIconCustomized
        self.isRecurring = isRecurring
        self.autoArchiveDays = autoArchiveDays
        self.createdAt = createdAt
        self.tasks = tasks
    }
    
    // MARK: - Computed Properties
    
    /// Anzahl der Tasks in dieser Kategorie (nur Backlog-Tasks)
    var taskCount: Int {
        liveTasks.filter { $0.status == .inBacklog }.count
    }
    
    /// Tasks die im Backlog sind (nicht completed/scheduled)
    var backlogTasks: [Task] {
        liveTasks
            .filter { $0.status == .inBacklog }
            .sorted()
    }

    /// Filtert bereits als gelöscht markierte Tasks aus der Relationship.
    /// Siehe Hinweis in `Backlog.liveTasks`.
    private var liveTasks: [Task] {
        (tasks ?? []).filter { !$0.isDeleted }
    }

    // MARK: - Display

    /// Name für die UI. Solange der User nichts geändert hat, kommt die
    /// (re-)lokalisierte Variante aus `TaskCategory.displayName` zurück.
    /// Dadurch funktioniert ein Sprachwechsel weiterhin korrekt.
    var displayName: String {
        if isNameCustomized {
            return name
        }
        if isRecurring && categoryType == .custom {
            return String(
                localized: "category.recurring.default.name",
                defaultValue: "Recurring Tasks"
            )
        }
        return categoryType.displayName
    }

    /// SF-Symbol für die UI. Folgt der gleichen Logik wie `displayName`.
    var displayIconName: String {
        isIconCustomized ? iconName : categoryType.iconName
    }

    // MARK: - Editing Capabilities

    /// Darf der Nutzer diese Kategorie umbenennen?
    /// "Unkategorisiert" ist komplett gesperrt.
    var canRename: Bool {
        !isUncategorized
    }

    /// Darf der Nutzer das Symbol dieser Kategorie ändern?
    /// "Unkategorisiert" ist komplett gesperrt.
    var canChangeIcon: Bool {
        !isUncategorized
    }

    /// Darf der Nutzer diese Kategorie löschen?
    /// "Unkategorisiert" und "Heute" (`.quick`) sind nicht löschbar.
    var canDelete: Bool {
        !isUncategorized && categoryType != .quick
    }

    /// Darf der Nutzer die wiederkehrende Markierung umschalten?
    var canToggleRecurring: Bool {
        !isUncategorized
    }

    /// True, wenn überhaupt irgendeine Edit-Aktion verfügbar ist.
    var hasAnyEditCapability: Bool {
        canRename || canChangeIcon || canDelete || canToggleRecurring
    }
}

// MARK: - Equatable

extension Category: Equatable {
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Comparable

extension Category: Comparable {
    static func < (lhs: Category, rhs: Category) -> Bool {
        // Primär nach orderIndex
        if lhs.orderIndex != rhs.orderIndex {
            return lhs.orderIndex < rhs.orderIndex
        }
        // Sekundär nach Erstellungsdatum
        return lhs.createdAt < rhs.createdAt
    }
}


