// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  CloudDeduplicator.swift
//  Dawny
//
//  Führt doppelt geseedete Objekte nach einem CloudKit-Import zusammen.
//

import Foundation
import SwiftData

/// Repariert Duplikate, die entstehen, wenn ein frisch installiertes Gerät die
/// Standarddaten seedet, bevor der erste CloudKit-Download angekommen ist.
/// Betroffen sind nur automatisch angelegte Objekte: der Default-Backlog, die
/// eingebauten Kategorien und die Standard-„Wiederkehrende Aufgaben"-Kategorie.
///
/// Vom Nutzer angelegte Kategorien werden nie zusammengeführt — dort ist die `id`
/// die Identität, zwei gleichnamige Custom-Kategorien sind zwei echte Kategorien.
///
/// Die Routine ist **idempotent** (ein zweiter Lauf ändert nichts) und
/// **deterministisch** (alle Geräte wählen denselben Gewinner), damit die
/// Deduplizierung selbst wieder konvergiert.
enum CloudDeduplicator {
    /// Führt alle Duplikate zusammen. Gibt `true` zurück, wenn etwas geändert wurde.
    @discardableResult
    static func dedupe(in context: ModelContext) throws -> Bool {
        let backlogsChanged = try dedupeBacklogs(in: context)
        let categoriesChanged = try dedupeCategories(in: context)

        let changed = backlogsChanged || categoriesChanged
        if changed {
            try context.save()
        }
        return changed
    }

    // MARK: - Winner selection

    /// Ältestes `createdAt` gewinnt; bei Gleichstand die lexikografisch kleinste `id`.
    /// Beide Kriterien sind geräteunabhängig, also wählt jedes Gerät denselben Gewinner.
    private static func sortedByPrecedence<T>(
        _ items: [T],
        createdAt: (T) -> Date,
        id: (T) -> UUID
    ) -> [T] {
        items.sorted { lhs, rhs in
            let lhsDate = createdAt(lhs)
            let rhsDate = createdAt(rhs)
            if lhsDate != rhsDate {
                return lhsDate < rhsDate
            }
            return id(lhs).uuidString < id(rhs).uuidString
        }
    }

    // MARK: - Backlogs

    private static func dedupeBacklogs(in context: ModelContext) throws -> Bool {
        let backlogs = try context.fetch(FetchDescriptor<Backlog>()).filter { !$0.isDeleted }
        guard backlogs.count > 1 else { return false }

        let ordered = sortedByPrecedence(backlogs, createdAt: \.createdAt, id: \.id)
        guard let winner = ordered.first else { return false }
        let losers = Array(ordered.dropFirst())
        let loserIDs = Set(losers.map(\.id))

        // `parentBacklogID` ist denormalisiert: auch Tasks, die nicht (mehr) in der
        // Relationship hängen, müssen auf den Gewinner zeigen.
        let allTasks = try context.fetch(FetchDescriptor<Task>()).filter { !$0.isDeleted }
        for task in allTasks where loserIDs.contains(task.parentBacklogID) {
            task.parentBacklogID = winner.id
        }

        for loser in losers {
            // Snapshot: das Umhängen mutiert die Inverse-Relationship während der Iteration.
            // Muss vor dem Löschen passieren — `Backlog` löscht seine Tasks kaskadierend.
            let tasksToMove = loser.tasks.filter { !$0.isDeleted }
            for task in tasksToMove {
                task.backlog = winner
                task.parentBacklogID = winner.id
            }
            context.delete(loser)
        }

        return true
    }

    // MARK: - Categories

    private static func dedupeCategories(in context: ModelContext) throws -> Bool {
        let categories = try context.fetch(FetchDescriptor<Category>()).filter { !$0.isDeleted }
        guard categories.count > 1 else { return false }

        let categoryService = CategoryService(modelContext: context)
        var groups: [[Category]] = []

        // Eingebaute Kategorien: der `categoryType` ist die Identität.
        let builtIns = Dictionary(grouping: categories.filter { $0.categoryType != .custom }) {
            $0.categoryType
        }
        groups.append(contentsOf: builtIns.values.filter { $0.count > 1 })

        // Die geseedete „Wiederkehrende Aufgaben"-Kategorie ist `.custom` und
        // braucht deshalb ihre eigene Erkennung.
        let defaultRecurring = categories.filter {
            $0.categoryType == .custom && categoryService.isLikelyDefaultRecurringCategory($0)
        }
        if defaultRecurring.count > 1 {
            groups.append(defaultRecurring)
        }

        guard !groups.isEmpty else { return false }

        for group in groups {
            let ordered = sortedByPrecedence(group, createdAt: \.createdAt, id: \.id)
            guard let winner = ordered.first else { continue }

            for loser in ordered.dropFirst() {
                // Snapshot wegen Inverse-Relationship-Mutation während der Iteration.
                let tasksToMove = loser.tasks.filter { !$0.isDeleted }
                for task in tasksToMove {
                    task.category = winner
                    task.modifiedAt = Date()
                }
                merge(loser: loser, into: winner)
                context.delete(loser)
            }
        }

        return true
    }

    /// Übernimmt Anpassungen des Verlierers, die der Gewinner noch nicht hat.
    /// Der Gewinner behält immer seine eigenen bereits angepassten Werte.
    private static func merge(loser: Category, into winner: Category) {
        if loser.isNameCustomized && !winner.isNameCustomized {
            winner.name = loser.name
            winner.isNameCustomized = true
        }
        if loser.isIconCustomized && !winner.isIconCustomized {
            winner.iconName = loser.iconName
            winner.isIconCustomized = true
        }
        if winner.autoArchiveDays == nil, let days = loser.autoArchiveDays, !winner.isRecurring {
            winner.autoArchiveDays = days
        }
    }
}
