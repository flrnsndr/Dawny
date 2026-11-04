// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  AutoArchiveReviewView.swift
//  Dawny
//
//  Zwei-Schritt-Sheet das nach einem Auto-Archive-Event zeigt, was archiviert wurde.
//

import SwiftUI

struct AutoArchiveReviewView: View {
    @State var viewModel: AutoArchiveReviewViewModel
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            TabView(selection: $viewModel.currentStep) {
                dailyReviewPage
                    .tag(0)
                backlogReviewPage
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .accessibilityLabel(
                        String(localized: "common.close", defaultValue: "Close")
                    )
                }
            }
        }
        .onDisappear {
            viewModel.markAllReviewed()
        }
    }

    // MARK: - Daily Review Page

    private var dailyReviewPage: some View {
        reviewPage(
            title: viewModel.dailyArchivedTasks.isEmpty
                ? String(localized: "autoarchive.review.daily.title.empty", defaultValue: "All clean")
                : String(localized: "autoarchive.review.daily.title.hasItems", defaultValue: "Time for a fresh start"),
            subtitle: viewModel.dailyArchivedTasks.isEmpty
                ? String(localized: "autoarchive.review.daily.subtitle.empty", defaultValue: "Nothing needed archiving from your Daily. A wonderfully clean slate for today.")
                : String(localized: "autoarchive.review.daily.subtitle.hasItems", defaultValue: "We've safely tucked these tasks away in the archive so you can start today free of clutter."),
            tasks: viewModel.dailyArchivedTasks,
            ctaLabel: viewModel.backlogArchivedTasks.isEmpty
                ? String(localized: "autoarchive.review.cta.freshStart", defaultValue: "Fresh start")
                : String(localized: "autoarchive.review.cta.next", defaultValue: "Continue"),
            onCTA: {
                if viewModel.backlogArchivedTasks.isEmpty {
                    onDismiss()
                } else {
                    withAnimation { viewModel.currentStep = 1 }
                }
            }
        )
    }

    // MARK: - Backlog Review Page

    private var backlogReviewPage: some View {
        reviewPage(
            title: viewModel.backlogArchivedTasks.isEmpty
                ? String(localized: "autoarchive.review.backlog.title.empty", defaultValue: "Focus stays put")
                : String(localized: "autoarchive.review.backlog.title.hasItems", defaultValue: "Backlog breathed out"),
            subtitle: viewModel.backlogArchivedTasks.isEmpty
                ? String(localized: "autoarchive.review.backlog.subtitle.empty", defaultValue: "Your backlog is exactly how you left it.")
                : String(localized: "autoarchive.review.backlog.subtitle.hasItems", defaultValue: "Space has been made here too. These items are now resting in the archive."),
            tasks: viewModel.backlogArchivedTasks,
            ctaLabel: String(localized: "autoarchive.review.cta.go", defaultValue: "Let's go"),
            onCTA: { onDismiss() }
        )
    }

    // MARK: - Shared Page Layout

    private func reviewPage(
        title: String,
        subtitle: String,
        tasks: [Task],
        ctaLabel: String,
        onCTA: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 36)
                    .padding(.horizontal, 32)

                    if !tasks.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(tasks) { task in
                                reviewTaskRow(task)
                                if task.id != tasks.last?.id {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 80)
                }
            }

            VStack(spacing: 0) {
                Divider()
                Button(action: onCTA) {
                    Text(ctaLabel)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Task Row

    private func reviewTaskRow(_ task: Task) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "archivebox")
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                if let category = task.category {
                    HStack(spacing: 4) {
                        Image(systemName: category.displayIconName)
                            .font(.caption2)
                        Text(category.displayName)
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
