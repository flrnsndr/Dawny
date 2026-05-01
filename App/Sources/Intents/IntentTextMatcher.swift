// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import Foundation

enum IntentTextMatcher {
    nonisolated static func normalized(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9äöüß ]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .joined(separator: " ")
    }

    nonisolated static func score(query: String, candidates: [String]) -> Double {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else { return 0 }

        return candidates
            .map { score(normalizedQuery: normalizedQuery, candidate: normalized($0)) }
            .max() ?? 0
    }

    nonisolated static func bestMatches<Entity>(
        for query: String,
        in entities: [Entity],
        candidates: (Entity) -> [String],
        minimumScore: Double = 0.25
    ) -> [Entity] {
        let scored = entities
            .map { entity in
                (entity: entity, score: score(query: query, candidates: candidates(entity)))
            }
            .filter { $0.score >= minimumScore }
            .sorted { $0.score > $1.score }

        guard let best = scored.first else { return [] }

        // Strong matches should run directly. We return several lower-confidence
        // matches so Siri can disambiguate with a spoken follow-up.
        if best.score >= 0.95 {
            return [best.entity]
        }

        return scored.prefix(5).map(\.entity)
    }

    nonisolated private static func score(normalizedQuery: String, candidate: String) -> Double {
        guard !candidate.isEmpty else { return 0 }
        if normalizedQuery == candidate { return 1.0 }
        if candidate.contains(normalizedQuery) || normalizedQuery.contains(candidate) {
            return 0.85
        }

        let queryTokens = Set(normalizedQuery.split(separator: " ").map(String.init))
        let candidateTokens = Set(candidate.split(separator: " ").map(String.init))
        let sharedTokens = queryTokens.intersection(candidateTokens).count
        let totalTokens = max(queryTokens.union(candidateTokens).count, 1)
        let tokenScore = Double(sharedTokens) / Double(totalTokens)

        let distance = levenshtein(normalizedQuery, candidate)
        let maxLength = max(normalizedQuery.count, candidate.count, 1)
        let editScore = 1.0 - (Double(distance) / Double(maxLength))

        return max(tokenScore * 0.8, editScore * 0.75)
    }

    nonisolated private static func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        let lhs = Array(lhs)
        let rhs = Array(rhs)

        if lhs.isEmpty { return rhs.count }
        if rhs.isEmpty { return lhs.count }

        var previous = Array(0...rhs.count)
        var current = Array(repeating: 0, count: rhs.count + 1)

        for lhsIndex in 1...lhs.count {
            current[0] = lhsIndex

            for rhsIndex in 1...rhs.count {
                let deletion = previous[rhsIndex] + 1
                let insertion = current[rhsIndex - 1] + 1
                let substitution = previous[rhsIndex - 1] + (lhs[lhsIndex - 1] == rhs[rhsIndex - 1] ? 0 : 1)
                current[rhsIndex] = min(deletion, insertion, substitution)
            }

            previous = current
        }

        return previous[rhs.count]
    }
}
