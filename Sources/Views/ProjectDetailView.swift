import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingGoalSheet = false
    @State private var showingDeleteAlert = false
    @State private var aiInsight: AIService.AIInsight?
    @State private var isLoadingAI = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with momentum score
                    VStack(spacing: 0) {
                    // Momentum Circle with glow effect
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [momentumColor.opacity(0.2), Color.clear],
                                    center: .center,
                                    startRadius: 60,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 20)
                        
                        // Background track
                        Circle()
                            .stroke(Color.gray.opacity(0.12), lineWidth: 14)
                            .frame(width: 140, height: 140)
                        
                        // Animated progress ring
                        Circle()
                            .trim(from: 0, to: CGFloat(project.momentumScore / 100))
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        momentumColor,
                                        momentumColor.opacity(0.8),
                                        momentumColor.opacity(0.5)
                                    ],
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: momentumColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: project.momentumScore)
                        
                        // Center content
                        VStack(spacing: 4) {
                            Text("\(Int(project.momentumScore))%")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [momentumColor, momentumColor.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: momentumColor.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Text("Momentum")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                        }
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                    
                    // Project name and path
                    VStack(spacing: 6) {
                        Text(project.name)
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text(project.path)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .textSelection(.enabled)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                    
                    // Status badge
                    HStack(spacing: 8) {
                        StatusBadge(status: project.activityStatus)
                        
                        if project.isPaused {
                            Label("Paused", systemImage: "pause.circle.fill")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        // Gradient background
                        LinearGradient(
                            colors: [
                                Color(NSColor.controlBackgroundColor).opacity(0.6),
                                Color(NSColor.controlBackgroundColor).opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Subtle pattern
                        Circle()
                            .fill(momentumColor.opacity(0.03))
                            .frame(width: 300, height: 300)
                            .blur(radius: 60)
                            .offset(y: -50)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    StatCard(
                        icon: "calendar.circle.fill",
                        title: "Last Activity",
                        value: lastActivityText,
                        color: .blue
                    )
                    
                    StatCard(
                        icon: "arrow.triangle.branch",
                        title: "Total Commits",
                        value: "\(project.commitCount)",
                        color: .purple
                    )
                    
                    StatCard(
                        icon: "clock.fill",
                        title: "Days Inactive",
                        value: project.daysSinceLastActivity == Int.max ? "∞" : "\(project.daysSinceLastActivity)",
                        color: project.activityStatus == .dormant ? .red : .orange
                    )
                }
                
                // Goals Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Goals", systemImage: "target")
                            .font(.system(size: 15, weight: .semibold))
                        
                        if !project.goals.isEmpty {
                            Text("\(project.goals.filter { !$0.isCompleted }.count)/\(project.goals.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingGoalSheet = true }) {
                            Text(project.goals.isEmpty ? "Add" : "Manage")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if project.goals.isEmpty {
                        Button(action: { showingGoalSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Add goals for this project")
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(project.goals.prefix(3)) { goal in
                                ProjectGoalRow(goal: goal)
                            }
                            
                            if project.goals.count > 3 {
                                Button(action: { showingGoalSheet = true }) {
                                    Text("View all \(project.goals.count) goals")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
                
                // AI Insights - COMMENTED OUT
                /*
                if settingsManager.settings.enableAIInsights {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AI Insights", systemImage: "sparkles")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.purple)
                            
                            Spacer()
                            
                            Button(action: loadAIInsight) {
                                HStack(spacing: 4) {
                                    if isLoadingAI {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 11))
                                    }
                                    Text(isLoadingAI ? "Generating..." : "Generate")
                                        .font(.caption)
                                }
                                .foregroundColor(.purple)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoadingAI)
                        }
                        
                        if let insight = aiInsight {
                            VStack(alignment: .leading, spacing: 10) {
                                InsightRow(icon: "chart.bar.fill", title: "Summary", text: insight.summary)
                                InsightRow(icon: "arrow.right.circle.fill", title: "Next Action", text: insight.nextAction)
                                InsightRow(icon: "heart.fill", title: "Motivation", text: insight.motivation)
                            }
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.purple.opacity(0.6))
                                Text("Generate AI insights to get personalized recommendations")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.1), lineWidth: 1)
                    )
                }
                */
                
                // Quick Actions Section
                HStack(spacing: 12) {
                    ActionIconButton(
                        icon: "chevron.left.forwardslash.chevron.right",
                        color: .blue,
                        label: "Open in VSCode",
                        action: openInVSCode
                    )
                    
                    ActionIconButton(
                        icon: "folder.fill",
                        color: .blue,
                        label: "Open in Finder",
                        action: openInFinder
                    )
                }
            }
            .padding()
            .padding(.top, 50) // Space for floating action buttons
        }
            
            // Floating action buttons in top right
            HStack(spacing: 8) {
                FloatingActionButton(
                    icon: project.isPaused ? "play.circle.fill" : "pause.circle.fill",
                    color: project.isPaused ? .green : .orange,
                    tooltip: project.isPaused ? "Resume Tracking" : "Pause Tracking",
                    action: togglePause
                )
                
                FloatingActionButton(
                    icon: "arrow.clockwise",
                    color: .blue,
                    tooltip: "Refresh Project",
                    action: refreshProject
                )
                
                FloatingActionButton(
                    icon: "trash.fill",
                    color: .red,
                    tooltip: "Remove Project",
                    action: { showingDeleteAlert = true }
                )
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        // AI Insights auto-load - COMMENTED OUT
        /*
        .onAppear {
            if settingsManager.settings.enableAIInsights && aiInsight == nil {
                loadAIInsight()
            }
        }
        */
        .sheet(isPresented: $showingGoalSheet) {
            GoalSheet(project: project)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first { window.makeKeyAndOrderFront(nil) }
                }
        }
        .alert("Remove Project", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                projectStore.deleteProject(project)
            }
        } message: {
            Text("Are you sure you want to remove \(project.name) from tracking? This won't delete any files.")
        }
    }
    
    private var momentumColor: Color {
        let score = project.momentumScore
        if score > 70 { return .green }
        if score > 40 { return .yellow }
        if score > 20 { return .orange }
        return .red
    }
    
    private var lastActivityText: String {
        guard let date = project.lastActivityDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func openInVSCode() {
        let url = URL(string: "vscode://file/\(project.path)")!
        NSWorkspace.shared.open(url)
    }
    
    private func openInFinder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path)
    }
    
    private func togglePause() {
        var updated = project
        updated.isPaused.toggle()
        projectStore.updateProject(updated)
    }
    
    private func refreshProject() {
        Task {
            await projectStore.refreshProject(project)
        }
    }
    
    private func loadAIInsight() {
        isLoadingAI = true
        Task {
            if let insight = await AIService.shared.generateInsight(for: project) {
                await MainActor.run {
                    aiInsight = insight
                    isLoadingAI = false
                }
            } else {
                await MainActor.run {
                    isLoadingAI = false
                }
            }
        }
    }
}

struct StatusBadge: View {
    let status: Project.ActivityStatus
    
    var body: some View {
        Label(status.rawValue, systemImage: iconName)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
    
    private var color: Color {
        switch status {
        case .active: return .green
        case .cooling: return .yellow
        case .inactive: return .orange
        case .dormant: return .red
        }
    }
    
    private var iconName: String {
        switch status {
        case .active: return "flame.fill"
        case .cooling: return "wind"
        case .inactive: return "moon.fill"
        case .dormant: return "zzz"
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: color.opacity(0.2), radius: isHovered ? 8 : 4, x: 0, y: 2)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.04), radius: isHovered ? 12 : 6, x: 0, y: 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.15), Color.purple.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.purple.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.05), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.purple.opacity(0.1), lineWidth: 1)
        )
    }
}

struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let tooltip: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        if isHovered {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                        }
                    }
                )
                .shadow(color: color.opacity(isHovered ? 0.5 : 0.3), radius: isHovered ? 12 : 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ActionIconButton: View {
    let icon: String
    let color: Color
    let label: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(isHovered ? 1.0 : 0.9)
            )
            .cornerRadius(12)
            .shadow(color: color.opacity(isHovered ? 0.4 : 0.25), radius: isHovered ? 12 : 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ProjectGoalRow: View {
    let goal: ProjectGoal
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(goal.isCompleted ? .green : .blue)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(goal.text)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .strikethrough(goal.isCompleted)
                    .foregroundColor(goal.isCompleted ? .secondary : .primary)
                
                if let deadline = goal.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(deadline, style: .date)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(isOverdue(deadline) && !goal.isCompleted ? .red : .secondary)
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(goal.isCompleted ? Color.green.opacity(0.05) : Color(NSColor.controlBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(goal.isCompleted ? Color.green.opacity(0.15) : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func isOverdue(_ deadline: Date) -> Bool {
        deadline < Date()
    }
}

