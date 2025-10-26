import Foundation

struct ProjectGoal: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var text: String
    var deadline: Date?
    var isCompleted: Bool
    var completedDate: Date?
    var createdDate: Date
    
    init(
        id: UUID = UUID(),
        text: String,
        deadline: Date? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.createdDate = createdDate
    }
}

struct Project: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var lastCommitDate: Date?
    var lastFileEditDate: Date?
    var createdDate: Date
    var isPaused: Bool
    var isCompleted: Bool
    var completedDate: Date?
    var goals: [ProjectGoal]
    var isGitRepository: Bool
    var commitCount: Int
    var fileChangeCount: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        lastCommitDate: Date? = nil,
        lastFileEditDate: Date? = nil,
        createdDate: Date = Date(),
        isPaused: Bool = false,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        goals: [ProjectGoal] = [],
        isGitRepository: Bool = false,
        commitCount: Int = 0,
        fileChangeCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.lastCommitDate = lastCommitDate
        self.lastFileEditDate = lastFileEditDate
        self.createdDate = createdDate
        self.isPaused = isPaused
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.goals = goals
        self.isGitRepository = isGitRepository
        self.commitCount = commitCount
        self.fileChangeCount = fileChangeCount
    }
    
    var lastActivityDate: Date? {
        [lastCommitDate, lastFileEditDate]
            .compactMap { $0 }
            .max()
    }
    
    var daysSinceLastActivity: Int {
        guard let lastActivity = lastActivityDate else {
            return Int.max
        }
        return Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
    }
    
    var momentumScore: Double {
        // Completed projects always have 100% momentum
        if isCompleted { return 100 }
        
        let days = daysSinceLastActivity
        if days == Int.max { return 0 }
        
        // Exponential decay: 100% at 0 days, ~50% at 7 days, ~10% at 30 days
        return max(0, min(100, 100 * exp(-Double(days) / 10.0)))
    }
    
    var activityStatus: ActivityStatus {
        let days = daysSinceLastActivity
        if days == Int.max { return .dormant }
        if days <= 2 { return .active }
        if days <= 7 { return .cooling }
        if days <= 30 { return .inactive }
        return .dormant
    }
    
    enum ActivityStatus: String, CaseIterable {
        case active = "Active"
        case cooling = "Cooling"
        case inactive = "Inactive"
        case dormant = "Dormant"
        
        var color: String {
            switch self {
            case .active: return "green"
            case .cooling: return "yellow"
            case .inactive: return "orange"
            case .dormant: return "red"
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "flame.fill"
            case .cooling: return "wind"
            case .inactive: return "moon.fill"
            case .dormant: return "zzz"
            }
        }
    }
}

