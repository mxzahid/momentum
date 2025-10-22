import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingGoalSheet = false
    @State private var showingDeleteAlert = false
    @State private var aiInsight: AIService.AIInsight?
    @State private var isLoadingAI = false
    @State private var mouseLocation: CGPoint = .zero
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    var body: some View {
        ZStack {
            // Ambient gradient background
            AmbientGradientBackground(accentColor: accentColor)
                .ignoresSafeArea()
            
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Hero Section with Momentum Ring
                        LiquidMomentumRing(
                            score: project.momentumScore,
                            accentColor: accentColor,
                            projectName: project.name,
                            projectPath: project.path,
                            status: project.activityStatus,
                            isPaused: project.isPaused
                        )
                        .padding(.top, 60)
                        .padding(.horizontal)
                        
                        // MARK: - Stats Row (Floating Glass Tiles)
                        FloatingStatsRow(project: project, accentColor: accentColor)
                            .padding(.horizontal)
                        
                        // MARK: - Goals Section (Glass Panel)
                        GlassGoalsSection(
                            project: project,
                            showingGoalSheet: $showingGoalSheet
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
                
                // MARK: - Floating Action Buttons
                FloatingActionBar(
                    project: project,
                    togglePause: togglePause,
                    refreshProject: refreshProject,
                    showDeleteAlert: { showingDeleteAlert = true }
                )
                .padding(.top, 16)
                .padding(.trailing, 20)
            }
        }
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
    
    // MARK: - Computed Properties
    
    private var accentColor: Color {
        DynamicAccentColor.forMomentum(project.momentumScore)
    }
    
    private var lastActivityText: String {
        guard let date = project.lastActivityDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Actions
    
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
}

// MARK: - Liquid Momentum Ring

struct LiquidMomentumRing: View {
    let score: Double
    let accentColor: Color
    let projectName: String
    let projectPath: String
    let status: Project.ActivityStatus
    let isPaused: Bool
    
    @State private var animateRing = false
    @State private var particleOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: 20) {
            // 3D Depth Gradient Ring with Neon Halo
            ZStack {
                // Outer subtle halo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.08),
                                accentColor.opacity(0.03),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 70,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: 30)
                
                // Background track
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 18
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Inner shadow for depth
                Circle()
                    .stroke(
                        Color.black.opacity(0.2),
                        lineWidth: 2
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 4)
                
                // Liquid gauge ring with 3D depth
                Circle()
                    .trim(from: 0, to: animateRing ? CGFloat(score / 100) : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                accentColor,
                                accentColor.opacity(0.8),
                                accentColor.opacity(0.6),
                                accentColor
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accentColor.opacity(0.15), radius: 6, x: 0, y: 0)
                    .shadow(color: accentColor.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        // Shimmer particle effect (subtle)
                        Circle()
                            .trim(from: particleOffset, to: particleOffset + 0.02)
                            .stroke(Color.white.opacity(0.8), lineWidth: 4)
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                            .blur(radius: 2)
                            .opacity(reduceMotion ? 0 : 0.6)
                    )
                
                // Center content with blurred glow
                VStack(spacing: 6) {
                    ZStack {
                        // Blurred glow behind digits
                        Text("\(Int(score))%")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundColor(accentColor)
                            .blur(radius: 20)
                            .opacity(0.5)
                        
                        // Crisp digits with gradient
                        Text("\(Int(score))%")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        accentColor,
                                        accentColor.opacity(0.8)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Text("MOMENTUM")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2.5)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                    animateRing = true
                }
                
                if !reduceMotion {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        particleOffset = 1.0
                    }
                }
            }
            
            // Project Info
            VStack(spacing: 8) {
                Text(projectName)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(projectPath)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .padding(.horizontal, 30)
            }
            
            // Status Capsule Pill
            GlassStatusPill(status: status, isPaused: isPaused)
        }
    }
}

// MARK: - Glass Status Pill

struct GlassStatusPill: View {
    let status: Project.ActivityStatus
    let isPaused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Status pill
            HStack(spacing: 8) {
                Image(systemName: status.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(status.rawValue)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(statusColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.6)
                    
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                }
            )
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
            
            // Paused pill (if paused)
            if isPaused {
                HStack(spacing: 6) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 11))
                    Text("Paused")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(.gray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.4)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }
    
    private var statusColor: Color {
        DynamicAccentColor.forStatus(status)
    }
}

// MARK: - Floating Stats Row

struct FloatingStatsRow: View {
    let project: Project
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            FloatingStatCard(
                icon: "calendar.circle.fill",
                title: "Last Activity",
                value: lastActivityText,
                color: .blue
            )
            
            FloatingStatCard(
                icon: "arrow.triangle.branch",
                title: "Total Commits",
                value: "\(project.commitCount)",
                color: Color(red: 0.22, green: 0.741, blue: 0.969)
            )
            
            FloatingStatCard(
                icon: "clock.fill",
                title: "Days Inactive",
                value: project.daysSinceLastActivity == Int.max ? "∞" : "\(project.daysSinceLastActivity)",
                color: project.daysSinceLastActivity > 7 ? .orange : accentColor
            )
        }
    }
    
    private var lastActivityText: String {
        guard project.lastActivityDate != nil else { return "Never" }
        let days = project.daysSinceLastActivity
        if days == 0 { return "Today" }
        if days == 1 { return "1d ago" }
        return "\(days)d"
    }
}

struct FloatingStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    @State private var isHovered = false
    @State private var parallaxOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: 14) {
            // Icon with soft spotlight background
            ZStack {
                // Spotlight glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.2),
                                color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(isHovered && !reduceMotion ? 1.15 : 1.0)
            
            // Value
            Text(value)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            // Label
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding(.horizontal, 16)
        .glassCard(cornerRadius: 28, borderOpacity: 0.12, shadowRadius: 25, shadowOpacity: isHovered ? 0.4 : 0.25)
        .offset(y: reduceMotion ? 0 : parallaxOffset)
        .hoverLift(amount: 4, scale: 1.03)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                parallaxOffset = hovering ? -2 : 0
            }
        }
    }
}

// MARK: - Glass Goals Section

struct GlassGoalsSection: View {
    let project: Project
    @Binding var showingGoalSheet: Bool
    @State private var isExpanded = true
    
    var activeGoalsCount: Int {
        project.goals.filter { !$0.isCompleted }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text("Goals")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if !project.goals.isEmpty {
                        Text("\(activeGoalsCount)/\(project.goals.count)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.5)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    // Expand/collapse chevron
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    
                    // Manage button
                    Button(action: { showingGoalSheet = true }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                if project.goals.isEmpty {
                    // Empty state
                    Button(action: { showingGoalSheet = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            
                            Text("Add goals for this project")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .opacity(0.3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    Color.blue.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                )
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    // Goals list
                    VStack(spacing: 10) {
                        ForEach(project.goals.prefix(3)) { goal in
                            TranslucentGoalPill(goal: goal)
                        }
                        
                        if project.goals.count > 3 {
                            Button(action: { showingGoalSheet = true }) {
                                Text("View all \(project.goals.count) goals")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.blue)
                                    .padding(.top, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(24)
        .glassCard(cornerRadius: 24, borderOpacity: 0.08)
    }
}

struct TranslucentGoalPill: View {
    let goal: ProjectGoal
    
    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(goal.isCompleted ? .green : .blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(goal.isCompleted ? .white.opacity(0.5) : .white.opacity(0.9))
                    .strikethrough(goal.isCompleted)
                    .lineLimit(2)
                
                if let deadline = goal.deadline {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(deadline, style: .date)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(
                        isOverdue(deadline) && !goal.isCompleted
                            ? Color(red: 1.0, green: 0.4, blue: 0.4)
                            : Color(red: 0.6, green: 0.7, blue: 0.85)
                    )
                }
            }
            
            Spacer()
            
            // Progress dot/streak
            if !goal.isCompleted {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .opacity(goal.isCompleted ? 0.2 : 0.4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private func isOverdue(_ deadline: Date) -> Bool {
        deadline < Date()
    }
}

// MARK: - Floating Action Bar

struct FloatingActionBar: View {
    let project: Project
    let togglePause: () -> Void
    let refreshProject: () -> Void
    let showDeleteAlert: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
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
                action: showDeleteAlert
            )
        }
    }
}

struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    ZStack {
                        // Glass base
                        Circle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.6)
                        
                        // Color gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.7),
                                        color.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Highlight on hover
                        if isHovered {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        }
                    }
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.9 : (isHovered && !reduceMotion ? 1.1 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
