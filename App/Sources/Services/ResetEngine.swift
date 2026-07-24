// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ResetEngine.swift
//  Dawny
//
//  Engine für den automatischen 3-AM-Reset
//

import Foundation
import SwiftData
import BackgroundTasks

/// ResetEngine - Verantwortlich für den automatischen Task-Reset
/// Tasks die um 3:00 Uhr nicht completed sind, wandern zurück ins Backlog
@MainActor
final class ResetEngine {
    // MARK: - Properties
    
    private let timeProvider: TimeProvider
    private let modelContext: ModelContext
    private let userDefaultsKey = "DawnyLastResetDate"
    private let backgroundTaskIdentifier = "Flo.Dawny.reset"
    
    /// Aktuelle Reset-Stunde aus Settings
    private var resetHour: Int {
        AppSettings.shared.resetHour
    }
    
    /// Optional: Referenz zum SyncEngine für Kalender-Cleanup
    weak var syncEngine: SyncEngine?
    
    // MARK: - Initializer
    
    init(
        timeProvider: TimeProvider,
        modelContext: ModelContext
    ) {
        self.timeProvider = timeProvider
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Prüft ob ein Reset fällig ist und führt ihn ggf. durch
    func checkAndPerformResetIfNeeded() async {
        let currentDate = timeProvider.currentDate
        let lastResetDate = getLastResetDate()
        
        // Berechne wann der letzte Reset hätte stattfinden sollen
        let shouldHaveResetAt = calculateLastResetThreshold(for: currentDate)
        
        // Wenn der letzte Reset vor dem Threshold liegt, führe Reset durch
        if lastResetDate < shouldHaveResetAt {
            await performReset(referenceDate: currentDate)
        }
    }
    
    /// Führt den Reset durch (hauptsächlich für Tests und manuellen Aufruf)
    func performReset(referenceDate: Date = Date()) async {
        print("🔄 Performing Reset at \(referenceDate)")

        // Auto-Tidy: abgelaufene Backlog-Tasks zuerst archivieren
        let staleCount = archiveStaleBacklogTasks(referenceDate: referenceDate)
        var hasArchivedAnyTask = staleCount > 0
        if staleCount > 0 {
            print("🧹 Auto-Tidy archived \(staleCount) stale backlog task(s)")
        }

        // Fetch alle Tasks die resettet werden müssen
        let tasksToReset = fetchTasksNeedingReset()

        guard !tasksToReset.isEmpty else {
            print("✅ No tasks need reset")
            if hasArchivedAnyTask {
                AppSettings.shared.hasNewArchivedTasks = true
                // Auto-Tidy hat Backlog-Tasks verändert → UI neu laden lassen.
                NotificationCenter.default.post(name: .dawnyDidReset, object: nil)
            }
            saveLastResetDate(referenceDate)
            // Widgets aus dem „Als-ob"-Zustand auf den echten Stand aktualisieren.
            WidgetRefresher.reload()
            return
        }

        print("📋 Resetting \(tasksToReset.count) task(s)")

        let threshold = AppSettings.shared.makeItCountThreshold

        // Reset jeden Task
        for (index, task) in tasksToReset.enumerated() {
            // Entferne aus Kalender falls synchronisiert
            if task.isSyncedToCalendar {
                await syncEngine?.removeTaskFromCalendar(task)
            }

            let outcome = ResetOutcomePlanner.outcome(
                for: task.resetPlanInput,
                referenceDate: referenceDate,
                makeItCountThreshold: threshold,
                calendar: timeProvider.calendar
            )

            switch outcome {
            case .archive(let reason):
                // Nicht-wiederkehrend über der Make-It-Count-Schwelle → archivieren.
                task.resetCount += 1
                task.archive(reason: reason)
                hasArchivedAnyTask = true
                print("📦 Archived task '\(task.title)' after \(task.resetCount) incomplete day(s) on Today")
            case .returnToBacklog(let incrementsResetCount):
                if incrementsResetCount {
                    task.resetCount += 1
                }
                task.resetToBacklog()
                let offset = TimeInterval(-index) * 0.001
                task.sortPriority = referenceDate.addingTimeInterval(offset)
            case .none:
                break
            }
        }

        if hasArchivedAnyTask {
            AppSettings.shared.hasNewArchivedTasks = true
        }

        // Save Context
        do {
            try modelContext.save()
            print("✅ Reset completed successfully")
        } catch {
            print("❌ Failed to save reset: \(error)")
        }

        // Speichere Reset-Zeitpunkt und zähle Event für Review-Eligibility
        AppSettings.shared.totalResetEventCount += 1
        saveLastResetDate(referenceDate)

        // Widgets aus dem „Als-ob"-Zustand auf den echten Stand aktualisieren.
        WidgetRefresher.reload()

        // Der Reset hat Tasks verändert (Recurring → Backlog, resetCount, Archiv)
        // → UI-Listen neu laden lassen.
        NotificationCenter.default.post(name: .dawnyDidReset, object: nil)

        if hasArchivedAnyTask {
            NotificationCenter.default.post(name: .dawnyDidAutoArchiveTasks, object: nil)
        }
    }
    
    /// Registriert Background Task für automatischen Reset
    func registerBackgroundTask() {
        #if !targetEnvironment(simulator)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self = self else {
                task.setTaskCompleted(success: false)
                return
            }
            
            _Concurrency.Task {
                await self.performReset()
                task.setTaskCompleted(success: true)
                self.scheduleNextBackgroundReset()
            }
        }
        
        scheduleNextBackgroundReset()
        #endif
    }
    
    // MARK: - Private Methods
    
    /// Holt das Datum des letzten Resets aus UserDefaults (App Group, damit das Widget den Stand sieht)
    private func getLastResetDate() -> Date {
        if let lastReset = AppGroup.defaults.object(forKey: userDefaultsKey) as? Date {
            return lastReset
        }
        // Wenn noch nie resettet wurde, verwende ein Datum weit in der Vergangenheit
        return Date(timeIntervalSince1970: 0)
    }

    /// Speichert das Datum des letzten Resets in UserDefaults (App Group)
    private func saveLastResetDate(_ date: Date) {
        AppGroup.defaults.set(date, forKey: userDefaultsKey)
    }
    
    /// Berechnet den Zeitpunkt des letzten Reset-Schwellwerts
    /// Beispiel: Wenn jetzt 10:00 Uhr ist und resetHour=3, dann ist der Threshold heute 03:00
    /// Wenn jetzt 02:00 Uhr ist, dann ist der Threshold gestern 03:00
    private func calculateLastResetThreshold(for date: Date) -> Date {
        ResetSchedule.lastThreshold(
            before: date,
            resetHour: resetHour,
            calendar: timeProvider.calendar
        )
    }
    
    /// Auto-Tidy: Archiviert Backlog-Tasks, die die Lebensdauer ihrer Kategorie überschritten haben.
    /// Gibt die Anzahl archivierter Tasks zurück.
    private func archiveStaleBacklogTasks(referenceDate: Date) -> Int {
        let descriptor = FetchDescriptor<Task>()
        guard let all = try? modelContext.fetch(descriptor) else { return 0 }
        let threshold = AppSettings.shared.makeItCountThreshold
        var count = 0
        for task in all {
            let outcome = ResetOutcomePlanner.outcome(
                for: task.resetPlanInput,
                referenceDate: referenceDate,
                makeItCountThreshold: threshold,
                calendar: timeProvider.calendar
            )
            if outcome == .archive(.autoTidy) {
                task.archive(reason: .autoTidy)
                count += 1
            }
        }
        return count
    }

    /// Holt alle Tasks die resettet werden müssen
    private func fetchTasksNeedingReset() -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            // Filter manuell (Predicates mit Enums funktionieren nicht gut)
            return allTasks.filter { $0.status == .dailyFocus && !$0.isCompleted }
        } catch {
            print("❌ Failed to fetch tasks for reset: \(error)")
            return []
        }
    }
    
    /// Plant den nächsten Background-Reset
    private func scheduleNextBackgroundReset() {
        #if !targetEnvironment(simulator)
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        
        // Schedule für nächsten Reset-Zeitpunkt (z.B. morgen 3:05 AM)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day? += 1
        components.hour = resetHour
        components.minute = 5 // 5 Minuten nach Reset-Zeit
        
        if let nextResetTime = calendar.date(from: components) {
            request.earliestBeginDate = nextResetTime
            
            do {
                try BGTaskScheduler.shared.submit(request)
                print("📅 Scheduled next background reset for \(nextResetTime)")
            } catch {
                print("❌ Failed to schedule background task: \(error)")
            }
        }
        #endif
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let dawnyDidAutoArchiveTasks = Notification.Name("dawnyDidAutoArchiveTasks")
    /// Gepostet, nachdem ein Reset Tasks verändert hat. `ContentView` lädt darauf die ViewModel-Listen neu.
    static let dawnyDidReset = Notification.Name("dawnyDidReset")
}

// MARK: - Testing Helpers

extension ResetEngine {
    /// Setzt den letzten Reset-Zeitpunkt (nur für Tests)
    func setLastResetDate(_ date: Date) {
        saveLastResetDate(date)
    }
    
    /// Löscht den letzten Reset-Zeitpunkt (nur für Tests)
    func clearLastResetDate() {
        AppGroup.defaults.removeObject(forKey: userDefaultsKey)
    }
}
