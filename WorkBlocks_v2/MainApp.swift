import SwiftUI


struct WorkBlocksApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Singletons wired at app start
    @StateObject private var storage = Storage()
    @StateObject private var timerStore = TimerStore()
    @StateObject private var lifecycle = LifecycleService()

    var body: some Scene {
        // Menu bar extra (compact glance + quick actions)
        MenuBarExtra("WorkBlocks", systemImage: "timer") {
            MenuBarView()
                .environmentObject(timerStore)
                .environmentObject(storage)
        }

        // Main minimal window
        WindowGroup {
            MainView()
                .environmentObject(timerStore)
                .environmentObject(storage)
                .onAppear {
                    timerStore.bootstrap(storage: storage)
                    lifecycle.bootstrap(timerStore: timerStore)
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}

// For sleep/wake hooks
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillResignActive(_ notification: Notification) {}
}
