// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  TodayWidget.swift
//  DawnyWidgets
//

import SwiftUI
import WidgetKit

struct TodayWidget: Widget {
    static let kind = "DawnyTodayWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: TodayConfigurationIntent.self,
            provider: TodayProvider()
        ) { entry in
            TodayWidgetEntryView(entry: entry)
                .containerBackground(DawnyWidgetColor.cardBackground, for: .widget)
        }
        .configurationDisplayName(Text("widget.today.name"))
        .description(Text("widget.today.description"))
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryRectangular, .accessoryCircular
        ])
    }
}
