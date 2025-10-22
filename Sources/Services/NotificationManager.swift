import Foundation
import UserNotifications

actor NotificationManager {
    static let shared = NotificationManager()
    
    private var lastNotificationDate: [UUID: Date] = [:]
    
    private init() {}
    
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("✅ Notification permission granted")
            }
        } catch {
            print("❌ Notification permission error: \(error)")
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
        } catch {
            print("❌ Failed to send notification: \(error)")
        }
    }
    
    func setupNotificationActions() {
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
    }
}

