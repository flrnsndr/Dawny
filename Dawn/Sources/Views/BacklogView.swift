//
//  BacklogView.swift
//  Dawn
//
//  View für Backlog-Management
//

import SwiftUI

struct BacklogView: View {
    @Bindable var viewModel: BacklogViewModel
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.backlogTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
            }
            .navigationTitle(viewModel.currentBacklog?.title ?? "Backlog")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                QuickAddView { title, notes in
                    viewModel.addTask(title: title, notes: notes)
                }
            }
            .onAppear {
                viewModel.loadBacklogs()
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
            ForEach(viewModel.backlogTasks) { task in
                TaskRowView(
                    task: task,
                    onToggle: nil,
                    onDelete: {
                        _Concurrency.Task {
                            await viewModel.deleteTask(task)
                        }
                    }
                )
                .swipeActions(edge: .leading) {
                    Button {
                        HapticFeedback.medium()
                        _Concurrency.Task {
                            await viewModel.moveTaskToDailyFocus(task)
                        }
                    } label: {
                        Label("Heute", systemImage: "sun.max.fill")
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "tray",
            title: "Backlog ist leer",
            message: "Füge neue Tasks hinzu, um mit der Planung zu beginnen",
            actionTitle: "Task hinzufügen",
            action: {
                showingAddTask = true
            }
        )
    }
}
