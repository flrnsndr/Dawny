// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  SelectTodayTabEnvironment.swift
//  Dawny
//
//  Environment-Callback zum Umschalten auf den „Heute“-Tab (z. B. nach UI-Testworkflow).
//

import SwiftUI

private struct SelectTodayTabKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var selectTodayTab: () -> Void {
        get { self[SelectTodayTabKey.self] }
        set { self[SelectTodayTabKey.self] = newValue }
    }
}
