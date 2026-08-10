// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  SettingsView.swift
//  Dawny
//
//  Settings-Seite für App-Konfiguration
//

import SwiftUI
import UIKit
import MessageUI

struct SettingsView: View {

    private static let makeItCountThresholdRange = 1...7
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    let onRequestAddTestItems: (() -> Void)?
    let onRequestDeleteAll: (() -> Void)?
    let onRequestResetWelcome: (() -> Void)?
    let onRequestShowWelcome: (() -> Void)?
    let onRequestAdvanceTimeBy24h: (() -> Void)?
    let onRequestResetTimeOffset: (() -> Void)?

    @State private var resetTime: Date
    @State private var showingFeedbackMail = false
    @State private var showingNoMailAlert = false
    @State private var iCloudAccountAvailability: CloudSyncStatus.Availability?
    
    init(
        settings: AppSettings = .shared,
        onRequestAddTestItems: (() -> Void)? = nil,
        onRequestDeleteAll: (() -> Void)? = nil,
        onRequestResetWelcome: (() -> Void)? = nil,
        onRequestShowWelcome: (() -> Void)? = nil,
        onRequestAdvanceTimeBy24h: (() -> Void)? = nil,
        onRequestResetTimeOffset: (() -> Void)? = nil
    ) {
        self.settings = settings
        self.onRequestAddTestItems = onRequestAddTestItems
        self.onRequestDeleteAll = onRequestDeleteAll
        self.onRequestResetWelcome = onRequestResetWelcome
        self.onRequestShowWelcome = onRequestShowWelcome
        self.onRequestAdvanceTimeBy24h = onRequestAdvanceTimeBy24h
        self.onRequestResetTimeOffset = onRequestResetTimeOffset
        
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
                iCloudSyncSection
                synchronisationSection
                appearanceSection
                welcomeSection
                feedbackSection
            }
            .listSectionSpacing(.compact)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                settingsBottomChrome
            }
            .sheet(isPresented: $showingFeedbackMail) {
                MailComposeView(
                    recipients: [FeedbackService.recipient],
                    subject: FeedbackService.mailSubject(version: appVersion, build: appBuild),
                    body: FeedbackService.deviceInfoBody(),
                    isPresented: $showingFeedbackMail
                )
                .ignoresSafeArea()
            }
            .alert(
                String(localized: "settings.feedback.nomail.title", defaultValue: "No Mail Account"),
                isPresented: $showingNoMailAlert
            ) {
                Button(String(localized: "settings.feedback.nomail.copy", defaultValue: "Copy Address")) {
                    UIPasteboard.general.string = FeedbackService.recipient
                }
                Button(String(localized: "general.ok", defaultValue: "OK"), role: .cancel) {}
            } message: {
                Text(String(localized: "settings.feedback.nomail.message", defaultValue: "No mail client is set up on this device. You can reach us at \(FeedbackService.recipient)."))
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
        let hasAnyDebugAction = onRequestAddTestItems != nil
            || onRequestDeleteAll != nil
            || onRequestResetWelcome != nil
            || onRequestAdvanceTimeBy24h != nil
            || onRequestResetTimeOffset != nil
        if hasAnyDebugAction {
            Section {
                #if DEBUG
                let offsetHours = Int(DebugTimeProvider.storedOffset / 3600)
                if offsetHours != 0 {
                    Label("Zeit: +\(offsetHours)h vorgerückt", systemImage: "clock.badge.exclamationmark")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
                #endif

                if let onRequestAdvanceTimeBy24h {
                    Button {
                        onRequestAdvanceTimeBy24h()
                        dismiss()
                    } label: {
                        Label("Zeit +24h & Reset", systemImage: "clock.arrow.circlepath")
                    }
                }

                if let onRequestResetTimeOffset {
                    Button {
                        onRequestResetTimeOffset()
                    } label: {
                        Label("Zeit zurücksetzen", systemImage: "clock")
                    }
                }

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

                if let onRequestResetWelcome {
                    Button {
                        onRequestResetWelcome()
                    } label: {
                        Label(
                            String(localized: "debug.reset.welcome", defaultValue: "Reset Welcome"),
                            systemImage: "sparkles"
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
    
    private var iCloudSyncSection: some View {
        Section {
            Toggle(
                String(localized: "settings.icloud.toggle", defaultValue: "Sync with iCloud"),
                isOn: $settings.iCloudSyncEnabled
            )

            if settings.iCloudSyncEnabled, let availability = iCloudAccountAvailability {
                Label {
                    Text(iCloudStatusText(for: availability))
                } icon: {
                    Image(systemName: availability == .available ? "checkmark.icloud" : "exclamationmark.icloud")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        } header: {
            Text(String(localized: "settings.icloud.section", defaultValue: "iCloud Sync"))
        } footer: {
            Text(String(
                localized: "settings.icloud.footer.restart",
                defaultValue: "Takes effect after you relaunch Dawny. Your tasks sync through your personal iCloud account."
            ))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: settings.iCloudSyncEnabled) {
            guard settings.iCloudSyncEnabled else {
                iCloudAccountAvailability = nil
                return
            }
            iCloudAccountAvailability = await CloudSyncStatus.accountAvailability()
        }
    }

    private func iCloudStatusText(for availability: CloudSyncStatus.Availability) -> String {
        switch availability {
        case .available:
            return String(localized: "settings.icloud.status.available", defaultValue: "iCloud available")
        case .unavailable:
            return String(
                localized: "settings.icloud.status.noAccount",
                defaultValue: "Not signed into iCloud. Sync is paused."
            )
        }
    }

    private var synchronisationSection: some View {
        Section {
            Toggle(String(localized: "settings.sync.toggle", defaultValue: "Calendar Sync"), isOn: $settings.calendarSyncEnabled)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "settings.sync.description", defaultValue: "Synchronizes Daily Focus tasks with iOS Reminders."))
                if settings.iCloudSyncEnabled {
                    Text(String(
                        localized: "settings.icloud.footer.reminders",
                        defaultValue: "Tip: enable the Apple Reminders integration on one device only."
                    ))
                }
            }
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

    @ViewBuilder
    private var welcomeSection: some View {
        if let showWelcomeAgain = onRequestShowWelcome {
            Section {
                Button {
                    dismiss()
                    showWelcomeAgain()
                } label: {
                    Text(String(localized: "settings.welcome.showAgain", defaultValue: "Show welcome message again"))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .tint(.primary)
                .accessibilityIdentifier("SettingsShowWelcomeButton")
            }
        }
    }
    
    private var feedbackSection: some View {
        Section {
            Button {
                if MFMailComposeViewController.canSendMail() {
                    showingFeedbackMail = true
                } else if let url = FeedbackService.mailtoFallbackURL(version: appVersion, build: appBuild) {
                    UIApplication.shared.open(url, options: [:]) { success in
                        if !success {
                            DispatchQueue.main.async { showingNoMailAlert = true }
                        }
                    }
                } else {
                    showingNoMailAlert = true
                }
            } label: {
                Label(
                    String(localized: "settings.feedback.send", defaultValue: "Send Feedback"),
                    systemImage: "envelope"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier("SettingsFeedbackSendButton")
        } header: {
            Text(String(localized: "settings.feedback.header", defaultValue: "Feedback"))
        }
    }

    private var settingsBottomChrome: some View {
        Text(versionBuildFooterLine)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Color(uiColor: .systemGroupedBackground))
            .accessibilityLabel(versionBuildAccessibilityLabel)
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
