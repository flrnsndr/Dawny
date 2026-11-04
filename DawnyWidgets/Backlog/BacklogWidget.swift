// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  BacklogWidget.swift
//  DawnyWidgets
//

import SwiftUI
import WidgetKit

struct BacklogWidget: Widget {
    static let kind = "DawnyBacklogWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: BacklogConfigurationIntent.self,
            provider: BacklogProvider()
        ) { entry in
            BacklogWidgetEntryView(entry: entry)
                .containerBackground(DawnyWidgetColor.cardBackground, for: .widget)
        }
        .configurationDisplayName(Text("widget.backlog.name"))
        .description(Text("widget.backlog.description"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
