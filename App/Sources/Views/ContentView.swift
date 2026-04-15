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
    @State private var showWelcome = !AppSettings.shared.hasSeenWelcome
    @State private var isDraggingHorizontally = false
    
    enum Tab: Int {
        case backlog = 0
        case today = 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            tabSwitcher
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
                    if let dailyViewModel = dailyFocusViewModel {
                        DailyFocusView(viewModel: dailyViewModel)
                    } else {
                        ProgressView()
                    }
                }
            }
        }
        .simultaneousGesture(tabSwipeGesture)
        .environment(\.selectTodayTab) {
            selectedTab = .today
        }
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView {
                AppSettings.shared.hasSeenWelcome = true
                showWelcome = false
            }
        }
        .onAppear {
            initializeViewModels()
            
            if !hasSetInitialTab {
                hasSetInitialTab = true
                if shouldShowTodayTab() {
                    selectedTab = .today
                }
            }
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 6) {
            tabSwitchButton(
                title: String(localized: "tabs.backlog", defaultValue: "Backlog"),
                tab: .backlog
            )
            tabSwitchButton(
                title: String(localized: "tabs.today", defaultValue: "Heute"),
                tab: .today
            )
        }
        .padding(4)
        .background(Color(UIColor.secondarySystemFill), in: Capsule())
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.thinMaterial)
    }

    private func tabSwitchButton(title: String, tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
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
