import Foundation

actor ProjectMonitorService {
    static let shared = ProjectMonitorService()
    
    private var isMonitoring = false
    private var monitorTask: Task<Void, Never>?
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitorTask = Task {
            while !Task.isCancelled {
                await updateAllProjects()
                
                // Check for projects needing nudges
                await checkForNudges()
                
                // Wait 1 hour before next check
                try? await Task.sleep(nanoseconds: 3_600_000_000_000)
            }
        }
    }
    
    func stopMonitoring() {
        monitorTask?.cancel()
        isMonitoring = false
    }
    
    private func updateAllProjects() async {
        let projects = await MainActor.run { ProjectStore.shared.projects }
        
        for project in projects where !project.isPaused {
            // Update file modification date
            let url = URL(fileURLWithPath: project.path)
            if let lastModDate = getLastModificationDate(at: url) {
                var updatedProject = project
                updatedProject.lastFileEditDate = lastModDate
                
                // Update git info if it's a git repository
                if project.isGitRepository {
                    let gitInfo = await GitService.shared.getRepositoryInfo(at: project.path)
                    updatedProject.lastCommitDate = gitInfo.lastCommitDate
                    updatedProject.commitCount = gitInfo.commitCount
                }
                
                await MainActor.run {
                    ProjectStore.shared.updateProject(updatedProject)
                }
            }
        }
    }
    
    private func checkForNudges() async {
        let (projects, quietStart, quietEnd, motivationStyle) = await MainActor.run {
            (
                ProjectStore.shared.projects,
                SettingsManager.shared.settings.quietHoursStart,
                SettingsManager.shared.settings.quietHoursEnd,
                SettingsManager.shared.settings.motivationStyle
            )
        }
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Check if we're in quiet hours
        let isQuietTime = if quietStart < quietEnd {
            currentHour >= quietStart && currentHour < quietEnd
        } else {
            currentHour >= quietStart || currentHour < quietEnd
        }
        
        if isQuietTime {
            return
        }
        
        // Find projects that need nudges (inactive for > 7 days, not paused)
        let projectsNeedingNudge = projects.filter { project in
            !project.isPaused && project.daysSinceLastActivity >= 7
        }
        
        // Send nudge for most inactive project
        if let project = projectsNeedingNudge.sorted(by: { $0.daysSinceLastActivity > $1.daysSinceLastActivity }).first {
            let message = motivationStyle.generateMessage(for: project)
            
            await NotificationManager.shared.sendNotification(
                title: "Project Needs Attention",
                body: message,
                project: project
            )
        }
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
            if fileCount > 1000 { break }
            
            if let date = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                if latestDate == nil || date > latestDate! {
                    latestDate = date
                }
            }
        }
        
        return latestDate
    }
}

