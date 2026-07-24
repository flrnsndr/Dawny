// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  DawnyWidgetsBundle.swift
//  DawnyWidgets
//
//  Einstiegspunkt der Widget-Extension.
//

import SwiftUI
import WidgetKit

@main
struct DawnyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        BacklogWidget()
        ArchiveWidget()
    }
}
