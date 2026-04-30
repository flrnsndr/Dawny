// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  TriggerWelcomeFlowEnvironment.swift
//  Dawny
//
//  Environment-Callback zum Starten des Welcome-Screen-Workflows aus den Einstellungen.
//

import SwiftUI

private struct TriggerWelcomeFlowKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var triggerWelcomeFlow: () -> Void {
        get { self[TriggerWelcomeFlowKey.self] }
        set { self[TriggerWelcomeFlowKey.self] = newValue }
    }
}
