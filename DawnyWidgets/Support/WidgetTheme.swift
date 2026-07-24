// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  WidgetTheme.swift
//  DawnyWidgets
//
//  Design-Tokens (Richtung 1a) und wiederverwendbare Widget-Bausteine.
//

import SwiftUI
import WidgetKit

enum DawnyWidgetFont {
    static let title = Font.system(size: 13, weight: .semibold)
    static let taskTitle = Font.system(size: 14, weight: .regular)
    static let bigCounter = Font.system(size: 34, weight: .bold)
    static let counterLabel = Font.system(size: 13, weight: .regular)
    static let meta = Font.system(size: 11, weight: .regular)
    static let footer = Font.system(size: 10, weight: .regular)
    static let sectionLabel = Font.system(size: 11, weight: .semibold)
}

enum DawnyWidgetColor {
    /// Dawny-Orange (== #FF9500 / #FF9F0A). Bewusst `.orange`, kein AccentColor-Asset.
    static let accent = Color.orange
    static let done = Color.green
    static let backlogTint = Color(.systemIndigo)
    static let cardBackground = Color(.systemBackground)
    /// Fortschrittsbalken-Verlauf im Large-Heute-Widget (#FFB340 → #FF9500).
    static let progressGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.70, blue: 0.25), Color(red: 1.0, green: 0.584, blue: 0.0)],
        startPoint: .leading, endPoint: .trailing
    )
}

/// Kopfzeile: Icon + Titel links, optionaler sekundärer Text rechts.
struct WidgetHeader: View {
    let iconName: String
    let iconColor: Color
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
            Text(title)
                .font(DawnyWidgetFont.title)
                .foregroundStyle(.primary)
            Spacer(minLength: 4)
            if let trailing {
                Text(trailing)
                    .font(DawnyWidgetFont.counterLabel)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

/// Leerer Checkbox-Kreis (nicht interaktiv, für nicht-abhakbare Größen).
struct WidgetCheckCircle: View {
    let isDone: Bool
    var body: some View {
        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 16))
            .foregroundStyle(isDone ? DawnyWidgetColor.done : Color(.tertiaryLabel))
    }
}

/// Footer-Zeile mit Icon + Text (z. B. „Reset um 3:00").
struct WidgetFooterHint: View {
    let iconName: String
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 10))
            Text(text)
                .font(DawnyWidgetFont.footer)
        }
        .foregroundStyle(.tertiary)
    }
}

/// Platzhalter, solange der geteilte Store noch nicht migriert ist (App einmal öffnen).
struct WidgetNeedsLaunchView: View {
    let iconName: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 26))
                .foregroundStyle(DawnyWidgetColor.accent)
            Text(WidgetStrings.openDawny)
                .font(DawnyWidgetFont.counterLabel)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Rendert einen Widget-`Toggle` als Checkbox-Kreis + Label (optimistische Animation gratis).
struct WidgetCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 9) {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundStyle(configuration.isOn ? DawnyWidgetColor.done : Color(.tertiaryLabel))
            configuration.label
        }
    }
}

/// Deep-Link-Ziele in die App.
enum DawnyDeepLink {
    static let today = URL(string: "dawny://today")!
    static let backlog = URL(string: "dawny://backlog")!
    static let archive = URL(string: "dawny://archive")!
}
