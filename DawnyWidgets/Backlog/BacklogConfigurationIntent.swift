// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  BacklogConfigurationIntent.swift
//  DawnyWidgets
//

import AppIntents
import WidgetKit

struct BacklogConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.backlog.config.title"
    static var description = IntentDescription("widget.backlog.config.description")

    /// Im Medium standardmäßig gezeigte Kategorie (leer = erste nicht-leere).
    @Parameter(title: "widget.backlog.config.category")
    var category: CategoryAppEntity?

    /// Chevron-Kategorie-Navigation im Widget aktivieren (Default aus).
    @Parameter(title: "widget.backlog.config.navigation", default: false)
    var showNavigation: Bool
}
