// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  PreviewSupport.swift
//  Dawny
//
//  Gemeinsames SwiftUI-Setup für Xcode Previews (SwiftData + Services).
//

import SwiftData
import SwiftUI

enum DawnyPreview {
    @MainActor
    static func contentView() -> some View {
        let schema = Schema([
            Task.self,
            Backlog.self,
            Category.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let calendarService = PreviewCalendarService()
        let resetEngine = ResetEngine(
            timeProvider: SystemTimeProvider(),
            modelContext: container.mainContext
        )
        let syncEngine = SyncEngine(
            calendarService: calendarService,
            modelContext: container.mainContext
        )
        resetEngine.syncEngine = syncEngine

        return ContentView()
            .modelContainer(container)
            .environment(\.resetEngine, resetEngine)
            .environment(\.syncEngine, syncEngine)
    }
}

private final class PreviewCalendarService: CalendarServiceProtocol {
    func requestAccess() async throws -> Bool { true }

    func createReminder(title: String, notes: String?, dueDate: Date?) async throws -> String {
        UUID().uuidString
    }

    func updateReminder(
        id: String,
        title: String?,
        notes: String?,
        isCompleted: Bool?,
        dueDate: Date?
    ) async throws {}

    func deleteReminder(id: String) async throws {}

    func fetchReminder(id: String) async throws -> CalendarReminder? { nil }

    func fetchReminders(from startDate: Date, to endDate: Date) async throws -> [CalendarReminder] {
        []
    }
}
