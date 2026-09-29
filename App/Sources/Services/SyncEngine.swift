// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  SyncEngine.swift
//  Dawny
//
//  Engine für bidirektionale Synchronisation mit EventKit
//

import Foundation
import Observation
import SwiftData
import EventKit
import Combine

/// SyncEngine - Verantwortlich für Kalender-Synchronisation
@MainActor
@Observable
final class SyncEngine {
    // MARK: - Properties
    
    private let calendarService: CalendarServiceProtocol
    private let modelContext: ModelContext
    /// Gerätelokales Wissen darüber, welche Erinnerungen dieses Gerät erreichen kann.
    /// Entscheidet, ob ein fehlender Treffer eine Löschung beweist — siehe
    /// `ReminderLinkRegistry`.
    private let linkRegistry: ReminderLinkRegistry
    // Interne Sync-Mechanik, keine UI-State: `@ObservationIgnored` hält sie aus der
    // Beobachtung heraus und lässt `deinit` weiterhin auf `observerTask` zugreifen.
    @ObservationIgnored private var observerTask: _Concurrency.Task<Void, Never>?
    @ObservationIgnored private var syncInProgress = false
    @ObservationIgnored private var lastSyncDate = Date()
    private let debounceInterval: TimeInterval = 1.0

    /// Einmaliges Flag der Identifier-Migration. Nicht `private`: der `AppGroupMigrator`
    /// übernimmt es in die geteilte Suite, damit die Migration nicht erneut läuft.
    static let reminderIdentifierMigrationKey = "DawnyMigratedReminderExternalIDsV1"

    /// Letzter Fehler aus einer schreibenden Kalender-Operation, für die Fehleranzeige.
    ///
    /// Vorher landeten EventKit-Fehler ausschließlich in einem `print`. Scheiterte das
    /// Anlegen einer Erinnerung — etwa weil in der Erinnerungen-App keine Standardliste
    /// eingerichtet ist — sah der Nutzer weiterhin einen aktiven Schalter und nie eine
    /// Erinnerung, ohne jeden Hinweis darauf, dass etwas schiefgelaufen ist.
    private(set) var lastErrorMessage: String?

    // MARK: - Initializer
    
    init(
        calendarService: CalendarServiceProtocol,
        modelContext: ModelContext,
        linkRegistry: ReminderLinkRegistry = ReminderLinkRegistry()
    ) {
        self.calendarService = calendarService
        self.modelContext = modelContext
        self.linkRegistry = linkRegistry
    }
    
    deinit {
        observerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Startet das Beobachten von Kalender-Änderungen
    func startObserving() async {
        // Registriere für EventStore-Änderungen
        observerTask = _Concurrency.Task {
            for await _ in NotificationCenter.default.notifications(named: .EKEventStoreChanged) {
                await handleCalendarChanged()
            }
        }

        // Bestehende Verknüpfungen auf die geräteübergreifende ID heben, bevor der
        // erste Sync auf ihnen arbeitet.
        await migrateReminderIdentifiersIfNeeded()

        // Initiale Sync
        await syncFromCalendar()
    }
    
    /// Stoppt das Beobachten
    func stopObserving() {
        observerTask?.cancel()
        observerTask = nil
    }

    /// Verwirft die aktuelle Fehlermeldung (Tap auf das X im Banner).
    func clearError() {
        lastErrorMessage = nil
    }

    /// Zieht die Erinnerungen nach, nachdem der Nutzer den Sync eingeschaltet hat.
    ///
    /// Ohne diesen Nachlauf bleiben Aufgaben, die schon vor dem Einschalten in Heute
    /// lagen, dauerhaft ohne Erinnerung: Eine Erinnerung entsteht sonst nur im Moment
    /// des Übergangs nach Heute, und genau den hat der Nutzer dann verpasst.
    func backfillAfterEnabling() async {
        await syncAllDailyFocusTasks()
    }

    /// Entfernt alle von Dawny angelegten Erinnerungen, nachdem der Nutzer den Sync
    /// ausgeschaltet hat.
    ///
    /// Läuft absichtlich ohne den `calendarSyncEnabled`-Guard: Beim Aufruf steht die
    /// Einstellung bereits auf `false`, der Guard würde also genau das Aufräumen
    /// verhindern, für das diese Methode da ist. Betroffen sind nur Aufgaben mit
    /// `externalReminderID`, also ausschließlich Erinnerungen, die Dawny selbst
    /// angelegt hat.
    func teardownAfterDisabling() async {
        let linkedTasks = fetchTasksLinkedToCalendar()
        guard !linkedTasks.isEmpty else { return }

        for task in linkedTasks {
            guard let reminderID = task.externalReminderID else { continue }

            // Verknüpfungen anderer Geräte gehören nicht diesem Gerät: Sie hier zu lösen
            // würde die echte Erinnerung auf dem verknüpfenden Gerät verwaisen lassen.
            guard await canReachReminder(reminderID) else {
                print("↩︎ Reminder link belongs to another device, keeping it: \(task.title)")
                continue
            }

            do {
                try await calendarService.deleteReminder(id: reminderID)
                task.unlinkFromCalendar()
                linkRegistry.forget(reminderID)
                print("✅ Removed reminder from calendar: \(task.title)")
            } catch {
                print("❌ Failed to remove reminder from calendar: \(error)")
                setError(from: error)
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save teardown changes: \(error)")
            setError(from: error)
        }
    }

    /// Synchronisiert einen Task zum Kalender (App → Calendar)
    func syncTaskToCalendar(_ task: Task) async {
        // Prüfe ob Kalender-Sync aktiviert ist
        guard AppSettings.shared.calendarSyncEnabled else {
            return
        }
        
        guard task.shouldSyncToCalendar else {
            // Task soll nicht mehr synchronisiert werden
            if task.isSyncedToCalendar {
                await removeTaskFromCalendar(task)
            }
            return
        }
        
        do {
            if let existingID = task.externalReminderID {
                // Update existierenden Reminder
                try await calendarService.updateReminder(
                    id: existingID,
                    title: task.title,
                    notes: task.notes,
                    isCompleted: task.isCompleted,
                    dueDate: task.scheduledDate
                )
                linkRegistry.remember(existingID)
                print("✅ Updated reminder in calendar: \(task.title)")
            } else {
                // Erstelle neuen Reminder
                let reminderID = try await calendarService.createReminder(
                    title: task.title,
                    notes: task.notes,
                    dueDate: task.scheduledDate
                )
                task.linkToCalendar(reminderID: reminderID)
                linkRegistry.remember(reminderID)
                try modelContext.save()
                print("✅ Created reminder in calendar: \(task.title)")
            }
        } catch {
            // Eine Verknüpfung von einem anderen Gerät ist hier nicht auflösbar. Das ist
            // erwartetes Verhalten und kein Fehler, den der Nutzer sehen soll — sonst
            // steht bei jedem Zweitgerät dauerhaft ein Fehler-Banner. Erst recht darf
            // Dawny hier keine zweite Erinnerung für dieselbe Aufgabe anlegen.
            if isForeignLinkError(error, of: task) {
                print("↩︎ Reminder link belongs to another device, skipping: \(task.title)")
                return
            }

            print("❌ Failed to sync task to calendar: \(error)")
            setError(from: error)
        }
    }
    
    /// Entfernt nur den EventKit-Reminder (ohne SwiftData-Task). Für Debug-Massenlöschen nach DB-Delete.
    func deleteReminderFromCalendarOnly(id: String) async {
        do {
            try await calendarService.deleteReminder(id: id)
        } catch {
            print("⚠️ deleteReminderFromCalendarOnly(\(id)): \(error)")
        }
    }
    
    /// Entfernt einen Task aus dem Kalender.
    ///
    /// Der `calendarSyncEnabled`-Guard ist bei aktivem iCloud-Sync wichtig: Ein Gerät
    /// ohne Reminders-Integration kennt die Erinnerung nicht und würde beim Reset die
    /// mitgesyncte Verknüpfung lösen — und dieses Lösen zurück zum verknüpfenden Gerät
    /// syncen, dessen echte Erinnerung damit verwaist.
    ///
    /// Derselbe Schaden entsteht auf einem Zweitgerät, auf dem die Integration
    /// eingeschaltet ist (der Auslieferungszustand): `deleteReminder` läuft für eine
    /// fremde ID stillschweigend ins Leere, das Lösen der Verknüpfung aber nicht.
    /// Deshalb fasst nur das Gerät die Verknüpfung an, das die Erinnerung selbst
    /// erreicht — siehe `ReminderLinkRegistry`.
    func removeTaskFromCalendar(_ task: Task) async {
        guard AppSettings.shared.calendarSyncEnabled else {
            return
        }

        guard let reminderID = task.externalReminderID else {
            return
        }

        guard await canReachReminder(reminderID) else {
            print("↩︎ Reminder link belongs to another device, keeping it: \(task.title)")
            return
        }

        do {
            try await calendarService.deleteReminder(id: reminderID)
            task.unlinkFromCalendar()
            linkRegistry.forget(reminderID)
            try modelContext.save()
            print("✅ Removed reminder from calendar: \(task.title)")
        } catch {
            print("❌ Failed to remove reminder from calendar: \(error)")
            setError(from: error)
        }
    }

    /// Synchronisiert alle Daily Focus Tasks
    func syncAllDailyFocusTasks() async {
        let tasks = fetchDailyFocusTasks()

        for task in tasks {
            await syncTaskToCalendar(task)
        }
    }

    /// Expliziter Calendar → App Sync (z. B. beim Wechsel in den Vordergrund).
    /// Nutzt dieselben `syncInProgress`/Debounce-Guards wie der Observer-Pfad.
    func syncNow() async {
        await syncFromCalendar()
    }
    
    // MARK: - Private Methods
    
    /// Handler für Kalender-Änderungen (Calendar → App)
    private func handleCalendarChanged() async {
        // Prüfe ob Kalender-Sync aktiviert ist
        guard AppSettings.shared.calendarSyncEnabled else {
            return
        }
        
        // Debouncing: Nicht zu oft synchronisieren
        let timeSinceLastSync = Date().timeIntervalSince(lastSyncDate)
        if timeSinceLastSync < debounceInterval {
            return
        }
        
        await syncFromCalendar()
    }
    
    /// Synchronisiert Änderungen vom Kalender zur App
    private func syncFromCalendar() async {
        // Prüfe ob Kalender-Sync aktiviert ist
        guard AppSettings.shared.calendarSyncEnabled else {
            return
        }
        
        guard !syncInProgress else { return }
        syncInProgress = true
        defer { syncInProgress = false }
        
        lastSyncDate = Date()
        
        let tasks = fetchDailyFocusTasks()

        // Sammelt, ob der Sync tatsächlich Daten verändert hat – nur dann wird
        // anschließend ein UI-Refresh-Signal gepostet (verhindert Refresh-Stürme).
        var didChange = false

        for task in tasks {
            guard let reminderID = task.externalReminderID else {
                continue
            }

            do {
                guard let calendarReminder = try await calendarService.fetchReminder(id: reminderID) else {
                    // Kein Treffer heißt nicht zwingend „gelöscht". Eine über iCloud
                    // mitgereiste Verknüpfung eines anderen Geräts ist hier schlicht
                    // nicht auflösbar, und die Aufgabe aus Heute zu räumen würde
                    // genau diesen Irrtum auf alle Geräte tragen.
                    guard linkRegistry.isKnownLocally(reminderID) else {
                        print("↩︎ Reminder \(reminderID) not resolvable on this device, leaving task untouched: \(task.title)")
                        continue
                    }

                    // Diese Erinnerung hat dieses Gerät selbst schon einmal erreicht —
                    // fehlt sie jetzt, wurde sie tatsächlich in Reminders gelöscht.
                    await handleReminderDeleted(task: task)
                    linkRegistry.forget(reminderID)
                    didChange = true
                    continue
                }

                linkRegistry.remember(reminderID)

                // Prüfe auf Änderungen und löse Konflikte
                if await resolveConflicts(task: task, calendarReminder: calendarReminder) {
                    didChange = true
                }

            } catch {
                print("❌ Failed to fetch reminder \(reminderID): \(error)")
            }
        }

        // Verzeichnis auf die noch bestehenden Verknüpfungen eindampfen, damit es nicht
        // unbegrenzt wächst.
        linkRegistry.keepOnly(Set(fetchTasksLinkedToCalendar().compactMap { $0.externalReminderID }))

        // Save Context
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save sync changes: \(error)")
        }

        // UI benachrichtigen, damit die ViewModels (DailyFocus/Backlog/Archive)
        // ihre Snapshot-Listen neu laden. Nur bei echter Änderung.
        if didChange {
            NotificationCenter.default.post(name: .dawnyDidSyncFromCalendar, object: nil)
        }
    }
    
    /// Löst Konflikte zwischen App und Kalender
    /// Strategie: Last-Write-Wins basierend auf Timestamps
    /// - Returns: `true`, wenn der Task durch den Kalender verändert wurde.
    @discardableResult
    private func resolveConflicts(task: Task, calendarReminder: CalendarReminder) async -> Bool {
        var hasChanges = false
        
        // Vergleiche Timestamps
        let calendarModDate = calendarReminder.modificationDate ?? Date.distantPast
        let taskModDate = task.modifiedAt
        
        // Calendar ist neuer = Calendar gewinnt
        let calendarIsNewer = calendarModDate > taskModDate
        
        // 1. Prüfe Completion-Status
        if calendarReminder.isCompleted != task.isCompleted {
            if calendarIsNewer {
                // Calendar sagt: completed
                if calendarReminder.isCompleted {
                    task.complete()
                    hasChanges = true
                    print("📥 Task marked as completed from calendar: \(task.title)")
                }
            } else {
                // App ist neuer, sync zu Calendar
                await syncTaskToCalendar(task)
            }
        }
        
        // 2. Prüfe Datum-Änderung
        if let calendarDueDate = calendarReminder.dueDate,
           let taskScheduledDate = task.scheduledDate {
            
            let calendar = Calendar.current
            let calendarDay = calendar.startOfDay(for: calendarDueDate)
            let taskDay = calendar.startOfDay(for: taskScheduledDate)
            
            if calendarDay != taskDay && calendarIsNewer {
                // User hat Datum im Kalender geändert
                // Task verlässt Daily Focus und wird für neues Datum geplant
                task.scheduleFor(date: calendarDueDate)
                hasChanges = true
                print("📥 Task rescheduled from calendar: \(task.title) to \(calendarDueDate)")
            }
        }
        
        // 3. Prüfe Titel-Änderung
        if calendarReminder.title != task.title && calendarIsNewer {
            task.title = calendarReminder.title
            hasChanges = true
            print("📥 Task title updated from calendar: \(task.title)")
        }
        
        // 4. Prüfe Notes-Änderung
        if calendarReminder.notes != task.notes && calendarIsNewer {
            task.notes = calendarReminder.notes
            hasChanges = true
            print("📥 Task notes updated from calendar")
        }
        
        if hasChanges {
            task.modifiedAt = Date()
        }

        return hasChanges
    }

    /// Handler wenn Reminder im Kalender gelöscht wurde
    private func handleReminderDeleted(task: Task) async {
        // MVP: Automatisch aus DailyFocus entfernen
        print("📥 Reminder deleted in calendar, moving task to backlog: \(task.title)")
        task.unlinkFromCalendar()
        task.resetToBacklog()
    }
    
    // MARK: - Erreichbarkeit von Verknüpfungen

    /// True, wenn dieses Gerät die Erinnerung erreichen kann.
    ///
    /// Erst das Verzeichnis, dann ein direkter Abruf. Der Abruf deckt den ersten Lauf
    /// nach dem Update ab, in dem das Verzeichnis noch leer ist, obwohl die
    /// Verknüpfungen von diesem Gerät stammen.
    private func canReachReminder(_ reminderID: String) async -> Bool {
        if linkRegistry.isKnownLocally(reminderID) {
            return true
        }

        do {
            guard try await calendarService.fetchReminder(id: reminderID) != nil else {
                return false
            }
        } catch {
            print("❌ Failed to fetch reminder \(reminderID): \(error)")
            return false
        }

        linkRegistry.remember(reminderID)
        return true
    }

    /// True, wenn der Fehler daher rührt, dass die Verknüpfung der Aufgabe zu einer
    /// Erinnerung zeigt, die dieses Gerät nicht kennt.
    private func isForeignLinkError(_ error: Error, of task: Task) -> Bool {
        guard let calendarError = error as? CalendarServiceError,
              case .reminderNotFound = calendarError,
              let reminderID = task.externalReminderID else {
            return false
        }

        return !linkRegistry.isKnownLocally(reminderID)
    }

    /// Holt alle Daily Focus Tasks aus dem Context
    private func fetchDailyFocusTasks() -> [Task] {
        let descriptor = FetchDescriptor<Task>()

        do {
            let allTasks = try modelContext.fetch(descriptor)
            // Filter manuell nach status (Predicates mit Enums funktionieren nicht gut)
            return allTasks.filter { $0.status == .dailyFocus }
        } catch {
            print("❌ Failed to fetch daily focus tasks: \(error)")
            return []
        }
    }

    /// Holt alle Tasks, die eine Erinnerung in der Erinnerungen-App haben.
    ///
    /// Bewusst nicht auf `.dailyFocus` eingeschränkt: Beim Abräumen zählt jede
    /// Verknüpfung, auch die einer inzwischen erledigten oder verschobenen Aufgabe.
    private func fetchTasksLinkedToCalendar() -> [Task] {
        let descriptor = FetchDescriptor<Task>()

        do {
            return try modelContext.fetch(descriptor).filter { $0.isSyncedToCalendar }
        } catch {
            print("❌ Failed to fetch linked tasks: \(error)")
            return []
        }
    }

    // MARK: - Migration

    /// Hebt bestehende Verknüpfungen einmalig von der gerätelokalen
    /// `calendarItemIdentifier` auf die geräteübergreifende `calendarItemExternalIdentifier`.
    ///
    /// Vor der Umstellung stand in `externalReminderID` eine ID, die nur auf dem
    /// verknüpfenden Gerät auflösbar war. Bei aktivem iCloud-Sync sah ein Zweitgerät
    /// deshalb eine Verknüpfung, zu der es keine Erinnerung finden konnte, und legte beim
    /// Sync eine zweite an. Nach der Migration zeigen beide Geräte auf denselben Eintrag.
    ///
    /// Läuft bewusst ohne `calendarSyncEnabled`-Guard: Der Schritt liest nur aus EventKit
    /// und ist bei ausgeschaltetem Sync ohnehin ein Leerlauf, weil dann keine
    /// Verknüpfungen mehr existieren.
    func migrateReminderIdentifiersIfNeeded() async {
        guard !AppGroup.defaults.bool(forKey: Self.reminderIdentifierMigrationKey) else { return }

        var didRewrite = false

        for task in fetchTasksLinkedToCalendar() {
            guard let storedID = task.externalReminderID else { continue }

            do {
                guard let stableID = try await calendarService.stableIdentifier(forStoredID: storedID) else {
                    // Hier nicht auflösbar: entweder im Kalender gelöscht oder von einem
                    // anderen Gerät verknüpft. Beides fasst die Migration nicht an — der
                    // reguläre Sync räumt gelöschte Erinnerungen auf, und eine fremde
                    // Verknüpfung schreibt das verknüpfende Gerät selbst um.
                    continue
                }

                // Aufgelöst heißt: Dieses Gerät erreicht die Erinnerung. Das gehört ins
                // Verzeichnis, egal ob die ID danach umgeschrieben wird oder nicht.
                linkRegistry.remember(stableID)

                guard stableID != storedID else { continue }

                // Direkt gesetzt statt über `linkToCalendar`: Ein neues `modifiedAt` würde
                // die Aufgabe im Last-Write-Wins-Vergleich künstlich gewinnen lassen,
                // obwohl sich inhaltlich nichts geändert hat.
                task.externalReminderID = stableID
                didRewrite = true
                print("🔁 Migrated reminder link to external identifier: \(task.title)")
            } catch {
                // Flag nicht setzen — der nächste Start versucht es erneut.
                print("❌ Failed to migrate reminder identifier: \(error)")
                return
            }
        }

        if didRewrite {
            do {
                try modelContext.save()
            } catch {
                print("❌ Failed to save migrated reminder identifiers: \(error)")
                return
            }
        }

        AppGroup.defaults.set(true, forKey: Self.reminderIdentifierMigrationKey)
    }

    /// Übersetzt einen Kalender-Fehler in eine Meldung für das Fehler-Banner.
    private func setError(from error: Error) {
        if let calendarError = error as? CalendarServiceError,
           case .permissionDenied = calendarError {
            lastErrorMessage = String(
                localized: "error.sync.reminders_permission",
                defaultValue: "Dawny has no access to Reminders. You can grant it in the iOS settings."
            )
        } else {
            lastErrorMessage = String(
                localized: "error.sync.reminders_failed",
                defaultValue: "Tasks cannot be synced with Reminders right now."
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Gepostet, nachdem ein Calendar → App Sync tatsächlich Daten verändert hat.
    /// `ContentView` lauscht darauf und lädt die ViewModel-Listen neu.
    static let dawnyDidSyncFromCalendar = Notification.Name("dawnyDidSyncFromCalendar")
}

// MARK: - NotificationCenter Extension

extension NotificationCenter {
    func notifications(named name: Notification.Name) -> AsyncStream<Notification> {
        AsyncStream { continuation in
            let observer = addObserver(forName: name, object: nil, queue: nil) { notification in
                continuation.yield(notification)
            }
            
            continuation.onTermination = { _ in
                self.removeObserver(observer)
            }
        }
    }
}
