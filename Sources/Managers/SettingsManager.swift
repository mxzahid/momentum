import Foundation
import SwiftUI

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }
    
    var hasCompletedOnboarding: Bool {
        settings.hasCompletedOnboarding
    }
    
    private let settingsKey = "MomentumSettings"
    
    private init() {
        self.settings = Self.loadSettings()
    }
    
    private static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "MomentumSettings"),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return decoded
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
    }
    
    func updateMotivationStyle(_ style: MotivationStyle) {
        settings.motivationStyle = style
    }
    
    func updateNudgeFrequency(_ hours: Int) {
        settings.nudgeFrequencyHours = hours
    }
    
    func toggleAIInsights(_ enabled: Bool) {
        settings.enableAIInsights = enabled
    }
    
    func updateOllamaSettings(endpoint: String, model: String) {
        settings.ollamaEndpoint = endpoint
        settings.ollamaModel = model
    }
    
    func addWatchFolder(_ path: String) {
        if !settings.watchFolders.contains(path) {
            settings.watchFolders.append(path)
        }
    }
    
    func removeWatchFolder(_ path: String) {
        settings.watchFolders.removeAll { $0 == path }
    }
    
    func updateQuietHours(start: Int, end: Int) {
        settings.quietHoursStart = start
        settings.quietHoursEnd = end
    }
    
    // Reset onboarding to see it again
    func resetOnboarding() {
        settings.hasCompletedOnboarding = false
    }
}

