import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedProjectID: Project.ID?
    @State private var searchText = ""
    @State private var filterStatus: Project.ActivityStatus?
    @State private var showingAddProject = false
    @State private var aiInsight: String?
    
    var filteredProjects: [Project] {
        var filtered = projectStore.projects
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let status = filterStatus {
            filtered = filtered.filter { $0.activityStatus == status }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding([.horizontal, .top], 12)
                
                // Status filters - vertical layout for better fit
                VStack(spacing: 8) {
                    FilterButtonCompact(
                        title: "All",
                        count: projectStore.projects.count,
                        isSelected: filterStatus == nil,
                        icon: "circle.grid.3x3.fill"
                    ) {
                        filterStatus = nil
                    }
                    
                    ForEach(Project.ActivityStatus.allCases, id: \.self) { status in
                        FilterButtonCompact(
                            title: status.rawValue,
                            count: projectStore.projects.filter { $0.activityStatus == status }.count,
                            isSelected: filterStatus == status,
                            icon: status.icon,
                            color: colorFromString(status.color)
                        ) {
                            filterStatus = status
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                // Project list
                if filteredProjects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No projects yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Click + to add")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                } else {
                    List(filteredProjects, selection: $selectedProjectID) { project in
                        ProjectListRow(project: project)
                            .tag(project.id)
                    }
                    .listStyle(.sidebar)
                }
                
                Divider()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { showingAddProject = true }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                    .help("Add Project")
                    
                    Button(action: refreshAllProjects) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .disabled(projectStore.isLoading)
                    .help("Refresh All")
                    
                    Spacer()
                    
                    Text("\(projectStore.projects.count) projects")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
            }
            .frame(minWidth: 280)
        } detail: {
            // Detail view
            if let project = projectStore.projects.first(where: { $0.id == selectedProjectID }) {
                ProjectDetailView(project: project)
            } else {
                EmptyProjectView()
            }
        }
        .navigationTitle("Momentum")
        // AI Insights toolbar button - COMMENTED OUT
        /*
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if settingsManager.settings.enableAIInsights {
                    Button(action: generateAIInsight) {
                        Label("AI Insight", systemImage: "sparkles")
                    }
                }
            }
        }
        */
        .sheet(isPresented: $showingAddProject) {
            AddProjectSheet()
        }
        // AI Insights alert - COMMENTED OUT
        /*
        .alert("AI Insight", isPresented: .constant(aiInsight != nil)) {
            Button("OK") { aiInsight = nil }
        } message: {
            if let insight = aiInsight {
                Text(insight)
            }
        }
        */
        .onChange(of: filterStatus) { _ in
            let visibleProjects = filteredProjects
            if let first = visibleProjects.first {
                selectedProjectID = first.id
            } else {
                selectedProjectID = nil
            }
        }
        .onChange(of: projectStore.projects) { projects in
            guard let selectedProjectID else { return }
            if !projects.contains(where: { $0.id == selectedProjectID }) {
                self.selectedProjectID = nil
            }
        }
    }
    
    private func refreshAllProjects() {
        Task {
            for project in projectStore.projects {
                await projectStore.refreshProject(project)
            }
        }
    }
    
    private func generateAIInsight() {
        Task {
            if let insight = await AIService.shared.generateProjectSummary(projects: projectStore.projects) {
                await MainActor.run {
                    aiInsight = insight
                }
            }
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "blue": return .blue
        default: return .gray
        }
    }
}

struct FilterButtonCompact: View {
    let title: String
    let count: Int
    let isSelected: Bool
    var icon: String = "circle.fill"
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? color : .secondary)
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? color : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isSelected ? color.opacity(0.15) : Color.gray.opacity(0.1))
                .cornerRadius(4)
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? color.opacity(0.08) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .onTapGesture {
            action()
        }
    }
}

struct ProjectListRow: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(project.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Spacer()
                
                if project.isPaused {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 6) {
                if project.isGitRepository {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                Text(timeAgoText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Momentum percentage
                Text("\(Int(project.momentumScore))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(statusColor)
            }
            
            // Momentum bar
            MomentumBar(score: project.momentumScore)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .opacity(project.isPaused ? 0.5 : 1.0)
    }
    
    private var statusColor: Color {
        switch project.activityStatus {
        case .active: return .green
        case .cooling: return .yellow
        case .inactive: return .orange
        case .dormant: return .red
        }
    }
    
    private var timeAgoText: String {
        let days = project.daysSinceLastActivity
        if days == Int.max { return "Never" }
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days)d ago"
    }
}

struct MomentumBar: View {
    let score: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.15))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, geometry.size.width * CGFloat(score / 100)))
            }
        }
        .frame(height: 4)
    }
    
    private var color: Color {
        if score > 70 { return .green }
        if score > 40 { return .yellow }
        if score > 20 { return .orange }
        return .red
    }
}

struct EmptyProjectView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Project Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select a project from the sidebar to view details")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

