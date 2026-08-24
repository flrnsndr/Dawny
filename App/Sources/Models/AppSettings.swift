// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  AppSettings.swift
//  Dawny
//
//  App-Einstellungen mit UserDefaults-Persistenz
//

import Foundation
import Observation

/// Verwaltet App-Einstellungen mit UserDefaults-Persistenz
@Observable
final class AppSettings {
    // MARK: - UserDefaults Keys

    /// Nicht `private`, damit der `AppGroupMigrator` die Werte in die geteilte Suite kopieren kann.
    enum Keys {
        static let resetHour = "DawnyResetHour"
        static let calendarSyncEnabled = "DawnyCalendarSyncEnabled"
        static let iCloudSyncEnabled = "DawnyICloudSyncEnabled"
        static let showCompletedTasksInToday = "DawnyShowCompletedTasksInToday"
        static let showCategories = "DawnyShowCategories"
        static let defaultCategoryType = "DawnyDefaultCategoryType"
        static let hasSeenWelcome = "DawnyHasSeenWelcome"
        static let makeItCountThreshold = "DawnyMakeItCountThreshold"
        static let hasNewArchivedTasks = "DawnyHasNewArchivedTasks"
        static let lastArchiveVisitDate = "DawnyLastArchiveVisitDate"
        static let appLaunchCount = "DawnyAppLaunchCount"
        static let totalResetEventCount = "DawnyTotalResetEventCount"
        static let lastReviewPromptDate = "DawnyLastReviewPromptDate"

        /// Alle Keys — vom `AppGroupMigrator` genutzt, um bestehende Werte in die App-Group-Suite zu übernehmen.
        static let allKeys: [String] = [
            resetHour, calendarSyncEnabled, iCloudSyncEnabled, showCompletedTasksInToday, showCategories,
            defaultCategoryType, hasSeenWelcome, makeItCountThreshold, hasNewArchivedTasks,
            lastArchiveVisitDate, appLaunchCount, totalResetEventCount, lastReviewPromptDate
        ]
    }

    /// Keys im iCloud-Key-Value-Store. Bewusst getrennt von den lokalen Keys:
    /// nur die drei verhaltensrelevanten Werte wandern zwischen Geräten, weil
    /// der nächtliche Reset auf allen Geräten dieselben Parameter braucht
    /// (sonst können zwei Geräte widersprüchliche Ergebnisse schreiben).
    enum CloudKeys {
        static let resetHour = "DawnyKVSResetHour"
        static let makeItCountThreshold = "DawnyKVSMakeItCountThreshold"
        static let defaultCategoryType = "DawnyKVSDefaultCategoryType"
    }

    // MARK: - Properties

    /// Reset-Zeit in Stunden (0-23)
    var resetHour: Int {
        didSet {
            AppGroup.defaults.set(resetHour, forKey: Keys.resetHour)
            pushToCloud(resetHour, forKey: CloudKeys.resetHour)
        }
    }
    
    /// Kalender-Synchronisation aktiviert
    var calendarSyncEnabled: Bool {
        didSet {
            AppGroup.defaults.set(calendarSyncEnabled, forKey: Keys.calendarSyncEnabled)
        }
    }
    
    /// iCloud-Sync über CloudKit aktiviert (Opt-out, Standard: an).
    /// Bewusst gerätelokal: jedes Gerät entscheidet selbst, ob es syncen soll.
    /// Wird erst beim nächsten App-Start wirksam, weil der `ModelContainer`
    /// einmalig in `DawnyApp.init()` gebaut wird.
    var iCloudSyncEnabled: Bool {
        didSet {
            AppGroup.defaults.set(iCloudSyncEnabled, forKey: Keys.iCloudSyncEnabled)
        }
    }

    /// Erledigte Tasks im Heute-Tab anzeigen
    var showCompletedTasksInToday: Bool {
        didSet {
            AppGroup.defaults.set(showCompletedTasksInToday, forKey: Keys.showCompletedTasksInToday)
        }
    }
    
    /// Kategorien im Backlog anzeigen
    var showCategories: Bool {
        didSet {
            AppGroup.defaults.set(showCategories, forKey: Keys.showCategories)
        }
    }
    
    /// Welcome Screen wurde bereits angezeigt
    var hasSeenWelcome: Bool {
        didSet {
            AppGroup.defaults.set(hasSeenWelcome, forKey: Keys.hasSeenWelcome)
        }
    }

    /// Anzahl der fehlgeschlagenen Resets, bevor ein Task archiviert wird (1–7, Standard: 1)
    var makeItCountThreshold: Int {
        didSet {
            AppGroup.defaults.set(makeItCountThreshold, forKey: Keys.makeItCountThreshold)
            pushToCloud(makeItCountThreshold, forKey: CloudKeys.makeItCountThreshold)
        }
    }

    /// Zeigt an ob beim letzten Reset neue Tasks ins Archiv verschoben wurden (Dot-Badge)
    var hasNewArchivedTasks: Bool {
        didSet {
            AppGroup.defaults.set(hasNewArchivedTasks, forKey: Keys.hasNewArchivedTasks)
        }
    }
    
    /// Zeitpunkt des letzten Archiv-Besuchs (Watermark für die Row-Dots im Archiv).
    /// Tasks mit `archivedAt` nach diesem Zeitpunkt gelten als "neu" und zeigen einen Dot.
    var lastArchiveVisitDate: Date {
        didSet {
            AppGroup.defaults.set(lastArchiveVisitDate, forKey: Keys.lastArchiveVisitDate)
        }
    }

    /// Anzahl der App-Starts (für Review-Prompt-Eligibility)
    var appLaunchCount: Int {
        didSet {
            AppGroup.defaults.set(appLaunchCount, forKey: Keys.appLaunchCount)
        }
    }

    /// Anzahl abgeschlossener Reset-Events (für Review-Prompt-Eligibility)
    var totalResetEventCount: Int {
        didSet {
            AppGroup.defaults.set(totalResetEventCount, forKey: Keys.totalResetEventCount)
        }
    }

    /// Datum des letzten Review-Prompts (Rate-Limiting)
    var lastReviewPromptDate: Date? {
        didSet {
            AppGroup.defaults.set(lastReviewPromptDate, forKey: Keys.lastReviewPromptDate)
        }
    }

    /// Standard-Kategorie für neue Tasks (wenn Kategorien aktiviert)
    var defaultCategoryType: TaskCategory {
        didSet {
            if let encoded = try? JSONEncoder().encode(defaultCategoryType.rawValue) {
                AppGroup.defaults.set(encoded, forKey: Keys.defaultCategoryType)
            }
            pushToCloud(defaultCategoryType.rawValue, forKey: CloudKeys.defaultCategoryType)
        }
    }
    
    // MARK: - iCloud sync state

    /// Injizierbar für Tests. `nil` = im Betrieb erst bei aktiviertem Sync auflösen,
    /// damit Tests und Nicht-Sync-Nutzer den echten Store nie anfassen.
    @ObservationIgnored private let injectedCloudStore: UbiquitousKeyValueStoring?

    /// Verhindert Ping-Pong: Werte, die gerade aus der Cloud übernommen werden,
    /// dürfen nicht sofort wieder hochgeschrieben werden.
    @ObservationIgnored private var isApplyingCloudValues = false

    @ObservationIgnored private var cloudObserver: NSObjectProtocol?

    // MARK: - Initializer

    init(cloudStore: UbiquitousKeyValueStoring? = nil) {
        self.injectedCloudStore = cloudStore

        // Lade Werte aus UserDefaults oder verwende Defaults
        self.resetHour = AppGroup.defaults.object(forKey: Keys.resetHour) as? Int ?? 3
        self.calendarSyncEnabled = AppGroup.defaults.object(forKey: Keys.calendarSyncEnabled) as? Bool ?? true
        // Opt-out: standardmäßig an. `bool(forKey:)` liefert bei fehlendem Key
        // `false`, deshalb hier explizit über `object(forKey:)`.
        self.iCloudSyncEnabled = AppGroup.defaults.object(forKey: Keys.iCloudSyncEnabled) as? Bool ?? true
        self.showCompletedTasksInToday = AppGroup.defaults.object(forKey: Keys.showCompletedTasksInToday) as? Bool ?? true
        self.showCategories = AppGroup.defaults.object(forKey: Keys.showCategories) as? Bool ?? true
        self.hasSeenWelcome = AppGroup.defaults.bool(forKey: Keys.hasSeenWelcome)
        self.makeItCountThreshold = AppGroup.defaults.object(forKey: Keys.makeItCountThreshold) as? Int ?? 1
        self.hasNewArchivedTasks = AppGroup.defaults.bool(forKey: Keys.hasNewArchivedTasks)
        // Watermark einmalig mit "jetzt" seeden UND persistieren: Ohne Zurückschreiben
        // würde jeder App-Start die Marke neu setzen und Dots aus früheren Sessions löschen.
        // Bestandsnutzer: vor dem Update archivierte Tasks bekommen so keinen Dot-Sturm.
        if let storedVisit = AppGroup.defaults.object(forKey: Keys.lastArchiveVisitDate) as? Date {
            self.lastArchiveVisitDate = storedVisit
        } else {
            let now = Date()
            self.lastArchiveVisitDate = now
            AppGroup.defaults.set(now, forKey: Keys.lastArchiveVisitDate)
        }
        self.appLaunchCount = AppGroup.defaults.object(forKey: Keys.appLaunchCount) as? Int ?? 0
        self.totalResetEventCount = AppGroup.defaults.object(forKey: Keys.totalResetEventCount) as? Int ?? 0
        self.lastReviewPromptDate = AppGroup.defaults.object(forKey: Keys.lastReviewPromptDate) as? Date
        
        // Lade defaultCategoryType
        if let data = AppGroup.defaults.data(forKey: Keys.defaultCategoryType),
           let rawValue = try? JSONDecoder().decode(String.self, from: data),
           let categoryType = TaskCategory(rawValue: rawValue) {
            self.defaultCategoryType = categoryType
        } else {
            self.defaultCategoryType = .quick
        }
    }
    
    // MARK: - iCloud Key-Value Sync

    private var cloudStore: UbiquitousKeyValueStoring? {
        if let injectedCloudStore { return injectedCloudStore }
        guard iCloudSyncEnabled, !CloudKitConfig.isDisabledForTesting else { return nil }
        return NSUbiquitousKeyValueStore.default
    }

    /// Startet die Settings-Synchronisation. Wird beim App-Start aufgerufen.
    ///
    /// Beim ersten Lauf mit aktiviertem Sync gewinnen vorhandene Cloud-Werte über
    /// die lokalen — so übernimmt ein neu hinzugefügtes Gerät deterministisch die
    /// Einstellungen des ersten. Fehlt ein Wert in der Cloud, wird der lokale
    /// hochgeschoben.
    func activateCloudSyncIfEnabled() {
        guard iCloudSyncEnabled, let store = cloudStore else { return }

        store.synchronize()
        adoptCloudValues(from: store)
        pushMissingValues(to: store)
        startObservingCloudChanges(store)
    }

    /// Übernimmt alle in der Cloud vorhandenen Werte.
    private func adoptCloudValues(from store: UbiquitousKeyValueStoring) {
        isApplyingCloudValues = true
        defer { isApplyingCloudValues = false }

        if let hour = store.object(forKey: CloudKeys.resetHour) as? Int, hour != resetHour {
            resetHour = hour
        }
        if let threshold = store.object(forKey: CloudKeys.makeItCountThreshold) as? Int,
           threshold != makeItCountThreshold {
            makeItCountThreshold = threshold
        }
        if let raw = store.object(forKey: CloudKeys.defaultCategoryType) as? String,
           let category = TaskCategory(rawValue: raw),
           category != defaultCategoryType {
            defaultCategoryType = category
        }
    }

    /// Schreibt lokale Werte hoch, die in der Cloud noch fehlen.
    private func pushMissingValues(to store: UbiquitousKeyValueStoring) {
        var didWrite = false
        if store.object(forKey: CloudKeys.resetHour) == nil {
            store.set(resetHour, forKey: CloudKeys.resetHour)
            didWrite = true
        }
        if store.object(forKey: CloudKeys.makeItCountThreshold) == nil {
            store.set(makeItCountThreshold, forKey: CloudKeys.makeItCountThreshold)
            didWrite = true
        }
        if store.object(forKey: CloudKeys.defaultCategoryType) == nil {
            store.set(defaultCategoryType.rawValue, forKey: CloudKeys.defaultCategoryType)
            didWrite = true
        }
        if didWrite {
            store.synchronize()
        }
    }

    private func startObservingCloudChanges(_ store: UbiquitousKeyValueStoring) {
        guard cloudObserver == nil else { return }
        cloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.adoptCloudValues(from: store)
        }
    }

    private func pushToCloud(_ value: Any, forKey key: String) {
        guard !isApplyingCloudValues, iCloudSyncEnabled, let store = cloudStore else { return }
        store.set(value, forKey: key)
        store.synchronize()
    }

    // MARK: - Computed

    /// True wenn alle Bedingungen für den Review-Prompt erfüllt sind
    var isEligibleForReviewPrompt: Bool {
        guard appLaunchCount >= 5, totalResetEventCount >= 2 else { return false }
        if let last = lastReviewPromptDate {
            return Date().timeIntervalSince(last) >= 60 * 60 * 24 * 60
        }
        return true
    }

    // MARK: - Singleton

    /// Shared Instance für App-weite Nutzung
    static let shared = AppSettings()
}

