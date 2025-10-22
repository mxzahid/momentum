import Foundation

class GitService {
    static let shared = GitService()
    
    private init() {}
    
    struct GitInfo {
        var lastCommitDate: Date?
        var commitCount: Int
        var recentCommits: [String]
    }
    
    func getRepositoryInfo(at path: String) async -> GitInfo {
        var info = GitInfo(lastCommitDate: nil, commitCount: 0, recentCommits: [])
        
        // Get last commit date
        if let lastCommitDateString = await runGitCommand(["log", "-1", "--format=%cI"], in: path),
           !lastCommitDateString.isEmpty {
            let formatter = ISO8601DateFormatter()
            info.lastCommitDate = formatter.date(from: lastCommitDateString.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        // Get commit count
        if let countString = await runGitCommand(["rev-list", "--count", "HEAD"], in: path),
           let count = Int(countString.trimmingCharacters(in: .whitespacesAndNewlines)) {
            info.commitCount = count
        }
        
        // Get recent commit messages (last 5)
        if let commits = await runGitCommand(["log", "-5", "--format=%s"], in: path) {
            info.recentCommits = commits.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
        
        return info
    }
    
    func getRecentActivity(at path: String, days: Int = 30) async -> [(date: Date, commits: Int)] {
        var activity: [(date: Date, commits: Int)] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Get commits grouped by date
        if let output = await runGitCommand(
            ["log", "--since=\(days).days.ago", "--format=%cd", "--date=short"],
            in: path
        ) {
            let dates = output.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            // Count commits per date
            var commitsByDate: [String: Int] = [:]
            for dateString in dates {
                commitsByDate[dateString, default: 0] += 1
            }
            
            // Convert to array of tuples
            for (dateString, count) in commitsByDate {
                if let date = dateFormatter.date(from: dateString) {
                    activity.append((date: date, commits: count))
                }
            }
            
            activity.sort { $0.date > $1.date }
        }
        
        return activity
    }
    
    private func runGitCommand(_ arguments: [String], in directory: String) async -> String? {
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = arguments
            process.currentDirectoryURL = URL(fileURLWithPath: directory)
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(returning: nil)
                }
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}

