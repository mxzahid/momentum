import Foundation

class ProjectDiscoveryService {
    static let shared = ProjectDiscoveryService()
    
    private init() {}
    
    func discoverProjects(in directories: [String]) async -> [Project] {
        var discoveredProjects: [Project] = []
        
        for directory in directories {
            let url = URL(fileURLWithPath: directory)
            if let projects = await scanDirectory(url) {
                discoveredProjects.append(contentsOf: projects)
            }
        }
        
        return discoveredProjects
    }
    
    private func scanDirectory(_ url: URL) async -> [Project]? {
        let fileManager = FileManager.default
        var projects: [Project] = []
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        
        for case let fileURL as URL in enumerator {
            // Check if this is a git repository
            if fileURL.lastPathComponent == ".git" {
                let projectURL = fileURL.deletingLastPathComponent()
                
                // Skip if we've already found this project
                if projects.contains(where: { $0.path == projectURL.path }) {
                    continue
                }
                
                let projectName = projectURL.lastPathComponent
                let gitInfo = await GitService.shared.getRepositoryInfo(at: projectURL.path)
                
                let project = Project(
                    name: projectName,
                    path: projectURL.path,
                    lastCommitDate: gitInfo.lastCommitDate,
                    lastFileEditDate: getLastModificationDate(at: projectURL),
                    isGitRepository: true,
                    commitCount: gitInfo.commitCount
                )
                
                projects.append(project)
                
                // Skip subdirectories of this git repo
                enumerator.skipDescendants()
            }
        }
        
        return projects
    }
    
    func scanSingleProject(at path: String) async -> Project? {
        let url = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path) else {
            return nil
        }
        
        let projectName = url.lastPathComponent
        let isGit = fileManager.fileExists(atPath: url.appendingPathComponent(".git").path)
        
        var project = Project(
            name: projectName,
            path: path,
            lastFileEditDate: getLastModificationDate(at: url),
            isGitRepository: isGit
        )
        
        if isGit {
            let gitInfo = await GitService.shared.getRepositoryInfo(at: path)
            project.lastCommitDate = gitInfo.lastCommitDate
            project.commitCount = gitInfo.commitCount
        }
        
        return project
    }
    
    private func getLastModificationDate(at url: URL) -> Date? {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return nil
        }
        
        var latestDate: Date?
        var fileCount = 0
        
        for case let fileURL as URL in enumerator {
            fileCount += 1
            
            // Limit scanning to avoid performance issues
            if fileCount > 1000 {
                break
            }
            
            if let date = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                if latestDate == nil || date > latestDate! {
                    latestDate = date
                }
            }
        }
        
        return latestDate
    }
}

