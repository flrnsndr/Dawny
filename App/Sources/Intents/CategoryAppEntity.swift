// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import Foundation
import SwiftData

struct CategoryAppEntity: AppEntity, Identifiable {
    let id: UUID
    let displayName: String
    let categoryTypeRawValue: String
    let isCustom: Bool

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }

    init(category: Category) {
        self.id = category.id
        self.displayName = category.displayName
        self.categoryTypeRawValue = category.categoryType.rawValue
        self.isCustom = category.categoryType == .custom
    }
}

struct CategoryEntityQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [CategoryAppEntity.ID]) async throws -> [CategoryAppEntity] {
        let context = try await IntentDataStore.makeContext()
        return try await IntentDataStore.allCategories(in: context)
            .filter { identifiers.contains($0.id) }
            .map(CategoryAppEntity.init)
    }

    func suggestedEntities() async throws -> [CategoryAppEntity] {
        let context = try await IntentDataStore.makeContext()
        return try await IntentDataStore.allCategories(in: context).map(CategoryAppEntity.init)
    }

    func entities(matching string: String) async throws -> [CategoryAppEntity] {
        let context = try await IntentDataStore.makeContext()
        let categories = try await IntentDataStore.allCategories(in: context)

        return IntentTextMatcher.bestMatches(for: string, in: categories) { category in
            var candidates = [category.displayName, category.name]
            candidates.append(contentsOf: category.categoryType.spokenSynonyms)

            if category.categoryType == .custom {
                candidates.append(category.name)
            }

            return candidates
        }
        .map(CategoryAppEntity.init)
    }
}
