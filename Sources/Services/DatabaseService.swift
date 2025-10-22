import Foundation
import SQLite

class DatabaseService {
    static let shared = DatabaseService()
    
    private var db: Connection?
    
    // Tables
    private let projects = Table("projects")
    
    // Columns
    private let id = Expression<String>("id")
    private let name = Expression<String>("name")
    private let path = Expression<String>("path")
    private let lastCommitDate = Expression<Date?>("last_commit_date")
    private let lastFileEditDate = Expression<Date?>("last_file_edit_date")
    private let createdDate = Expression<Date>("created_date")
    private let isPaused = Expression<Bool>("is_paused")
    private let goalsJSON = Expression<String>("goals_json")
    private let isGitRepository = Expression<Bool>("is_git_repository")
    private let commitCount = Expression<Int>("commit_count")
    private let fileChangeCount = Expression<Int>("file_change_count")
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let momentumDir = appSupport.appendingPathComponent("Momentum", isDirectory: true)
            
            if !fileManager.fileExists(atPath: momentumDir.path) {
                try fileManager.createDirectory(at: momentumDir, withIntermediateDirectories: true)
            }
            
            let dbPath = momentumDir.appendingPathComponent("momentum.sqlite3").path
            db = try Connection(dbPath)
            
            try db?.run(projects.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(name)
                t.column(path, unique: true)
                t.column(lastCommitDate)
                t.column(lastFileEditDate)
                t.column(createdDate)
                t.column(isPaused, defaultValue: false)
                t.column(goalsJSON, defaultValue: "[]")
                t.column(isGitRepository, defaultValue: false)
                t.column(commitCount, defaultValue: 0)
                t.column(fileChangeCount, defaultValue: 0)
            })
            
            print("✅ Database initialized at: \(dbPath)")
        } catch {
            print("❌ Database setup error: \(error)")
        }
    }
    
    // CRUD Operations
    func saveProject(_ project: Project) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        let goalsData = try JSONEncoder().encode(project.goals)
        let goalsString = String(data: goalsData, encoding: .utf8) ?? "[]"
        
        try db.run(projects.insert(or: .replace,
            id <- project.id.uuidString,
            name <- project.name,
            path <- project.path,
            lastCommitDate <- project.lastCommitDate,
            lastFileEditDate <- project.lastFileEditDate,
            createdDate <- project.createdDate,
            isPaused <- project.isPaused,
            goalsJSON <- goalsString,
            isGitRepository <- project.isGitRepository,
            commitCount <- project.commitCount,
            fileChangeCount <- project.fileChangeCount
        ))
    }
    
    func fetchAllProjects() throws -> [Project] {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        var projectList: [Project] = []
        
        for row in try db.prepare(projects) {
            let goalsString = row[goalsJSON]
            var projectGoals: [ProjectGoal] = []
            if let goalsData = goalsString.data(using: .utf8),
               let decoded = try? JSONDecoder().decode([ProjectGoal].self, from: goalsData) {
                projectGoals = decoded
            }
            
            let project = Project(
                id: UUID(uuidString: row[id]) ?? UUID(),
                name: row[name],
                path: row[path],
                lastCommitDate: row[lastCommitDate],
                lastFileEditDate: row[lastFileEditDate],
                createdDate: row[createdDate],
                isPaused: row[isPaused],
                goals: projectGoals,
                isGitRepository: row[isGitRepository],
                commitCount: row[commitCount],
                fileChangeCount: row[fileChangeCount]
            )
            projectList.append(project)
        }
        
        return projectList
    }
    
    func updateProject(_ project: Project) throws {
        try saveProject(project) // Using insert or replace
    }
    
    func deleteProject(_ project: Project) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        let projectToDelete = projects.filter(path == project.path)
        try db.run(projectToDelete.delete())
    }
    
    enum DatabaseError: Error {
        case notInitialized
    }
}

