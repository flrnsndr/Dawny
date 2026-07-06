// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  AutoArchiveReviewViewModel.swift
//  Dawny
//
//  ViewModel für das Auto-Archive Review Overlay
//

import Foundation
import SwiftData
import Observation

@Observable
final class AutoArchiveReviewViewModel {
    // MARK: - Properties

    private let modelContext: ModelContext

    /// Tasks aus dem Daily Focus, die per Make-It-Count archiviert wurden (noch nicht reviewed)
    var dailyArchivedTasks: [Task] = []

    /// Tasks aus dem Backlog, die per Auto-Tidy archiviert wurden (noch nicht reviewed)
    var backlogArchivedTasks: [Task] = []

    var currentStep: Int = 0

    /// True wenn mindestens eine Liste nicht leer ist — Trigger für Sheet-Präsentation
    var shouldPresent: Bool {
        !dailyArchivedTasks.isEmpty || !backlogArchivedTasks.isEmpty
    }

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// Lädt alle noch nicht reviewed Auto-Archive-Items aus dem ModelContext.
    func loadQueue() {
        let descriptor = FetchDescriptor<Task>()
        guard let all = try? modelContext.fetch(descriptor) else { return }

        // SwiftData-Predicates mit Enums sind eingeschränkt — manuell filtern
        dailyArchivedTasks = all
            .filter { $0.archiveReason == .makeItCount && $0.archiveReviewed == false }
            .sorted { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) }

        backlogArchivedTasks = all
            .filter { $0.archiveReason == .autoTidy && $0.archiveReviewed == false }
            .sorted { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) }
    }

    /// Markiert alle geladenen Items als reviewed und speichert den Context.
    /// Wird beim Dismiss (Button, X, Pull-Down) aufgerufen.
    func markAllReviewed() {
        for task in dailyArchivedTasks { task.archiveReviewed = true }
        for task in backlogArchivedTasks { task.archiveReviewed = true }
        try? modelContext.save()
        dailyArchivedTasks = []
        backlogArchivedTasks = []
        currentStep = 0
    }
}
