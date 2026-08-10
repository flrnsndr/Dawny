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
}
