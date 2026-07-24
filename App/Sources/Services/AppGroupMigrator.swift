// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  AppGroupMigrator.swift
//  Dawny
//
//  Einmalige, defensive Migration des SwiftData-Stores und der UserDefaults
//  aus dem app-lokalen Verzeichnis in die geteilte App Group.
//

import Foundation

/// Migriert Store + UserDefaults einmalig in den App-Group-Container.
///
/// Design (die App ist im Store live — Datenverlust ist inakzeptabel):
/// - **Kopieren statt Verschieben:** der Legacy-Store bleibt als Backup erhalten.
/// - **Flag zuletzt:** `AppGroup.migrationDoneKey` wird erst nach vollständigem Erfolg gesetzt.
/// - **Rollback bei Teilkopie:** schlägt das Kopieren fehl, werden angefangene Zieldateien
///   entfernt und die Migration beim nächsten Start erneut versucht; bis dahin nutzt
///   `IntentDataStore.makeModelContainer` weiter den Legacy-Store.
/// - **Fresh Install:** ohne Legacy-Store wird nur das Flag gesetzt.
/// - **Kein Entitlement:** ohne App Group ist `storeURL` nil → No-Op, alles bleibt lokal.
///
/// Muss **vor** dem ersten `IntentDataStore.makeModelContainer()` laufen.
enum AppGroupMigrator {

    static func migrateIfNeeded() {
        guard !AppGroup.isMigrated, let groupStore = AppGroup.storeURL else { return }

        let fileManager = FileManager.default
        let legacyStore = URL.applicationSupportDirectory
            .appending(path: "default.store", directoryHint: .notDirectory)

        // Store-Dateien kopieren, falls ein Legacy-Store existiert.
        if fileManager.fileExists(atPath: legacyStore.path) {
            do {
                try fileManager.createDirectory(
                    at: groupStore.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                // -shm / -wal gehören zum WAL-Journal von SQLite und müssen mitkopiert werden.
                for suffix in ["", "-shm", "-wal"] {
                    let source = URL(fileURLWithPath: legacyStore.path + suffix)
                    let destination = URL(fileURLWithPath: groupStore.path + suffix)
                    // Etwaige verirrte Zieldatei entfernen: vor gesetztem Flag kann im
                    // Group-Container nichts Legitimes liegen (z. B. von einem Widget-Prozess,
                    // der vor der ersten App-Migration lief — der ist aber gesperrt, s. IntentDataStore).
                    if fileManager.fileExists(atPath: destination.path) {
                        try fileManager.removeItem(at: destination)
                    }
                    if fileManager.fileExists(atPath: source.path) {
                        try fileManager.copyItem(at: source, to: destination)
                    }
                }
            } catch {
                // Teilkopie zurückrollen, Flag NICHT setzen → Retry beim nächsten Start.
                for suffix in ["", "-shm", "-wal"] {
                    try? fileManager.removeItem(atPath: groupStore.path + suffix)
                }
                print("⚠️ App-Group-Store-Migration fehlgeschlagen, wird erneut versucht: \(error)")
                return
            }
        }

        migrateDefaults()
        AppGroup.defaults.set(true, forKey: AppGroup.migrationDoneKey)
        print("✅ App-Group-Migration abgeschlossen")
    }

    /// Kopiert bestehende Werte aus `.standard` in die geteilte Suite (nur wenn dort noch nicht vorhanden).
    private static func migrateDefaults() {
        let source = UserDefaults.standard
        let destination = AppGroup.defaults
        guard source !== destination else { return }

        var keys = AppSettings.Keys.allKeys
        keys.append("DawnyLastResetDate")
        keys.append(contentsOf: CategoryService.migrationFlagKeys)

        for key in keys where destination.object(forKey: key) == nil {
            if let value = source.object(forKey: key) {
                destination.set(value, forKey: key)
            }
        }
    }
}
