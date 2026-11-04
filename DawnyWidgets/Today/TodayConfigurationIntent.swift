// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  TodayConfigurationIntent.swift
//  DawnyWidgets
//

import AppIntents
import WidgetKit

/// Wie der Reset-Hinweis im Heute-Widget dargestellt wird (per langem Drücken → Bearbeiten).
enum ResetHintMode: String, AppEnum {
    /// Kleines `archivebox` rechts an jeder Aufgabe, die heute Nacht ins Archiv wandert (Default).
    case perTaskSymbol
    /// Eine Hinweis-Zeile im Footer.
    case footerLine
    /// Kein Hinweis.
    case off

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(
        name: "widget.today.hint.type"
    )

    static var caseDisplayRepresentations: [ResetHintMode: DisplayRepresentation] = [
        .perTaskSymbol: DisplayRepresentation(title: "widget.today.hint.pertask"),
        .footerLine: DisplayRepresentation(title: "widget.today.hint.footer"),
        .off: DisplayRepresentation(title: "widget.today.hint.off")
    ]
}

struct TodayConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.today.config.title"
    static var description = IntentDescription("widget.today.config.description")

    @Parameter(title: "widget.today.config.resethint", default: .perTaskSymbol)
    var resetHint: ResetHintMode
}
