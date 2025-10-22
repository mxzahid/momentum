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
            } catch {
                print("❌ Failed to load projects: \(error)")
            }
            isLoading = false
        }
    }
    
    func addProject(_ project: Project) {
        Task {
            do {
                try DatabaseService.shared.saveProject(project)
                await MainActor.run {
                    projects.append(project)
                    sortProjects()
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
                    }
                }
            } catch {
                print("❌ Failed to update project: \(error)")
            }
        }
    }
    
    func deleteProject(_ project: Project) {
        Task {
            do {
                try DatabaseService.shared.deleteProject(project)
                await MainActor.run {
                    projects.removeAll { $0.id == project.id }
                }
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
}

