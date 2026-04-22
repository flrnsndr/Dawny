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

struct SettingsView: View {
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
                synchronisationSection
                displaySection
                categorySection
                infoSection
            }
            .navigationTitle(String(localized: "settings.title", defaultValue: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onRequestShowWelcome {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                            onRequestShowWelcome()
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        .accessibilityLabel(String(localized: "settings.welcome.help", defaultValue: "Show welcome screen"))
                        .accessibilityIdentifier("SettingsShowWelcomeButton")
                    }
                }
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
            Section(String(localized: "settings.debug.section", defaultValue: "Debug")) {
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
    
    private var resetSection: some View {
        Section(String(localized: "settings.reset.section", defaultValue: "Reset")) {
            DatePicker(
                String(localized: "settings.reset.time", defaultValue: "Reset Time"),
                selection: $resetTime,
                displayedComponents: .hourAndMinute
            )
            .onChange(of: resetTime) { oldValue, newValue in
                let hour = Calendar.current.component(.hour, from: newValue)
                settings.resetHour = hour
            }
            
            Text(String(localized: "settings.reset.description", defaultValue: "Uncompleted tasks will be moved back to the backlog daily at this time."))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var synchronisationSection: some View {
        Section(String(localized: "settings.sync.section", defaultValue: "Synchronization")) {
            Toggle(String(localized: "settings.sync.toggle", defaultValue: "Calendar Sync"), isOn: $settings.calendarSyncEnabled)
            
            Text(String(localized: "settings.sync.description", defaultValue: "Synchronizes Daily Focus tasks with iOS Reminders."))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var displaySection: some View {
        Section(String(localized: "settings.display.section", defaultValue: "Display")) {
            Toggle(String(localized: "settings.display.toggle", defaultValue: "Show Completed Tasks"), isOn: $settings.showCompletedTasksInToday)
            
            Text(String(localized: "settings.display.description", defaultValue: "Shows completed tasks in the Today tab."))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var categorySection: some View {
        Section(String(localized: "settings.category.section", defaultValue: "Backlog Categories")) {
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
            
            Text(String(localized: "settings.category.description", defaultValue: "Organize your backlog tasks into categories."))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var infoSection: some View {
        Section(String(localized: "settings.info.section", defaultValue: "Info")) {
            HStack {
                Text(String(localized: "settings.info.version", defaultValue: "Version"))
                Spacer()
                Text(appVersion)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(String(localized: "settings.info.build", defaultValue: "Build"))
                Spacer()
                Text(appBuild)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? String(localized: "settings.info.unknown", defaultValue: "Unknown")
    }
    
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? String(localized: "settings.info.unknown", defaultValue: "Unknown")
    }
}
