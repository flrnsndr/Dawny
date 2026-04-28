// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import CoreSpotlight
import Foundation

struct CategoryAppEntity: AppEntity, IndexedEntity, Identifiable {
    let id: UUID
    let displayName: String
    let categoryTypeRawValue: String
    let isCustom: Bool

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.displayName = displayName
        if let type = TaskCategory(rawValue: categoryTypeRawValue) {
            attributes.keywords = type.spokenSynonyms
        }
        return attributes
    }

    init(category: Category) {
        self.id = category.id
        self.displayName = category.displayName
        self.categoryTypeRawValue = category.categoryType.rawValue
        self.isCustom = category.categoryType == .custom
    }
}

struct CategoryEntityQuery: EntityQuery, EntityStringQuery {
    @Dependency
    var dataStore: any TaskDataStoring

    @MainActor
    func entities(for identifiers: [CategoryAppEntity.ID]) async throws -> [CategoryAppEntity] {
        try dataStore.allCategories()
            .filter { identifiers.contains($0.id) }
            .map(CategoryAppEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [CategoryAppEntity] {
        try dataStore.allCategories().map(CategoryAppEntity.init)
    }

    @MainActor
    func entities(matching string: String) async throws -> [CategoryAppEntity] {
        let categories = try dataStore.allCategories()

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
