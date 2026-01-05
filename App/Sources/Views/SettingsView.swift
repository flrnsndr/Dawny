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
    
    @State private var resetTime: Date
    
    init(settings: AppSettings = .shared) {
        self.settings = settings
        
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
                resetSection
                synchronisationSection
                displaySection
                infoSection
            }
            .navigationTitle(String(localized: "settings.title", defaultValue: "Einstellungen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "settings.done", defaultValue: "Fertig")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var resetSection: some View {
        Section(String(localized: "settings.reset.section", defaultValue: "Reset")) {
            DatePicker(
                String(localized: "settings.reset.time", defaultValue: "Reset-Zeit"),
                selection: $resetTime,
                displayedComponents: .hourAndMinute
            )
            .onChange(of: resetTime) { oldValue, newValue in
                let hour = Calendar.current.component(.hour, from: newValue)
                settings.resetHour = hour
            }
            
            Text(String(localized: "settings.reset.description", defaultValue: "Nicht erledigte Tasks werden täglich um diese Uhrzeit zurück ins Backlog verschoben."))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var synchronisationSection: some View {
        Section(String(localized: "settings.sync.section", defaultValue: "Synchronisation")) {
            Toggle(String(localized: "settings.sync.toggle", defaultValue: "Kalender-Synchronisation"), isOn: $settings.calendarSyncEnabled)
            
            Text(String(localized: "settings.sync.description", defaultValue: "Synchronisiert Daily Focus Tasks mit iOS Erinnerungen."))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var displaySection: some View {
        Section(String(localized: "settings.display.section", defaultValue: "Anzeige")) {
            Toggle(String(localized: "settings.display.toggle", defaultValue: "Erledigte Tasks anzeigen"), isOn: $settings.showCompletedTasksInToday)
            
            Text(String(localized: "settings.display.description", defaultValue: "Zeigt erledigte Tasks im Heute-Tab an."))
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
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? String(localized: "settings.info.unknown", defaultValue: "Unbekannt")
    }
    
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? String(localized: "settings.info.unknown", defaultValue: "Unbekannt")
    }
}

