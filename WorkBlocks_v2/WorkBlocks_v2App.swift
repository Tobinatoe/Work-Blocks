//
//  WorkBlocks_v2App.swift
//  WorkBlocks_v2
//
//  Created by Tobias Leitner on 15.08.2025.
//

import SwiftUI

@main
struct WorkBlocks_v2App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Singletons wired at app start
    @StateObject private var storage = Storage()
    @StateObject private var timerStore = TimerStore()
    @StateObject private var lifecycle = LifecycleService()
    var body: some Scene {
        WindowGroup {
            TabView {
                MainView()
                    .tabItem { Label("Today", systemImage: "clock") }
                HistoryView()
                    .tabItem { Label("History", systemImage: "calendar") }
            }
            .environmentObject(timerStore)
            .environmentObject(storage)
            .onAppear {
                timerStore.bootstrap(storage: storage)
                lifecycle.bootstrap(timerStore: timerStore)
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)

        MenuBarExtra("WorkBlocks", systemImage: "timer") {
            MenuBarView()
                .environmentObject(timerStore)
                .environmentObject(storage)
        }
    }
}
