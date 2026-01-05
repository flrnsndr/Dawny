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
        
        // Fetch alle Tasks die resettet werden müssen
        let tasksToReset = fetchTasksNeedingReset()
        
        guard !tasksToReset.isEmpty else {
            print("✅ No tasks need reset")
            saveLastResetDate(referenceDate)
            return
        }
        
        print("📋 Resetting \(tasksToReset.count) task(s)")
        
        // Reset jeden Task
        for (index, task) in tasksToReset.enumerated() {
            // Entferne aus Kalender falls synchronisiert
            if task.isSyncedToCalendar {
                await syncEngine?.removeTaskFromCalendar(task)
            }
            
            // Reset Task Status
            task.resetToBacklog()
            
            // Setze sortPriority mit kleinem Offset für Ordnung
            // Neuere Resets kommen weiter oben, aber innerhalb eines Resets
            // wird die relative Ordnung beibehalten
            let offset = TimeInterval(-index) * 0.001 // Millisekunden-Offset
            task.sortPriority = referenceDate.addingTimeInterval(offset)
        }
        
        // Save Context
        do {
            try modelContext.save()
            print("✅ Reset completed successfully")
        } catch {
            print("❌ Failed to save reset: \(error)")
        }
        
        // Speichere Reset-Zeitpunkt
        saveLastResetDate(referenceDate)
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
    
    /// Holt das Datum des letzten Resets aus UserDefaults
    private func getLastResetDate() -> Date {
        if let lastReset = UserDefaults.standard.object(forKey: userDefaultsKey) as? Date {
            return lastReset
        }
        // Wenn noch nie resettet wurde, verwende ein Datum weit in der Vergangenheit
        return Date(timeIntervalSince1970: 0)
    }
    
    /// Speichert das Datum des letzten Resets in UserDefaults
    private func saveLastResetDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: userDefaultsKey)
    }
    
    /// Berechnet den Zeitpunkt des letzten Reset-Schwellwerts
    /// Beispiel: Wenn jetzt 10:00 Uhr ist und resetHour=3, dann ist der Threshold heute 03:00
    /// Wenn jetzt 02:00 Uhr ist, dann ist der Threshold gestern 03:00
    private func calculateLastResetThreshold(for date: Date) -> Date {
        let calendar = timeProvider.calendar
        
        // Hole die aktuelle Stunde
        let currentHour = calendar.component(.hour, from: date)
        
        // Erstelle ein Datum für heute um resetHour
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = resetHour
        components.minute = 0
        components.second = 0
        
        guard var resetToday = calendar.date(from: components) else {
            return date
        }
        
        // Wenn wir vor dem Reset-Zeitpunkt sind, verwende gestrigen Reset
        if currentHour < resetHour {
            resetToday = calendar.date(byAdding: .day, value: -1, to: resetToday) ?? resetToday
        }
        
        return resetToday
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

// MARK: - Testing Helpers

extension ResetEngine {
    /// Setzt den letzten Reset-Zeitpunkt (nur für Tests)
    func setLastResetDate(_ date: Date) {
        saveLastResetDate(date)
    }
    
    /// Löscht den letzten Reset-Zeitpunkt (nur für Tests)
    func clearLastResetDate() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
