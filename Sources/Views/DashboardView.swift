import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedProjectID: Project.ID?
    @State private var searchText = ""
    @State private var filterStatus: Project.ActivityStatus?
    @State private var showingAddProject = false
    @State private var aiInsight: String?
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
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
            // MARK: - Modernized Sidebar
            ZStack {
                // Subtle ambient gradient for sidebar
                LinearGradient(
                    colors: [
                        Color(hue: 0.0, saturation: 0.02, brightness: 0.10),
                        Color(hue: 0.0, saturation: 0.01, brightness: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Translucent Search Field
                    TranslucentSearchField(text: $searchText)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                    
                    // Status Filters with Tahoe Aesthetic
                    TahoeStatusFilters(
                        projects: projectStore.projects,
                        filterStatus: $filterStatus
                    )
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    
                    // Project List
                    if filteredProjects.isEmpty {
                        EmptySidebarState()
                    } else {
                        GlassProjectList(
                            projects: filteredProjects,
                            selectedProjectID: $selectedProjectID
                        )
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.05))
                    
                    // Frosted Bottom Action Bar
                    FrostedActionBar(
                        projectCount: projectStore.projects.count,
                        isLoading: projectStore.isLoading,
                        onAdd: { showingAddProject = true },
                        onRefresh: refreshAllProjects
                    )
                }
            }
            .frame(minWidth: 280)
        } detail: {
            // Detail view
            if let project = projectStore.projects.first(where: { $0.id == selectedProjectID }) {
                ProjectDetailView(project: project)
            } else {
                ModernEmptyProjectView()
            }
        }
        .navigationTitle("Momentum")
        .sheet(isPresented: $showingAddProject) {
            AddProjectSheet()
        }
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

// MARK: - Translucent Search Field

struct TranslucentSearchField: View {
    @Binding var text: String
    @State private var isFocused = false
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(isFocused ? 0.8 : 0.4))
            
            TextField("Search projects...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .onFocusChange { focused in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isFocused = focused
                    }
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                // Glass capsule
                if reduceTransparency {
                    Capsule()
                        .fill(Color(white: 0.15))
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                }
                
                // Inner shadow
                Capsule()
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    .blur(radius: 2)
                    .offset(y: 1)
            }
        )
        .overlay(
            Capsule()
                .stroke(
                    isFocused
                        ? Color.blue.opacity(0.4)
                        : Color.white.opacity(0.1),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: isFocused ? Color.blue.opacity(0.3) : Color.clear,
            radius: 8,
            x: 0,
            y: 2
        )
    }
}

// Helper for TextField focus state
extension View {
    func onFocusChange(_ action: @escaping (Bool) -> Void) -> some View {
        self.background(
            FocusHelper(onFocusChange: action)
        )
    }
}

struct FocusHelper: NSViewRepresentable {
    let onFocusChange: (Bool) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Tahoe Status Filters

struct TahoeStatusFilters: View {
    let projects: [Project]
    @Binding var filterStatus: Project.ActivityStatus?
    
    var body: some View {
        VStack(spacing: 10) {
            TahoeFilterButton(
                title: "All",
                count: projects.count,
                isSelected: filterStatus == nil,
                icon: "circle.grid.3x3.fill",
                color: .blue
            ) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    filterStatus = nil
                }
            }
            
            ForEach(Project.ActivityStatus.allCases, id: \.self) { status in
                TahoeFilterButton(
                    title: status.rawValue,
                    count: projects.filter { $0.activityStatus == status }.count,
                    isSelected: filterStatus == status,
                    icon: status.icon,
                    color: colorForStatus(status)
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        filterStatus = status
                    }
                }
            }
        }
    }
    
    private func colorForStatus(_ status: Project.ActivityStatus) -> Color {
        DynamicAccentColor.forStatus(status)
    }
}

struct TahoeFilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconView
                titleView
                Spacer()
                countBadge
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(buttonBackground)
            .overlay(buttonBorder)
            .scaleEffect(isHovered && !reduceMotion ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var iconView: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .blur(radius: 6)
            }
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? color : .white.opacity(0.5))
                .frame(width: 22, height: 22)
        }
    }
    
    private var titleView: some View {
        Text(title)
            .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
    }
    
    private var countBadge: some View {
        Text("\(count)")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(isSelected ? color : .white.opacity(0.5))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    private var buttonBackground: some View {
        ZStack {
            if reduceTransparency {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.15))
                }
            } else {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .opacity(0.6)
                }
            }
            
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
            }
            
            if isHovered && !isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            }
        }
    }
    
    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isSelected ? color.opacity(0.5) : (isHovered ? Color.white.opacity(0.2) : Color.clear),
                lineWidth: 1.5
            )
    }
}

// MARK: - Glass Project List

struct GlassProjectList: View {
    let projects: [Project]
    @Binding var selectedProjectID: Project.ID?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(projects) { project in
                    GlassProjectRow(
                        project: project,
                        isSelected: selectedProjectID == project.id
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedProjectID = project.id
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }
}

struct GlassProjectRow: View {
    let project: Project
    let isSelected: Bool
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            topRow
            bottomRow
            LiquidMomentumBar(score: project.momentumScore, color: statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackground)
        .overlay(rowBorder)
        .opacity(project.isPaused ? 0.6 : 1.0)
        .scaleEffect(isHovered && !reduceMotion ? 1.01 : 1.0)
        .shadow(color: isSelected ? statusColor.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var topRow: some View {
        HStack(spacing: 10) {
            statusIndicator
            
            Text(project.name)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundColor(.white.opacity(isSelected ? 1.0 : 0.85))
                .lineLimit(1)
            
            Spacer()
            
            if project.isPaused {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
    
    private var statusIndicator: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(statusColor.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .blur(radius: 4)
            }
            
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
        }
    }
    
    private var bottomRow: some View {
        HStack(spacing: 8) {
            if project.isGitRepository {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text(timeAgoText)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
            
            Spacer()
            
            Text("\(Int(project.momentumScore))%")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(statusColor)
        }
    }
    
    private var rowBackground: some View {
        ZStack {
            if reduceTransparency {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.18))
                }
            } else {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .opacity(0.7)
                }
            }
            
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor.opacity(0.1))
            }
            
            if isHovered && !isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            }
        }
    }
    
    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isSelected ? statusColor.opacity(0.5) : (isHovered ? Color.white.opacity(0.15) : Color.clear),
                lineWidth: 1.5
            )
    }
    
    private var statusColor: Color {
        DynamicAccentColor.forStatus(project.activityStatus)
    }
    
    private var timeAgoText: String {
        let days = project.daysSinceLastActivity
        if days == Int.max { return "Never" }
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days)d ago"
    }
}

struct LiquidMomentumBar: View {
    let score: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                            .blur(radius: 1)
                    )
                
                // Progress fill with gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                color,
                                color.opacity(0.8),
                                color.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, geometry.size.width * CGFloat(score / 100)))
                    .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 0)
            }
        }
        .frame(height: 5)
    }
}

// MARK: - Empty States

struct EmptySidebarState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: 6) {
                Text("No projects yet")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Click + to add your first project")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(24)
    }
}

struct ModernEmptyProjectView: View {
    var body: some View {
        ZStack {
            // Ambient gradient
            LinearGradient(
                colors: [
                    Color(hue: 0.0, saturation: 0.02, brightness: 0.10),
                    Color(hue: 0.0, saturation: 0.01, brightness: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    // Glow
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .blur(radius: 40)
                    
                    Image(systemName: "tray")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                VStack(spacing: 10) {
                    Text("No Project Selected")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Select a project from the sidebar to view details")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }
}

// MARK: - Frosted Action Bar

struct FrostedActionBar: View {
    let projectCount: Int
    let isLoading: Bool
    let onAdd: () -> Void
    let onRefresh: () -> Void
    
    @State private var addHovered = false
    @State private var refreshHovered = false
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    var body: some View {
        HStack(spacing: 14) {
            actionButton(
                icon: "plus",
                isHovered: $addHovered,
                action: onAdd,
                help: "Add Project"
            )
            
            actionButton(
                icon: "arrow.clockwise",
                isHovered: $refreshHovered,
                action: onRefresh,
                help: "Refresh All",
                disabled: isLoading
            )
            
            Spacer()
            
            Text("\(projectCount) projects")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(barBackground)
    }
    
    private func actionButton(
        icon: String,
        isHovered: Binding<Bool>,
        action: @escaping () -> Void,
        help: String,
        disabled: Bool = false
    ) -> some View {
        Button(action: action) {
            ZStack {
                Group {
                    if reduceTransparency {
                        Circle()
                            .fill(Color(white: 0.2))
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.6)
                    }
                }
                .frame(width: 32, height: 32)
                
                if isHovered.wrappedValue {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                }
                
                Image(systemName: icon)
                    .font(.system(size: icon == "plus" ? 14 : 13, weight: .semibold))
                    .foregroundColor(isHovered.wrappedValue ? .blue : .white.opacity(0.7))
            }
            .overlay(
                Circle()
                    .stroke(isHovered.wrappedValue ? Color.blue.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isHovered.wrappedValue ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered.wrappedValue)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(help)
        .onHover { hovering in isHovered.wrappedValue = hovering }
    }
    
    private var barBackground: some View {
        Group {
            if reduceTransparency {
                Rectangle()
                    .fill(Color(white: 0.12))
            } else {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
            }
        }
    }
}

