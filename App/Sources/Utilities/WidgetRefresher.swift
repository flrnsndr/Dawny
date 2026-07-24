// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  WidgetRefresher.swift
//  Dawny
//
//  Zentraler Anstoß für WidgetKit-Timeline-Reloads nach Datenänderungen.
//

import Foundation
import SwiftData
import WidgetKit

/// Fordert alle Dawny-Widgets auf, ihre Timelines neu zu laden.
///
/// WidgetKit koalesziert Reloads selbst; App-ausgelöste Reloads sind praktisch
/// unbudgetiert — deshalb kein eigenes Debouncing nötig.
enum WidgetRefresher {
    static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension ModelContext {
    /// Speichert den Kontext und lädt anschließend die Widget-Timelines neu.
    func saveAndRefreshWidgets() throws {
        try save()
        WidgetRefresher.reload()
    }
}
