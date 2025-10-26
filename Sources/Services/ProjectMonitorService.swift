import Foundation
import CoreServices

// MARK: - FileSystemWatcher

class FileSystemWatcher {
    private let path: String
    private let onChange: () -> Void
    private var eventStream: FSEventStreamRef?
    private var lastEventTime: Date = .now
    private let debounceInterval: TimeInterval = 2.0
    
    init(path: String, onChange: @escaping () -> Void) {
        self.path = path
        self.onChange = onChange
    }
    
    func start() {
        let pathsToWatch = [path] as CFArray
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let callback: FSEventStreamCallback = { (
            streamRef: ConstFSEventStreamRef,
            clientCallBackInfo: UnsafeMutableRawPointer?,
            numEvents: Int,
            eventPaths: UnsafeMutableRawPointer,
            eventFlags: UnsafePointer<FSEventStreamEventFlags>,
            eventIds: UnsafePointer<FSEventStreamEventId>
        ) in
            guard let info = clientCallBackInfo else { return }
            let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(info).takeUnretainedValue()
            watcher.handleEvents()
        }
        
        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            2.0, // Latency in seconds
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        )
        
        if let stream = eventStream {
            FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
            FSEventStreamStart(stream)
        }
    }
    
    func stop() {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }
    }
    
    private func handleEvents() {
        let now = Date()
        
        // Debounce: only trigger if enough time has passed since last event
        if now.timeIntervalSince(lastEventTime) >= debounceInterval {
            lastEventTime = now
            onChange()
        }
    }
    
    deinit {
        stop()
    }
}

// MARK: - ProjectMonitorService

actor ProjectMonitorService {
    static let shared = ProjectMonitorService()
    
    private var isMonitoring = false
    private var monitorTask: Task<Void, Never>?
    private var fileSystemWatchers: [String: FileSystemWatcher] = [:]
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Start file system watchers for all projects
        Task {
            await setupFileSystemWatchers()
        }
        
        monitorTask = Task {
            while !Task.isCancelled {
                // Check for projects needing nudges
                await checkForNudges()
                
                // Wait 1 hour before next nudge check
                try? await Task.sleep(nanoseconds: 3_600_000_000_000)
            }
        }
    }
    
    func stopMonitoring() {
        monitorTask?.cancel()
        isMonitoring = false
        
        // Stop all file system watchers
        for (_, watcher) in fileSystemWatchers {
            watcher.stop()
        }
        fileSystemWatchers.removeAll()
    }
    
    private func setupFileSystemWatchers() async {
        let projects = await MainActor.run { ProjectStore.shared.projects }
        
        for project in projects where !project.isPaused && !project.isCompleted {
            if fileSystemWatchers[project.path] == nil {
                let projectPath = project.path
                let watcher = FileSystemWatcher(path: projectPath) { [weak self] in
                    print("📁 File change detected in: \(projectPath)")
                    Task {
                        await self?.handleFileSystemChange(forPath: projectPath)
                    }
                }
                watcher.start()
                fileSystemWatchers[projectPath] = watcher
                print("👀 Started watching: \(projectPath)")
            }
        }
    }
    
    func addWatcher(for project: Project) {
        guard fileSystemWatchers[project.path] == nil else { 
            print("⚠️ Watcher already exists for: \(project.path)")
            return 
        }
        
        let projectPath = project.path
        let watcher = FileSystemWatcher(path: projectPath) { [weak self] in
            print("📁 File change detected in: \(projectPath)")
            Task {
                await self?.handleFileSystemChange(forPath: projectPath)
            }
        }
        watcher.start()
        fileSystemWatchers[projectPath] = watcher
        print("👀 Started watching: \(projectPath)")
    }
    
    func removeWatcher(for projectPath: String) {
        fileSystemWatchers[projectPath]?.stop()
        fileSystemWatchers.removeValue(forKey: projectPath)
        print("🛑 Stopped watching: \(projectPath)")
    }
    
    private func handleFileSystemChange(forPath projectPath: String) async {
        print("🔄 Processing file change for: \(projectPath)")
        
        // Debounce rapid changes - wait a bit before updating
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Get the current project from the store
        let project = await MainActor.run { 
            ProjectStore.shared.projects.first(where: { $0.path == projectPath })
        }
        
        guard let project = project else {
            print("⚠️ Project not found for path: \(projectPath)")
            return
        }
        
        // Update the specific project
        let url = URL(fileURLWithPath: project.path)
        if let lastModDate = getLastModificationDate(at: url) {
            var updatedProject = project
            updatedProject.lastFileEditDate = lastModDate
            
            print("📝 Last file edit date updated: \(lastModDate)")
            
            // Update git info if it's a git repository
            if project.isGitRepository {
                let gitInfo = await GitService.shared.getRepositoryInfo(at: project.path)
                updatedProject.lastCommitDate = gitInfo.lastCommitDate
                updatedProject.commitCount = gitInfo.commitCount
                print("🔀 Git info updated - commits: \(gitInfo.commitCount)")
            }
            
            let projectToUpdate = updatedProject
            await MainActor.run {
                print("✅ Updating project in store: \(projectToUpdate.name)")
                ProjectStore.shared.updateProjectFromFileSystem(projectToUpdate)
            }
        }
    }
    
    private func updateAllProjects() async {
        let projects = await MainActor.run { ProjectStore.shared.projects }
        
        for project in projects where !project.isPaused && !project.isCompleted {
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
                
                let projectToUpdate = updatedProject
                await MainActor.run {
                    ProjectStore.shared.updateProjectFromFileSystem(projectToUpdate)
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
        
        // Find projects that need nudges (inactive for > 7 days, not paused, not completed)
        let projectsNeedingNudge = projects.filter { project in
            !project.isPaused && !project.isCompleted && project.daysSinceLastActivity >= 7
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

