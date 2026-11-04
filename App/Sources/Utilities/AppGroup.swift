// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  AppGroup.swift
//  Dawny
//
//  Zentrale Definition der App Group, über die App und Widget-Extension
//  denselben SwiftData-Store und dieselben UserDefaults teilen.
//

import Foundation

/// App-Group-Zugriff für App und Widget-Extension.
///
/// Solange das App-Group-Entitlement (noch) nicht gesetzt ist — etwa in einem
/// Build ohne die Capability — liefert `containerURL` `nil`. In diesem Fall fällt
/// alles transparent auf `UserDefaults.standard` und den Legacy-Store zurück,
/// sodass die App unverändert weiterläuft. Erst wenn der Container verfügbar ist
/// UND die Migration gelaufen ist (`isMigrated`), wird der geteilte Store benutzt.
enum AppGroup {
    /// Muss exakt der App-Group-ID in beiden Target-Entitlements entsprechen.
    static let identifier = "group.Florian.Dawny.MVP"

    /// Flag: Wurde der Store + die UserDefaults einmalig in den Group-Container migriert?
    static let migrationDoneKey = "DawnyAppGroupMigrationDone"

    /// Basis-Container der App Group (nil, wenn das Entitlement fehlt).
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    /// Geteilte UserDefaults-Suite. Fällt auf `.standard` zurück, wenn die App
    /// Group nicht verfügbar ist, damit ohne Entitlement nichts kaputtgeht.
    /// Einmal pro Prozess aufgelöst (der Entitlement-Status ändert sich zur Laufzeit nicht).
    static let defaults: UserDefaults = {
        guard containerURL != nil, let suite = UserDefaults(suiteName: identifier) else {
            return .standard
        }
        return suite
    }()

    /// Ziel-URL des geteilten SwiftData-Stores (nil ohne Entitlement).
    /// Legt bewusst denselben `Library/Application Support`-Pfad wie der
    /// Default-Store an, damit die Migration eine 1:1-Kopie ist.
    static var storeURL: URL? {
        containerURL?
            .appending(path: "Library/Application Support", directoryHint: .isDirectory)
            .appending(path: "default.store", directoryHint: .notDirectory)
    }

    /// True, sobald der geteilte Store benutzt werden darf.
    static var isMigrated: Bool {
        defaults.bool(forKey: migrationDoneKey)
    }

    /// True, wenn der Code in einer App-Extension (Widget) läuft (Bundle endet auf `.appex`).
    static var isRunningInAppExtension: Bool {
        Bundle.main.bundleURL.pathExtension == "appex"
    }
}
