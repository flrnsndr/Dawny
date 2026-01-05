//
//  BacklogView.swift
//  Dawny
//
//  View für Backlog-Management mit optionaler Kategorieansicht
//

import SwiftUI

struct BacklogView: View {
    @Bindable var viewModel: BacklogViewModel
    @State private var showingAddTask = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.backlogTasks.isEmpty {
                    emptyStateView
                } else if viewModel.settings.showCategories {
                    categorizedListView
                } else {
                    flatTaskListView
                }
            }
            .navigationTitle(viewModel.currentBacklog?.title ?? String(localized: "backlog.title", defaultValue: "Backlog"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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
    
    // MARK: - Categorized View with Drag & Drop
    
    private var categorizedListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.visibleCategories) { category in
                    VStack(spacing: 0) {
                        // Category Header als Drop Target
                        CategoryHeaderDropTarget(
                            category: category,
                            taskCount: viewModel.tasksByCategory[category]?.count ?? 0,
                            isCollapsed: viewModel.settings.isCategoryCollapsed(category),
                            onToggleCollapse: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.settings.toggleCategoryCollapsed(category)
                                }
                            },
                            onDropTask: { task in
                                viewModel.moveTask(task, toCategory: category)
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        // Tasks in dieser Kategorie
                        if !viewModel.settings.isCategoryCollapsed(category) {
                            let tasks = viewModel.tasksByCategory[category] ?? []
                            
                            if tasks.isEmpty {
                                // Empty State
                                HStack {
                                    Spacer()
                                    Text(String(localized: "category.empty", defaultValue: "Keine Tasks"))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .italic()
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                            } else {
                                // Task Rows
                                ForEach(tasks) { task in
                                    DraggableTaskRow(
                                        task: task,
                                        onDelete: {
                                            _Concurrency.Task {
                                                await viewModel.deleteTask(task)
                                            }
                                        },
                                        onMoveToToday: {
                                            _Concurrency.Task {
                                                await viewModel.moveTaskToDailyFocus(task)
                                            }
                                        },
                                        onChangeCategory: { targetCategory in
                                            viewModel.moveTask(task, toCategory: targetCategory)
                                        },
                                        currentCategory: category
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemBackground))
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Flat List View (ohne Kategorien)
    
    private var flatTaskListView: some View {
        List {
            ForEach(viewModel.backlogTasks) { task in
                TaskRowView(
                    task: task,
                    onToggle: nil,
                    onDelete: {
                        _Concurrency.Task {
                            await viewModel.deleteTask(task)
                        }
                    },
                    showBacklogBadge: false
                )
                .swipeActions(edge: .leading) {
                    Button {
                        HapticFeedback.medium()
                        _Concurrency.Task {
                            await viewModel.moveTaskToDailyFocus(task)
                        }
                    } label: {
                        Label(String(localized: "backlog.swipe.today", defaultValue: "Heute"), systemImage: "sun.max.fill")
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "tray",
            title: String(localized: "backlog.empty.title", defaultValue: "Backlog ist leer"),
            message: String(localized: "backlog.empty.message", defaultValue: "Füge neue Tasks hinzu, um mit der Planung zu beginnen"),
            actionTitle: String(localized: "backlog.empty.action", defaultValue: "Task hinzufügen"),
            action: {
                showingAddTask = true
            }
        )
    }
}
