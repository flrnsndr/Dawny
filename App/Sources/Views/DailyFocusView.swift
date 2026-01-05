//
//  DailyFocusView.swift
//  Dawny
//
//  View für Daily Focus - Tasks für heute
//

import SwiftUI

struct DailyFocusView: View {
    @Bindable var viewModel: DailyFocusViewModel
    @State private var showingSyncIndicator = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.dailyTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
                
                // Sync Indicator
                if viewModel.isSyncing {
                    syncIndicatorView
                }
            }
            .navigationTitle(String(localized: "today.title", defaultValue: "Heute"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    progressView
                }
            }
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
    
    private var taskListView: some View {
        List {
            if !viewModel.openTasks.isEmpty {
                Section(String(localized: "today.section.open", defaultValue: "Offen")) {
                    ForEach(viewModel.openTasks) { task in
                        TaskRowView(
                            task: task,
                            onToggle: {
                                _Concurrency.Task {
                                    await viewModel.completeTask(task)
                                }
                            },
                            onDelete: nil,
                            showDragHandle: true
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
                    .onMove(perform: viewModel.moveTasks)
                }
            }
            
            if !viewModel.completedTasks.isEmpty {
                Section(String(localized: "today.section.completed", defaultValue: "Erledigt")) {
                    ForEach(viewModel.completedTasks) { task in
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
        .listStyle(.insetGrouped)
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "sun.horizon",
            title: String(localized: "today.empty.title", defaultValue: "Noch keine Tasks für heute"),
            message: String(localized: "today.empty.message", defaultValue: "Füge Tasks aus deinem Backlog hinzu, um den Tag zu planen")
        )
    }
    
    private var progressView: some View {
        HStack(spacing: 8) {
            Text("\(viewModel.completedTaskCount)/\(viewModel.dailyTasks.count)")
                .font(.caption)
                .fontWeight(.medium)
            
            SyncStatusIndicator(
                status: viewModel.isSyncing ? .syncing : .idle,
                lastSyncDate: viewModel.lastSyncDate
            )
        }
    }
    
    private var syncIndicatorView: some View {
        VStack {
            Spacer()
            HStack {
                ProgressView()
                Text(String(localized: "today.sync.progress", defaultValue: "Synchronisiere..."))
                    .font(.caption)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding()
        }
    }
}
