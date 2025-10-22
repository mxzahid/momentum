import Foundation

enum MotivationStyle: String, Codable, CaseIterable {
    case friendly = "Friendly"
    case guiltTrip = "Guilt Trip"
    case dataNerd = "Data Nerd"
    case coach = "Coach"
    
    var description: String {
        switch self {
        case .friendly:
            return "Warm and encouraging, like a supportive friend"
        case .guiltTrip:
            return "Playfully persistent, won't let you forget"
        case .dataNerd:
            return "Pure stats and insights, no fluff"
        case .coach:
            return "Direct and action-oriented, pushes you forward"
        }
    }
    
    func generateMessage(for project: Project) -> String {
        let days = project.daysSinceLastActivity
        let projectName = project.name
        
        switch self {
        case .friendly:
            if days <= 7 {
                return "Hey! It's been \(days) days since you worked on \(projectName). Want to pick it back up? ☕️"
            } else if days <= 14 {
                return "Missing \(projectName)? It's been \(days) days — maybe today's the day to dive back in?"
            } else {
                return "\(projectName) is waiting for you! \(days) days is a long time — let's bring it back to life 🌱"
            }
            
        case .guiltTrip:
            if days <= 7 {
                return "\(projectName) is feeling lonely after \(days) days... Don't abandon it now!"
            } else if days <= 14 {
                return "Remember \(projectName)? Yeah, it's been \(days) days. It remembers you too 👀"
            } else {
                return "\(days) days without \(projectName)? That project isn't going to finish itself, you know..."
            }
            
        case .dataNerd:
            let momentum = Int(project.momentumScore)
            return "Project: \(projectName) | Inactive: \(days)d | Momentum: \(momentum)% | Commits: \(project.commitCount) | Status: \(project.activityStatus.rawValue)"
            
        case .coach:
            if days <= 7 {
                return "\(projectName) — \(days) days out. Time to get back in the game. What's your next move?"
            } else if days <= 14 {
                return "\(days) days off \(projectName). You're losing momentum. Block 30 minutes today."
            } else {
                return "\(projectName): \(days) days dormant. Ship or kill it. Make the call."
            }
        }
    }
}

struct AppSettings: Codable {
    var motivationStyle: MotivationStyle
    var nudgeFrequencyHours: Int
    var enableAIInsights: Bool
    var ollamaEndpoint: String
    var ollamaModel: String
    var watchFolders: [String]
    var quietHoursStart: Int // 0-23
    var quietHoursEnd: Int // 0-23
    var hasCompletedOnboarding: Bool
    var enableGoalReminders: Bool
    
    static let `default` = AppSettings(
        motivationStyle: .friendly,
        nudgeFrequencyHours: 24,
        enableAIInsights: false,
        ollamaEndpoint: "http://localhost:11434",
        ollamaModel: "llama2",
        watchFolders: [],
        quietHoursStart: 22,
        quietHoursEnd: 8,
        hasCompletedOnboarding: false,
        enableGoalReminders: false
    )
}

