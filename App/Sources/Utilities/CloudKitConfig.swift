// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  CloudKitConfig.swift
//  Dawny
//
//  Zentrale Definition des CloudKit-Containers für den optionalen iCloud-Sync.
//

import Foundation

/// Container-Identität für den optionalen Multi-Device-Sync.
///
/// Bewusst ohne `import CloudKit`: die Datei liegt auch im Widget-Target, weil
/// `IntentDataStore` dort mitkompiliert wird. Die Extension nimmt den CloudKit-Zweig
/// nie (siehe `IntentDataStore.shouldUseCloudKit`) und soll das Framework nicht laden.
/// Der eigentliche CloudKit-Zugriff liegt app-seitig in `CloudSyncStatus`.
enum CloudKitConfig {
    /// Muss exakt dem Container in Signing & Capabilities entsprechen.
    static let containerID = "iCloud.Florian.Dawny.MVP"

    /// True in Testläufen. Dort darf weder der CloudKit-Container noch der
    /// iCloud-Key-Value-Store angefasst werden: Tests verstellen Einstellungen
    /// reihenweise und seeden Daten, das würde sonst in die echte iCloud des
    /// Entwicklers wandern und auf dessen Geräte synchronisieren.
    ///
    /// Unit-Tests laufen im selben Prozess wie die App und sind an der
    /// XCTest-Umgebungsvariable erkennbar. UI-Tests starten die App als eigenen
    /// Prozess ohne diese Variable — sie setzen bereits `--uitesting`.
    static let isDisabledForTesting: Bool = {
        let info = ProcessInfo.processInfo
        return info.environment["XCTestConfigurationFilePath"] != nil
            || info.arguments.contains("--uitesting")
    }()
}
