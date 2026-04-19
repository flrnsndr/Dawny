// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  ContentView.swift
//  Dawny
//
//  Main Tab View
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.resetEngine) private var resetEngine
    @Environment(\.syncEngine) private var syncEngine
    
    @State private var backlogViewModel: BacklogViewModel?
    @State private var dailyFocusViewModel: DailyFocusViewModel?
    @State private var selectedTab: Tab = .backlog
    @State private var hasSetInitialTab = false
    @State private var showWelcome = false
    @State private var isDraggingHorizontally = false
    @State private var showingSettings = false
    @Bindable private var settings: AppSettings = .shared
    #if DEBUG
    @State private var showingClearAllConfirm = false
    #endif

    private var clearAllAction: (() -> Void)? {
        #if DEBUG
        return { showingClearAllConfirm = true }
        #else
        return nil
        #endif
    }
    
    enum Tab: Int {
        case backlog = 0
        case today = 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            tabSwitcher
                .contentShape(Rectangle())
                .gesture(tabSwipeGesture)
            Group {
                switch selectedTab {
                case .backlog:
                    if let backlogVM = backlogViewModel {
                        BacklogView(
                            viewModel: backlogVM,
                            dailyFocusViewModel: dailyFocusViewModel
                        )
                    } else {
                        ProgressView()
                    }
                case .today:
                    if let dailyViewModel = dailyFocusViewModel, let backlogVM = backlogViewModel {
                        DailyFocusView(viewModel: dailyViewModel, backlogViewModel: backlogVM)
                    } else {
                        ProgressView()
                    }
                }
            }
        }
        .environment(\.triggerWelcomeFlow) {
            showWelcome = true
        }
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView {
                AppSettings.shared.hasSeenWelcome = true
                showWelcome = false
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                onRequestAddTestItems: {
                    triggerTestWorkflow()
                },
                onRequestDeleteAll: clearAllAction,
                onRequestShowWelcome: {
                    showingSettings = false
                    showWelcome = true
                }
            )
        }
        #if DEBUG
        .alert(
            String(localized: "quickadd.deleteall", defaultValue: "Delete All Tasks"),
            isPresented: $showingClearAllConfirm
        ) {
            Button(String(localized: "quickadd.cancel", defaultValue: "Cancel"), role: .cancel) {}
            Button(String(localized: "common.delete", defaultValue: "Delete"), role: .destructive) {
                _Concurrency.Task {
                    await clearAllBacklogTasks()
                }
            }
        } message: {
            Text(String(localized: "backlog.debug.clear.message", defaultValue: "All tasks (Backlog and Today) will be deleted."))
        }
        #endif
        .onAppear {
            initializeViewModels()
            
            if !hasSetInitialTab {
                hasSetInitialTab = true
                if shouldShowTodayTab() {
                    selectedTab = .today
                }
                if !AppSettings.shared.hasSeenWelcome {
                    showWelcome = true
                }
            }
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 8) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "settings.title", defaultValue: "Settings"))

            HStack(spacing: 4) {
                tabSwitchButton(
                    title: String(localized: "tabs.backlog", defaultValue: "Backlog"),
                    tab: .backlog
                )
                tabSwitchButton(
                    title: String(localized: "tabs.today", defaultValue: "Today"),
                    tab: .today
                )
            }
            .padding(2)
            .background(Color(UIColor.secondarySystemFill), in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background(.thinMaterial)
    }

    private func tabSwitchButton(title: String, tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    selectedTab == tab
                    ? Color(UIColor.systemBackground)
                    : Color.clear,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }

    /// Tab-Wechsel per horizontalem Wisch — bewusst nur am `tabSwitcher` angehängt,
    /// damit die Geste nicht mit `swipeActions` in den darunterliegenden Listen kollidiert.
    private var tabSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .local)
            .onChanged { value in
                if !isDraggingHorizontally {
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                    if isHorizontal {
                        isDraggingHorizontally = true
                    }
                }
            }
            .onEnded { value in
                defer { isDraggingHorizontally = false }

                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical), abs(horizontal) >= 50 else { return }

                if horizontal < 0, selectedTab == .backlog {
                    selectedTab = .today
                } else if horizontal > 0, selectedTab == .today {
                    selectedTab = .backlog
                }
            }
    }
    
    // MARK: - Debug Actions

    private func triggerTestWorkflow() {
        #if DEBUG
        guard let backlogVM = backlogViewModel else { return }
        backlogVM.addDebugTestItems(settings: settings)
        backlogVM.loadBacklogs()
        backlogVM.loadCategories()
        #endif
    }

    private func clearAllBacklogTasks() async {
        #if DEBUG
        guard let backlogVM = backlogViewModel else { return }
        let backlogTasks = backlogVM.backlogTasks
        let todayTasks = dailyFocusViewModel?.dailyTasks ?? []

        dailyFocusViewModel?.clearTasksFromDisplayOnly()

        for task in backlogTasks {
            await backlogVM.deleteTask(task)
        }

        if let dfvm = dailyFocusViewModel {
            for task in todayTasks {
                await dfvm.deleteTask(task)
            }
        }

        backlogVM.loadBacklogs()
        backlogVM.loadCategories()
        #endif
    }

    private func initializeViewModels() {
        guard let syncEngine = syncEngine,
              let resetEngine = resetEngine else {
            return
        }
        
        backlogViewModel = BacklogViewModel(
            modelContext: modelContext,
            syncEngine: syncEngine
        )
        
        dailyFocusViewModel = DailyFocusViewModel(
            modelContext: modelContext,
            syncEngine: syncEngine,
            resetEngine: resetEngine
        )
    }
    
    // MARK: - Tab Selection Logic
    
    /// Prüft ob der Heute-Tab angezeigt werden soll
    /// - Returns: true wenn DailyFocus Tasks existieren
    private func shouldShowTodayTab() -> Bool {
        // Fetch alle Tasks und filtere im Speicher
        // (SwiftData unterstützt keine computed properties in Predicates)
        let descriptor = FetchDescriptor<Task>()
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            
            // Prüfe auf dailyFocus Tasks (offene Tasks für heute)
            let hasDailyFocusTasks = allTasks.contains { $0.status == .dailyFocus }
            
            // TODO: Wenn Feature "erledigte Tasks im Heute-Tab" implementiert ist,
            // hier auch completedToday Tasks prüfen
            
            return hasDailyFocusTasks
        } catch {
            return false
        }
    }
}

#Preview {
    DawnyPreview.contentView()
}
