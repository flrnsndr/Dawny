// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  DailyFocusView.swift
//  Dawny
//
//  View für Daily Focus - Tasks für heute
//

import SwiftUI

struct DailyFocusView: View {
    @Bindable var viewModel: DailyFocusViewModel
    var backlogViewModel: BacklogViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollViewReader { proxy in
                    taskListView(scrollProxy: proxy)
                }
                
                // Sync Indicator
                if viewModel.isSyncing {
                    syncIndicatorView
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .refreshable {
                await viewModel.refresh()
            }
            .onAppear {
                viewModel.loadDailyTasks()
            }
            .overlay(alignment: .top) {
                if let error = viewModel.errorMessage {
                    ErrorBannerView(message: error) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.top, 8)
                    .onAppear {
                        HapticFeedback.error()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func taskListView(scrollProxy: ScrollViewProxy) -> some View {
        let openScrollID = AnyHashable("qe-today-open")

        return List {
            Section(String(localized: "today.section.open", defaultValue: "Open")) {
                ForEach(viewModel.openTasks, id: \.id) { task in
                    openTaskRow(task: task)
                }
                .onMove { source, destination in
                    viewModel.moveTasks(from: source, to: destination)
                }
                QuickEntryRow(
                    placeholder: String(localized: "quickentry.placeholder.today", defaultValue: "New task for today…"),
                    categoryAccessibilityName: nil,
                    scrollID: openScrollID,
                    onSubmit: { title in
                        _Concurrency.Task {
                            _ = await backlogViewModel.addTaskToTodayQuickEntry(title: title)
                            await MainActor.run {
                                viewModel.loadDailyTasks()
                            }
                        }
                    },
                    onFocusChange: { focused in
                        guard focused else { return }
                        DispatchQueue.main.async {
                            withAnimation {
                                scrollProxy.scrollTo(openScrollID, anchor: .bottom)
                            }
                        }
                    }
                )
                .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            }

            if !viewModel.completedTasks.isEmpty {
                Section(String(localized: "today.section.completed", defaultValue: "Completed")) {
                    ForEach(viewModel.completedTasks, id: \.id) { task in
                        TaskRowView(
                            task: task,
                            onToggle: {
                                _Concurrency.Task {
                                    await viewModel.uncompleteTask(task)
                                }
                            },
                            onDelete: nil
                        )
                    }
                }
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(.compact)
        .environment(\.defaultMinListRowHeight, 36)
    }
    
    @ViewBuilder
    private func openTaskRow(task: Task) -> some View {
        TaskRowView(
            task: task,
            onToggle: {
                _Concurrency.Task {
                    await viewModel.completeTask(task)
                }
            },
            onDelete: nil
        )
        .swipeActions(edge: .trailing) {
            Button {
                HapticFeedback.medium()
                _Concurrency.Task {
                    await viewModel.removeFromDailyFocus(task)
                }
            } label: {
                Label(String(localized: "today.swipe.backlog", defaultValue: "Backlog"), systemImage: "tray.fill")
            }
            .tint(.gray)
        }
    }
    
    private var syncIndicatorView: some View {
        VStack {
            Spacer()
            HStack {
                ProgressView()
                Text(String(localized: "today.sync.progress", defaultValue: "Syncing…"))
                    .font(.caption)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding()
        }
    }
}
