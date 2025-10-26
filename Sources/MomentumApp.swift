import SwiftUI
import AppKit

@main
struct MomentumApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var projectStore = ProjectStore.shared
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some Scene {
        WindowGroup {
            if settingsManager.hasCompletedOnboarding {
                DashboardView()
                    .environmentObject(projectStore)
                    .environmentObject(settingsManager)
                    .frame(minWidth: 1000, minHeight: 650)
            } else {
                OnboardingView()
                    .environmentObject(settingsManager)
                    .environmentObject(projectStore)
                    .frame(width: 750, height: 650)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Momentum") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "Momentum",
                            NSApplication.AboutPanelOptionKey.applicationVersion: "1.0.0",
                            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2025"
                        ]
                    )
                }
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
                .environmentObject(projectStore)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menuBarManager: MenuBarManager?
    private var mouseMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup menu bar
        menuBarManager = MenuBarManager()
        
        // Ensure app uses regular activation policy and becomes active on input
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first { window.makeKeyAndOrderFront(nil) }

        // Force activation on any mouse click inside the app
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            NSApp.activate(ignoringOtherApps: true)
            return event
        }

        // Check if running in DerivedData (Xcode build)
        let isRunningInXcode = Bundle.main.bundleURL.path.contains("DerivedData")

        if isRunningInXcode {
            print("⚠️ Running in Xcode DerivedData - notifications disabled")
            print("💡 Build the app properly and run outside of Xcode for notifications to work")
        } else {
            // Request notification permissions and start monitoring
            Task {
                await NotificationManager.shared.requestAuthorization()
                await NotificationManager.shared.setupNotificationActions()
                await ProjectMonitorService.shared.startMonitoring()
            }
        }

        if Bundle.main.bundleIdentifier != nil {
            print("✅ Running with proper app bundle - notifications enabled")
            print("💡 Bundle identifier: \(Bundle.main.bundleIdentifier ?? "nil")")
            print("💡 Bundle path: \(Bundle.main.bundlePath)")
        } else {
            print("⚠️  Running without app bundle - notifications may not work but will show alerts")
            print("💡 Build and run from Xcode with proper entitlements for notifications to work")
            print("💡 Current bundle path: \(Bundle.main.bundlePath)")
            print("💡 Current bundle identifier: \(Bundle.main.bundleIdentifier ?? "nil")")
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in menu bar
    }

    deinit {
        if let monitor = mouseMonitor { NSEvent.removeMonitor(monitor) }
    }
}

