// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  SettingsView.swift
//  Dawny
//
//  Settings-Seite für App-Konfiguration
//

import SwiftUI
import UIKit

struct SettingsView: View {

    private static let makeItCountThresholdRange = 1...7
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    let onRequestAddTestItems: (() -> Void)?
    let onRequestDeleteAll: (() -> Void)?
    let onRequestShowWelcome: (() -> Void)?

    @State private var resetTime: Date
    
    init(
        settings: AppSettings = .shared,
        onRequestAddTestItems: (() -> Void)? = nil,
        onRequestDeleteAll: (() -> Void)? = nil,
        onRequestShowWelcome: (() -> Void)? = nil
    ) {
        self.settings = settings
        self.onRequestAddTestItems = onRequestAddTestItems
        self.onRequestDeleteAll = onRequestDeleteAll
        self.onRequestShowWelcome = onRequestShowWelcome
        
        // Initialisiere resetTime basierend auf resetHour
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = settings.resetHour
        components.minute = 0
        components.second = 0
        self._resetTime = State(initialValue: calendar.date(from: components) ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                debugSection
                resetSection
                makeItCountSection
                synchronisationSection
                appearanceSection
            }
            .listSectionSpacing(.compact)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                settingsBottomChrome
            }
            .navigationTitle(String(localized: "settings.title", defaultValue: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "settings.done", defaultValue: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Sections

    @ViewBuilder
    private var debugSection: some View {
        if onRequestAddTestItems != nil || onRequestDeleteAll != nil {
            Section {
                if let onRequestAddTestItems {
                    Button {
                        onRequestAddTestItems()
                        dismiss()
                    } label: {
                        Label(
                            String(localized: "quickadd.addtestitems", defaultValue: "Add Test Items"),
                            systemImage: "wand.and.stars"
                        )
                    }
                }

                if let onRequestDeleteAll {
                    Button(role: .destructive) {
                        onRequestDeleteAll()
                        dismiss()
                    } label: {
                        Label(
                            String(localized: "quickadd.deleteall", defaultValue: "Delete All Tasks"),
                            systemImage: "trash"
                        )
                    }
                }
            }
        }
    }
    
    private var makeItCountSection: some View {
        Section {
            HStack(alignment: .center, spacing: 12) {
                Text(String(localized: "settings.makeitcount.label", defaultValue: "Make it count. Archive a task if it was incomplete on Today."))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                makeItCountThresholdPill
            }
        }
    }

    private var makeItCountThresholdPill: some View {
        let range = Self.makeItCountThresholdRange
        return HStack(spacing: 0) {
            Button {
                if settings.makeItCountThreshold > range.lowerBound {
                    settings.makeItCountThreshold -= 1
                }
            } label: {
                Image(systemName: "minus")
                    .font(.body.weight(.medium))
                    .frame(width: 38, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(settings.makeItCountThreshold <= range.lowerBound)

            makeItCountPillDivider

            Text("\(settings.makeItCountThreshold)")
                .font(.body.weight(.medium))
                .monospacedDigit()
                .frame(minWidth: 26)

            makeItCountPillDivider

            Button {
                if settings.makeItCountThreshold < range.upperBound {
                    settings.makeItCountThreshold += 1
                }
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.medium))
                    .frame(width: 38, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(settings.makeItCountThreshold >= range.upperBound)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
        .background(Color(uiColor: .secondarySystemFill))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("SettingsMakeItCountThreshold")
    }

    private var makeItCountPillDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(width: 1, height: 22)
    }

    private var resetSection: some View {
        Section {
            DatePicker(
                String(localized: "settings.reset.time", defaultValue: "Time for daily reset"),
                selection: $resetTime,
                displayedComponents: .hourAndMinute
            )
            .onChange(of: resetTime) { oldValue, newValue in
                let hour = Calendar.current.component(.hour, from: newValue)
                settings.resetHour = hour
            }
        }
    }
    
    private var synchronisationSection: some View {
        Section {
            Toggle(String(localized: "settings.sync.toggle", defaultValue: "Calendar Sync"), isOn: $settings.calendarSyncEnabled)
        } footer: {
            Text(String(localized: "settings.sync.description", defaultValue: "Synchronizes Daily Focus tasks with iOS Reminders."))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var appearanceSection: some View {
        Section {
            Toggle(String(localized: "settings.display.toggle", defaultValue: "Show Completed Tasks"), isOn: $settings.showCompletedTasksInToday)
            Toggle(String(localized: "settings.category.toggle", defaultValue: "Show Categories"), isOn: $settings.showCategories)

            if settings.showCategories {
                Picker(String(localized: "settings.category.default", defaultValue: "Default Category for New Tasks"), selection: $settings.defaultCategoryType) {
                    ForEach(TaskCategory.allCases.filter { $0 != .uncategorized && $0 != .custom }, id: \.self) { category in
                        HStack {
                            Image(systemName: category.iconName)
                            Text(category.displayName)
                        }
                        .tag(category)
                    }
                }
            }
        }
    }
    
    private var settingsBottomChrome: some View {
        VStack(spacing: 10) {
            if let onRequestShowWelcome {
                Button {
                    dismiss()
                    onRequestShowWelcome()
                } label: {
                    Text(String(localized: "settings.welcome.showAgain", defaultValue: "Show welcome message again"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("SettingsShowWelcomeButton")
            }

            Text(versionBuildFooterLine)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(versionBuildAccessibilityLabel)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var versionBuildFooterLine: String {
        "\(appVersion) (\(appBuild))"
    }

    private var versionBuildAccessibilityLabel: String {
        let versionLabel = String(localized: "settings.info.version", defaultValue: "Version")
        let buildLabel = String(localized: "settings.info.build", defaultValue: "Build")
        return "\(versionLabel) \(appVersion), \(buildLabel) \(appBuild)"
    }

    // MARK: - Computed Properties
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? String(localized: "settings.info.unknown", defaultValue: "Unknown")
    }
    
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? String(localized: "settings.info.unknown", defaultValue: "Unknown")
    }
}
