//
//  DebugAppDataCleaner.swift
//  Dawny
//
//  Nur DEBUG: leert Erinnerungen (EventKit) und alle SwiftData-Tasks.
//

#if DEBUG

import Foundation
import SwiftData

@MainActor
enum DebugAppDataCleaner {
    /// Löscht zuerst **alle** SwiftData-`Task`-Zeilen (ein Save), dann EventKit-Reminders nur per gespeicherter ID.
    /// Kein `removeTaskFromCalendar` dazwischen — das speichert pro Task und lässt andere Tabs noch `TaskRowView`s rendern.
    static func clearAll(syncEngine: SyncEngine, modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<Task>()
        let tasks = try modelContext.fetch(descriptor)
        let reminderIDs = tasks.compactMap(\.externalReminderID)
        
        for task in tasks {
            modelContext.delete(task)
        }
        try modelContext.save()
        
        for id in reminderIDs {
            await syncEngine.deleteReminderFromCalendarOnly(id: id)
        }
    }
}

#endif
