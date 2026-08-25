// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ICloudSyncIntroView.swift
//  Dawny
//
//  Einmaliger Hinweis auf den neuen iCloud-Sync mit Opt-in-Schalter.
//

import SwiftUI

/// Der einmalige Sync-Hinweis für Bestandsnutzer nach dem Update.
///
/// Der Sync startet grundsätzlich ausgeschaltet (`AppSettings.iCloudSyncEnabled`
/// hat den Startwert `false`). Erst „Okay" schreibt die Entscheidung fest, damit
/// niemals ungefragt zwei Gerätestände zusammenlaufen.
///
/// Bei einer Neuinstallation übernimmt die letzte Seite des Welcome-Flows diese
/// Rolle, deshalb liegt der Schalter samt Hinweistext in `ICloudSyncOptInSection`.
struct ICloudSyncIntroView: View {
    /// Wird nach dem Festschreiben der Entscheidung aufgerufen.
    var onDismiss: () -> Void

    @State private var enableSync = true

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 68, weight: .light))
                        .foregroundStyle(Color.blue.gradient)
                        .padding(.top, 48)

                    VStack(spacing: 14) {
                        Text(String(
                            localized: "icloudintro.title",
                            defaultValue: "Dawny on all your devices"
                        ))
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                        Text(String(
                            localized: "icloudintro.body",
                            defaultValue: "This update brings iCloud sync. Your tasks, categories and settings stay in step on every device that uses your iCloud account. Yay!"
                        ))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                        Text(String(
                            localized: "icloudintro.merge",
                            defaultValue: "When you switch it on, the tasks from all your devices are merged into one list. Nothing is deleted. If you created the same task on two devices, it appears twice and you can delete one of them."
                        ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 32)

                    ICloudSyncOptInSection(isEnabled: $enableSync)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }

            Button {
                ICloudSyncOptIn.apply(enableSync)
                onDismiss()
            } label: {
                Text(String(localized: "icloudintro.cta", defaultValue: "Okay"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .accessibilityIdentifier("ICloudSyncIntroConfirmButton")
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color(.systemGroupedBackground))
        .interactiveDismissDisabled()
    }
}

/// Schalter plus erklärender Hinweis, geteilt von Intro-Sheet und Welcome-Flow.
struct ICloudSyncOptInSection: View {
    @Binding var isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isEnabled) {
                Text(String(
                    localized: "icloudintro.toggle",
                    defaultValue: "Enable iCloud sync"
                ))
                .font(.headline)
            }
            .tint(.orange)
            .accessibilityIdentifier("ICloudSyncIntroToggle")

            Text(hintText)
                .accessibilityIdentifier("ICloudSyncIntroHint")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    /// Der Sync greift erst beim nächsten Kaltstart, weil der `ModelContainer`
    /// einmalig in `DawnyApp.init()` gebaut wird. In den Hintergrund schicken
    /// reicht dafür nicht, deshalb steht das hier ausdrücklich so drin.
    private var hintText: String {
        if isEnabled {
            return String(
                localized: "icloudintro.hint.on",
                defaultValue: "Sync starts the next time Dawny launches. Close Dawny completely once and open it again."
            )
        }
        return String(
            localized: "icloudintro.hint.off",
            defaultValue: "Sync stays off and nothing leaves this device. You can switch it on any time in Settings."
        )
    }
}

/// Schreibt die Entscheidung aus dem Hinweis fest.
enum ICloudSyncOptIn {
    static func apply(_ isEnabled: Bool) {
        AppSettings.shared.iCloudSyncEnabled = isEnabled
        AppSettings.shared.hasSeenICloudSyncIntro = true
    }
}

#if DEBUG
/// Test-Hook für den UI-Test des Sync-Hinweises.
///
/// UI-Testläufe unterdrücken das Sheet normalerweise, weil es als modale Ebene
/// jede andere Interaktion blockiert. Mit `--icloud-intro` wird es gezielt
/// wieder eingeschaltet und der Ausgangszustand deterministisch gesetzt, damit
/// der Test nicht davon abhängt, was frühere Läufe auf dem Simulator hinterlassen
/// haben.
enum ICloudSyncIntroTestSupport {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("--icloud-intro")
    }

    /// Muss aus `DawnyApp.init()` laufen, bevor die erste View erscheint.
    static func prepareForLaunch() {
        AppSettings.shared.hasSeenWelcome = true
        AppSettings.shared.hasSeenICloudSyncIntro = false
        AppSettings.shared.iCloudSyncEnabled = false
    }
}
#endif

#Preview {
    ICloudSyncIntroView(onDismiss: {})
}
