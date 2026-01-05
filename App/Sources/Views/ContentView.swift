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
    
    enum Tab: Int {
        case backlog = 0
        case today = 1
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Group {
                if let backlogVM = backlogViewModel {
                    BacklogView(viewModel: backlogVM)
                } else {
                    ProgressView()
                }
            }
            .tabItem {
                Label("Backlog", systemImage: "tray.fill")
            }
            .tag(Tab.backlog)
            
            Group {
                if let dailyViewModel = dailyFocusViewModel {
                    DailyFocusView(viewModel: dailyViewModel)
                } else {
                    ProgressView()
                }
            }
            .tabItem {
                Label("Heute", systemImage: "sun.max.fill")
            }
            .tag(Tab.today)
        }
        .onAppear {
            initializeViewModels()
            
            // Initiale Tab-Selektion nur einmal beim App-Start
            if !hasSetInitialTab {
                hasSetInitialTab = true
                if shouldShowTodayTab() {
                    selectedTab = .today
                }
            }
        }
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
