// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  WelcomeView.swift
//  Dawny
//
//  Welcome Screen – nur nach Installation angezeigt
//

import SwiftUI

struct WelcomeView: View {
    @State private var currentPage = 0
    @State private var showMakeItCountLockedAlert = false
    var onDismiss: () -> Void

    private let pages: [WelcomePage] = [
        WelcomePage(
            icon: "sun.horizon.fill",
            iconColor: .orange,
            title: LocalizedStringResource(
                "welcome.page1.title",
                defaultValue: "Welcome to Dawny"
            ),
            body: LocalizedStringResource(
                "welcome.page1.body",
                defaultValue: "Your to-do list that wakes up fresh every morning, free from yesterday's clutter."
            )
        ),
        WelcomePage(
            icon: "tray.fill",
            iconColor: .blue,
            title: LocalizedStringResource(
                "welcome.page2.title",
                defaultValue: "Capture everything in your Backlog"
            ),
            body: LocalizedStringResource(
                "welcome.page2.body",
                defaultValue: "Drop tasks in without deadline pressure. Your backlog never forgets."
            )
        ),
        WelcomePage(
            icon: "sun.max.fill",
            iconColor: .orange,
            title: LocalizedStringResource(
                "welcome.page3.title",
                defaultValue: "Plan today on purpose"
            ),
            body: LocalizedStringResource(
                "welcome.page3.body",
                defaultValue: "Each morning, decide what truly matters and pull it into Today."
            )
        ),
        WelcomePage(
            icon: "sparkles",
            iconColor: .purple,
            title: LocalizedStringResource(
                "welcome.page4.title",
                defaultValue: "Reset at dawn"
            ),
            body: LocalizedStringResource(
                "welcome.page4.body",
                defaultValue: "Anything left undone slides back to the backlog overnight. Tomorrow is a clean slate."
            )
        ),
        WelcomePage(
            icon: "archivebox.fill",
            iconColor: .indigo,
            title: LocalizedStringResource(
                "welcome.makeitcount.title",
                defaultValue: "Make it count"
            ),
            body: LocalizedStringResource(
                "welcome.makeitcount.body",
                defaultValue: "Tasks you don't complete get archived instead of silently piling up. Your backlog stays lean, honest, and meaningful."
            )
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page, pageIndex: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            .highPriorityGesture(closeOnLastPageSwipeGesture)

            bottomSection
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Page Content

    private func pageView(_ page: WelcomePage, pageIndex: Int) -> some View {
        let isMakeItCountPage = pageIndex == pages.count - 1
        return VStack(spacing: 28) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(page.iconColor.gradient)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 36)

            Spacer()

            if isMakeItCountPage {
                makeItCountCheckbox
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    // MARK: - Bottom Controls

    private var bottomSection: some View {
        VStack(spacing: 20) {
            pageIndicator

            if currentPage == pages.count - 1 {
                Button(action: onDismiss) {
                    Text(String(localized: "welcome.cta.start", defaultValue: "Get started"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .accessibilityIdentifier("WelcomeStartButton")
            } else {
                Button {
                    withAnimation {
                        currentPage += 1
                    }
                } label: {
                    Text(String(localized: "welcome.cta.next", defaultValue: "Continue"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .accessibilityIdentifier("WelcomeNextButton")
            }
        }
        .alert(
            String(localized: "makeitcount.alert.title", defaultValue: "Make it count is essential"),
            isPresented: $showMakeItCountLockedAlert
        ) {
            Button(String(localized: "makeitcount.alert.confirm", defaultValue: "Sounds great"), role: .cancel) {}
        } message: {
            Text(
                String(
                    localized: "makeitcount.alert.message",
                    defaultValue: "This is one of Dawny's core features. Tasks that are not completed are archived so your backlog stays focused and meaningful.\n\nTherefore, Make it count cannot be disabled in Dawny."
                )
            )
        }
    }

    /// Checkbox für Make it count – standardmäßig aktiv, nicht deaktivierbar.
    /// Bei Versuch zu deaktivieren erscheint ein erklärender Alert.
    private var makeItCountCheckbox: some View {
        Button {
            showMakeItCountLockedAlert = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.indigo)
                Text(String(localized: "welcome.makeitcount.checkbox", defaultValue: "Make it count"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "welcome.makeitcount.checkbox", defaultValue: "Make it count"))
        .accessibilityHint(
            String(
                localized: "welcome.makeitcount.checkbox.hint",
                defaultValue: "This feature is always enabled"
            )
        )
        .accessibilityIdentifier("WelcomeMakeItCountCheckbox")
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.orange : Color.secondary.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }

    private var closeOnLastPageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let isLastPage = currentPage == pages.count - 1
                let isSwipeToNext = value.translation.width < -48
                if isLastPage && isSwipeToNext {
                    onDismiss()
                }
            }
    }
}

// MARK: - Model

private struct WelcomePage {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringResource
    let body: LocalizedStringResource
}

#Preview {
    WelcomeView(onDismiss: {})
}
