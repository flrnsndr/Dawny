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
    
    var body: some View {
        TabView {
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
        }
        .onAppear {
            initializeViewModels()
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
}
