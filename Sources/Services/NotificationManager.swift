import Foundation
import UserNotifications
import AppKit

actor NotificationManager {
    static let shared = NotificationManager()
    
    private var lastNotificationDate: [UUID: Date] = [:]
    
    private init() {}
    
    func requestAuthorization() async {
        // Check if we have a proper bundle identifier (required for notifications)
        if Bundle.main.bundleIdentifier == nil {
            print("❌ Cannot request notification permissions: No bundle identifier (running without proper app bundle)")
            print("💡 Build and run from Xcode with proper entitlements for notifications to work")
            print("💡 Current bundle path: \(Bundle.main.bundlePath)")
            print("💡 Current bundle identifier: \(Bundle.main.bundleIdentifier ?? "nil")")
            print("💡 Attempting to request permissions anyway for testing...")
        }

        // Check if running in DerivedData (Xcode build) - skip authorization
        if Bundle.main.bundleURL.path.contains("DerivedData") {
            print("⚠️ Running in Xcode DerivedData - skipping notification authorization")
            return
        }

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied by user")
            }
        } catch {
            print("❌ Notification permission error: \(error)")
            print("💡 This might be due to missing entitlements. Make sure the app is built with proper notification permissions.")
            if let bundleId = Bundle.main.bundleIdentifier {
                print("💡 Bundle identifier found: \(bundleId)")
            } else {
                print("💡 No bundle identifier - this is the issue!")
            }
        }
    }
    
    func sendNotification(title: String, body: String, project: Project) async {
        // Check if we've sent a notification for this project recently
        let frequencyHours = await MainActor.run {
            SettingsManager.shared.settings.nudgeFrequencyHours
        }

        if let lastDate = lastNotificationDate[project.id] {
            let hoursSince = Date().timeIntervalSince(lastDate) / 3600
            if hoursSince < Double(frequencyHours) {
                return // Too soon
            }
        }

        // Check if notifications are available (proper app bundle)
        if Bundle.main.bundleIdentifier == nil {
            print("❌ Cannot send notifications: No bundle identifier (running without proper app bundle)")
            print("💡 Build and run from Xcode with proper entitlements for notifications to work")
            print("💡 Current bundle path: \(Bundle.main.bundlePath)")
            print("💡 Current bundle identifier: \(Bundle.main.bundleIdentifier ?? "nil")")
            print("💡 Attempting to send notification anyway for testing...")
        }

        // Check if running in DerivedData (Xcode build) - skip system notifications
        if Bundle.main.bundleURL.path.contains("DerivedData") {
            print("⚠️ Running in Xcode DerivedData - system notifications disabled, showing alert instead")
            await showTestAlert(title: title, body: body)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "PROJECT_NUDGE"
        content.userInfo = ["projectId": project.id.uuidString, "projectPath": project.path]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Send immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Notification sent for \(project.name)")
            lastNotificationDate[project.id] = Date()

            // Also show an immediate alert for testing purposes
            await showTestAlert(title: title, body: body)

        } catch {
            print("❌ Failed to send notification: \(error)")
            print("💡 This might be due to missing entitlements. Make sure the app is built with proper notification permissions.")
            if let bundleId = Bundle.main.bundleIdentifier {
                print("💡 Bundle identifier found: \(bundleId)")
            } else {
                print("💡 No bundle identifier - this is the issue!")
            }

            // Fallback: show alert since system notification failed
            await showTestAlert(title: title, body: body)
        }
    }
    
    func setupNotificationActions() async {
        // Check if we have a proper bundle identifier (required for notifications)
        if Bundle.main.bundleIdentifier == nil {
            print("❌ Cannot setup notification actions: No bundle identifier (running without proper app bundle)")
            print("💡 Current bundle path: \(Bundle.main.bundlePath)")
            print("💡 Current bundle identifier: \(Bundle.main.bundleIdentifier ?? "nil")")
            return
        }

        // Check if running in DerivedData (Xcode build) - skip setup
        if Bundle.main.bundleURL.path.contains("DerivedData") {
            print("⚠️ Running in Xcode DerivedData - skipping notification actions setup")
            return
        }

        let openAction = UNNotificationAction(
            identifier: "OPEN_PROJECT",
            title: "Open Project",
            options: .foreground
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_PROJECT",
            title: "Remind Later",
            options: []
        )

        let pauseAction = UNNotificationAction(
            identifier: "PAUSE_PROJECT",
            title: "Pause Tracking",
            options: .destructive
        )

        let category = UNNotificationCategory(
            identifier: "PROJECT_NUDGE",
            actions: [openAction, snoozeAction, pauseAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
        print("✅ Notification actions setup completed")
    }

    @MainActor
    private func showTestAlert(title: String, body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

