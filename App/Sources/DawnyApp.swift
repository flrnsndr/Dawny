// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  DawnyApp.swift
//  Dawny
//
//  Main App Entry Point
//

import SwiftUI
import SwiftData
import BackgroundTasks
import AppIntents

@main
struct DawnyApp: App {
    // SwiftData ModelContainer
    let modelContainer: ModelContainer
    
    // Services
    let timeProvider: TimeProvider
    let calendarService: CalendarServiceProtocol
    let resetEngine: ResetEngine
    let syncEngine: SyncEngine
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasLaunchedBefore = false
    
    init() {
        // Initialize ModelContainer
        do {
            modelContainer = try IntentDataStore.makeModelContainer()
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        
        // Initialize Services
        timeProvider = SystemTimeProvider()
        calendarService = EventKitCalendarService()
        resetEngine = ResetEngine(
            timeProvider: timeProvider,
            modelContext: modelContainer.mainContext
        )
        syncEngine = SyncEngine(
            calendarService: calendarService,
            modelContext: modelContainer.mainContext
        )
        
        // Cross-reference for reset engine
        resetEngine.syncEngine = syncEngine
        
        // Register dependencies for App Intents
        let container = modelContainer
        let sync = syncEngine
        AppDependencyManager.shared.add {
            TaskDataStore(container: container) as any TaskDataStoring
        }
        AppDependencyManager.shared.add {
            sync
        }
        
        // Siri Shortcuts registrieren
        DawnyShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    if !hasLaunchedBefore {
                        await performAppLaunchTasks()
                        hasLaunchedBefore = true
                    }
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
        }
        .modelContainer(modelContainer)
        .environment(\.resetEngine, resetEngine)
        .environment(\.syncEngine, syncEngine)
    }
    
    /// Führt wichtige Tasks beim App-Start aus
    private func performAppLaunchTasks() async {
        print("🚀 Dawny App Launching...")
        
        // 1. Request Calendar Permissions (falls noch nicht erteilt)
        do {
            let granted = try await calendarService.requestAccess()
            if granted {
                print("✅ Calendar access granted")
            } else {
                print("⚠️ Calendar access denied")
            }
        } catch {
            print("❌ Calendar access failed: \(error)")
        }
        
        // 2. Perform Reset Check (kritisch!)
        await resetEngine.checkAndPerformResetIfNeeded()
        
        // 3. Start Sync Observer
        await syncEngine.startObserving()
        
        // 4. Register Background Task
        resetEngine.registerBackgroundTask()
        
        // 5. Initialize Categories
        let categoryService = CategoryService(modelContext: modelContainer.mainContext)
        categoryService.initializeDefaultCategories()
        
        // 6. Reindex entities for Spotlight / Apple Intelligence
        let dataStore = TaskDataStore(container: modelContainer)
        await EntityIndexer.reindexAllTasks(using: dataStore)
        await EntityIndexer.reindexAllCategories(using: dataStore)
        
        print("✅ App launch tasks completed")
    }
    
    /// Behandelt Scene Phase Änderungen
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App wurde aktiv - prüfe ob Reset nötig
            _Concurrency.Task {
                await resetEngine.checkAndPerformResetIfNeeded()
            }
            
        case .background:
            // App geht in Background - schedule Background Task
            resetEngine.registerBackgroundTask()
            
        case .inactive:
            break
            
        @unknown default:
            break
        }
    }
}

// MARK: - Environment Keys

private struct ResetEngineKey: EnvironmentKey {
    static let defaultValue: ResetEngine? = nil
}

private struct SyncEngineKey: EnvironmentKey {
    static let defaultValue: SyncEngine? = nil
}

extension EnvironmentValues {
    var resetEngine: ResetEngine? {
        get { self[ResetEngineKey.self] }
        set { self[ResetEngineKey.self] = newValue }
    }
    
    var syncEngine: SyncEngine? {
        get { self[SyncEngineKey.self] }
        set { self[SyncEngineKey.self] = newValue }
    }
}

#Preview("App UI") {
    DawnyPreview.contentView()
}
