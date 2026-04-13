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
    /// Erforderlich, damit `List`+`onMove` die System-Reorder-Griffe anzeigt (wie Backlog).
    @State private var editMode = EditMode.inactive
    
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
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.openTasks.isEmpty {
                        Button {
                            toggleEditMode()
                        } label: {
                            Text(editMode == .active
                                 ? String(localized: "common.done", defaultValue: "Fertig")
                                 : String(localized: "common.edit", defaultValue: "Bearbeiten"))
                        }
                    }
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
                    ForEach(viewModel.openTasks, id: \.id) { task in
                        openTaskRow(task: task)
                    }
                    .onMove(perform: viewModel.moveTasks)
                }
            }
            
            if !viewModel.completedTasks.isEmpty {
                Section(String(localized: "today.section.completed", defaultValue: "Erledigt")) {
                    ForEach(viewModel.completedTasks, id: \.id) { task in
                        TaskRowView(
                            task: task,
                            onToggle: {
                                _Concurrency.Task {
                                    await viewModel.uncompleteTask(task)
                                }
                            },
                            onDelete: nil,
                            listEditingExplicit: editMode == .active
                        )
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
        .listStyle(.insetGrouped)
        
    }
    
    private func toggleEditMode() {
        editMode = editMode == .active ? .inactive : .active
    }
    
    @ViewBuilder
    private func openTaskRow(task: Task) -> some View {
        let row = TaskRowView(
            task: task,
            onToggle: {
                _Concurrency.Task {
                    await viewModel.completeTask(task)
                }
            },
            onDelete: nil,
            showDragHandle: false,
            listEditingExplicit: editMode == .active
        )
        if editMode == .inactive {
            row.swipeActions(edge: .trailing) {
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
        } else {
            row
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "sun.horizon",
            title: String(localized: "today.empty.title", defaultValue: "Noch keine Tasks für heute"),
            message: String(localized: "today.empty.message", defaultValue: "Füge Tasks aus deinem Backlog hinzu, um den Tag zu planen")
        )
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
