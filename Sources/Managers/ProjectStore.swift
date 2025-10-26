import Foundation
import SwiftUI

@MainActor
class ProjectStore: ObservableObject {
    static let shared = ProjectStore()
    
    @Published var projects: [Project] = []
    @Published var isLoading = false
    
    private init() {
        loadProjects()
    }
    
    func loadProjects() {
        isLoading = true
        Task {
            do {
                projects = try DatabaseService.shared.fetchAllProjects()
                    .sorted { ($0.lastActivityDate ?? .distantPast) > ($1.lastActivityDate ?? .distantPast) }

                // Set up watchers for all loaded projects
                await setupWatchers()

                // Update menu bar icon
                await MainActor.run {
                    MenuBarManager.updateIcon()
                }
            } catch {
                print("❌ Failed to load projects: \(error)")
            }
            isLoading = false
        }
    }
    
    func setupWatchers() async {
        for project in projects where !project.isPaused && !project.isCompleted {
            await ProjectMonitorService.shared.addWatcher(for: project)
        }
    }
    
    func addProject(_ project: Project) {
        Task {
            do {
                try DatabaseService.shared.saveProject(project)
                await MainActor.run {
                    projects.append(project)
                    sortProjects()
                    MenuBarManager.updateIcon()
                }

                // Start watching this project for changes
                if !project.isPaused && !project.isCompleted {
                    await ProjectMonitorService.shared.addWatcher(for: project)
                }
            } catch {
                print("❌ Failed to add project: \(error)")
            }
        }
    }
    
    func updateProject(_ project: Project) {
        Task {
            do {
                try DatabaseService.shared.updateProject(project)
                await MainActor.run {
                    if let index = projects.firstIndex(where: { $0.id == project.id }) {
                        projects[index] = project
                        sortProjects()
                        MenuBarManager.updateIcon()
                    }
                }

                // Update watcher based on pause state and completion status
                if project.isPaused || project.isCompleted {
                    await ProjectMonitorService.shared.removeWatcher(for: project.path)
                } else {
                    await ProjectMonitorService.shared.addWatcher(for: project)
                }
            } catch {
                print("❌ Failed to update project: \(error)")
            }
        }
    }
    
    // Internal update method for file system changes (doesn't update watchers)
    func updateProjectFromFileSystem(_ project: Project) {
        Task {
            do {
                try DatabaseService.shared.updateProject(project)
                await MainActor.run {
                    if let index = projects.firstIndex(where: { $0.id == project.id }) {
                        projects[index] = project
                        sortProjects()
                        MenuBarManager.updateIcon()
                    }
                }
            } catch {
                print("❌ Failed to update project from file system: \(error)")
            }
        }
    }
    
    func deleteProject(_ project: Project) {
        Task {
            do {
                try DatabaseService.shared.deleteProject(project)
                await MainActor.run {
                    projects.removeAll { $0.id == project.id }
                    MenuBarManager.updateIcon()
                }

                // Stop watching this project
                await ProjectMonitorService.shared.removeWatcher(for: project.path)
            } catch {
                print("❌ Failed to delete project: \(error)")
            }
        }
    }
    
    func discoverProjects(in directories: [String]) async {
        await MainActor.run {
            isLoading = true
        }
        
        let discovered = await ProjectDiscoveryService.shared.discoverProjects(in: directories)
        
        await MainActor.run {
            for project in discovered {
                // Only add if not already tracked
                if !projects.contains(where: { $0.path == project.path }) {
                    addProject(project)
                }
            }
            isLoading = false
            MenuBarManager.updateIcon()
        }
    }
    
    func refreshProject(_ project: Project) async {
        if let updated = await ProjectDiscoveryService.shared.scanSingleProject(at: project.path) {
            var refreshed = project
            refreshed.lastCommitDate = updated.lastCommitDate
            refreshed.lastFileEditDate = updated.lastFileEditDate
            refreshed.commitCount = updated.commitCount
            
            await MainActor.run {
                updateProject(refreshed)
            }
        }
    }
    
    private func sortProjects() {
        projects.sort { ($0.lastActivityDate ?? .distantPast) > ($1.lastActivityDate ?? .distantPast) }
    }
    
    var activeProjects: [Project] {
        projects.filter { $0.activityStatus == .active && !$0.isPaused }
    }
    
    var inactiveProjects: [Project] {
        projects.filter { $0.daysSinceLastActivity > 7 && !$0.isPaused }
    }
    
    var pausedProjects: [Project] {
        projects.filter { $0.isPaused }
    }
    
    var completedProjects: [Project] {
        projects.filter { $0.isCompleted }
    }
    
    var activeAndOngoingProjects: [Project] {
        projects.filter { !$0.isCompleted }
    }
    
    func completeProject(_ project: Project) {
        var completed = project
        completed.isCompleted = true
        completed.completedDate = Date()
        updateProject(completed)
    }
    
    func uncompleteProject(_ project: Project) {
        var uncompleted = project
        uncompleted.isCompleted = false
        uncompleted.completedDate = nil
        updateProject(uncompleted)
    }

    func toggleGoal(_ goal: ProjectGoal, in project: Project) {
        var updatedProject = project
        if let goalIndex = updatedProject.goals.firstIndex(where: { $0.id == goal.id }) {
            var updatedGoal = updatedProject.goals[goalIndex]
            updatedGoal.isCompleted.toggle()
            updatedGoal.completedDate = updatedGoal.isCompleted ? Date() : nil
            updatedProject.goals[goalIndex] = updatedGoal
            updateProject(updatedProject)
        }
    }

    func deleteGoal(_ goal: ProjectGoal, in project: Project) {
        var updatedProject = project
        updatedProject.goals.removeAll { $0.id == goal.id }
        updateProject(updatedProject)
    }
}

