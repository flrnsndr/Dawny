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
            TabPager(
                selectedIndex: Binding(
                    get: { selectedTab.rawValue },
                    set: { newValue in
                        selectedTab = Tab(rawValue: newValue) ?? .backlog
                    }
                ),
                page0: {
                    if let backlogVM = backlogViewModel {
                        BacklogView(
                            viewModel: backlogVM,
                            dailyFocusViewModel: dailyFocusViewModel
                        )
                    } else {
                        ProgressView()
                    }
                },
                page1: {
                    if let dailyViewModel = dailyFocusViewModel, let backlogVM = backlogViewModel {
                        DailyFocusView(viewModel: dailyViewModel, backlogViewModel: backlogVM)
                    } else {
                        ProgressView()
                    }
                }
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
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
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                selectedTab = tab
            }
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

/// Eigener Pager für den Tab-Wechsel. Statt SwiftUIs `DragGesture` (die nicht über
/// UIKits Delegate-Mechanismus mit den `swipeActions`-Gesten der List-Zellen
/// koordinieren kann) verwenden wir einen `UIPanGestureRecognizer` via
/// `UIGestureRecognizerRepresentable` (iOS 18+). Der Delegate stellt sicher, dass
/// der Pager *immer* hinter Row-Swipe-Gesten zurücktritt — exakt das Pattern,
/// das Apple Erinnerungen für die Back-Geste verwendet.
private struct TabPager<Page0: View, Page1: View>: View {
    @Binding var selectedIndex: Int
    @ViewBuilder var page0: () -> Page0
    @ViewBuilder var page1: () -> Page1

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    private static var snapAnimation: Animation {
        .interactiveSpring(response: 0.28, dampingFraction: 0.86)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            HStack(spacing: 0) {
                page0()
                    .frame(width: width)
                page1()
                    .frame(width: width)
            }
            .frame(width: width, alignment: .leading)
            .offset(x: -CGFloat(selectedIndex) * width + dragOffset)
            .animation(isDragging ? nil : Self.snapAnimation, value: selectedIndex)
            .animation(isDragging ? nil : Self.snapAnimation, value: dragOffset)
            .contentShape(Rectangle())
            .gesture(
                PagerPanRecognizer(
                    onChanged: { tx in
                        isDragging = true
                        let atLeftEdge = selectedIndex == 0 && tx > 0
                        let atRightEdge = selectedIndex == 1 && tx < 0
                        dragOffset = (atLeftEdge || atRightEdge) ? tx / 3 : tx
                    },
                    onEnded: { tx, vx in
                        let distanceThreshold = width / 4
                        let velocityThreshold: CGFloat = 400

                        withAnimation(Self.snapAnimation) {
                            if (tx < -distanceThreshold || vx < -velocityThreshold), selectedIndex == 0 {
                                selectedIndex = 1
                            } else if (tx > distanceThreshold || vx > velocityThreshold), selectedIndex == 1 {
                                selectedIndex = 0
                            }
                            dragOffset = 0
                            isDragging = false
                        }
                    },
                    onCancelled: {
                        withAnimation(Self.snapAnimation) {
                            dragOffset = 0
                            isDragging = false
                        }
                    }
                )
            )
        }
    }
}

/// Brückt einen `UIPanGestureRecognizer` mit eigenem Delegate nach SwiftUI.
/// Der Delegate sorgt dafür, dass die Geste:
/// 1. nur startet, wenn die initiale Bewegung dominant horizontal ist (vertikales
///    List-Scrolling bleibt unangetastet),
/// 2. *vor* jeder konkurrierenden Pan-Geste innerhalb einer `UICollectionViewCell`
///    bzw. `UITableViewCell` zurücktritt — also vor den `swipeActions` der List.
private struct PagerPanRecognizer: UIGestureRecognizerRepresentable {
    let onChanged: (_ translationX: CGFloat) -> Void
    let onEnded: (_ translationX: CGFloat, _ velocityX: CGFloat) -> Void
    let onCancelled: () -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {}

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let view = recognizer.view
        let tx = recognizer.translation(in: view).x
        switch recognizer.state {
        case .changed:
            onChanged(tx)
        case .ended:
            let vx = recognizer.velocity(in: view).x
            onEnded(tx, vx)
        case .cancelled, .failed:
            onCancelled()
        default:
            break
        }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        /// Filtert Touches *vor* der Gesten-Erkennung aus: Berührt der Finger eine
        /// List-Zelle (UICollectionViewCell/UITableViewCell), bekommt unsere Pan-Geste
        /// den Touch gar nicht erst zu sehen — die Row-`swipeActions` der Zelle laufen
        /// dann ungestört ab. Genau der Mechanismus, mit dem Apple Erinnerungen den
        /// `interactivePopGestureRecognizer` mit Row-Swipes koexistieren lässt.
        ///
        /// Wichtig: `touch.view` ist die hit-getestete tiefste View — bei SwiftUI-`List`
        /// (iOS 16+ intern `UICollectionView`) liegt die `swipeActions`-Geste an der
        /// Collection View, nicht an der Zelle. Eine Prüfung über `other.view` würde
        /// die Zelle deshalb nie finden. Über `touch.view` läuft der Walk-Up dagegen
        /// zuverlässig durch die Cell-Hierarchie.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            var view: UIView? = touch.view
            while let current = view {
                if current is UICollectionViewCell || current is UITableViewCell {
                    return false
                }
                view = current.superview
            }
            return true
        }

        /// Startet nur, wenn die Bewegung dominant horizontal ist — vertikales
        /// List-Scrolling bleibt damit unangetastet.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y) * 1.2
        }
    }
}

#Preview {
    DawnyPreview.contentView()
}
