import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingGoalSheet = false
    @State private var showingDeleteAlert = false
    @State private var showConfetti = false
    @State private var aiInsight: AIService.AIInsight?
    @State private var isLoadingAI = false
    @State private var mouseLocation: CGPoint = .zero
    @State private var contentOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    var body: some View {
        ZStack {
            // Ambient gradient background
            AmbientGradientBackground(accentColor: accentColor)
                .ignoresSafeArea()
            
            ZStack(alignment: .topTrailing) {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // MARK: - Hero Section with Ring & Ambient Stats Panel (Top 50%)
                        MomentumHeroSection(
                            project: project,
                            accentColor: accentColor
                        )
                        .frame(height: geometry.size.height * 0.5)
                        .padding(.horizontal, 40)
                        .opacity(contentOpacity)
                        
                        // MARK: - Goals Section (Bottom 50%)
                        GlassGoalsSection(
                            project: project,
                            projectStore: projectStore,
                            showingGoalSheet: $showingGoalSheet
                        )
                        .frame(height: geometry.size.height * 0.5)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                        .opacity(contentOpacity)
                    }
                    .onAppear {
                        if !reduceMotion {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                contentOpacity = 1
                            }
                        } else {
                            contentOpacity = 1
                        }
                    }
                    .onChange(of: project.id) { _ in
                        if !reduceMotion {
                            contentOpacity = 0
                            withAnimation(.easeInOut(duration: 0.25)) {
                                contentOpacity = 1
                            }
                        }
                    }
                }
                
                // MARK: - Floating Action Buttons
                FloatingActionBar(
                    project: project,
                    togglePause: togglePause,
                    toggleComplete: toggleComplete,
                    refreshProject: refreshProject,
                    showDeleteAlert: { showingDeleteAlert = true }
                )
                .padding(.top, 16)
                .padding(.trailing, 20)
            }
        }
        .confetti(isPresented: $showConfetti)
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
    
    private func toggleComplete() {
        if project.isCompleted {
            projectStore.uncompleteProject(project)
        } else {
            projectStore.completeProject(project)
            // Show confetti when completing
            showConfetti = true
        }
    }
    
    private func refreshProject() {
        Task {
            await projectStore.refreshProject(project)
        }
    }
}

// MARK: - Momentum Hero Section (Ring + Ambient Stats)

struct MomentumHeroSection: View {
    let project: Project
    let accentColor: Color
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        GeometryReader { geometry in
            let isNarrow = geometry.size.width < 600
            
            if isNarrow {
                // Stack vertically on narrow windows
                VStack(spacing: 40) {
                    LiquidMomentumRing(
                        score: project.momentumScore,
                        accentColor: accentColor,
                        projectName: project.name,
                        projectPath: project.path,
                        status: project.activityStatus,
                        isPaused: project.isPaused,
                        isCompleted: project.isCompleted,
                        size: min(geometry.size.width * 0.6, geometry.size.height * 0.6)
                    )
                    
                    AmbientStatsPanel(
                        project: project,
                        accentColor: accentColor
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Side-by-side on wide layouts
                HStack(alignment: .center, spacing: 60) {
                    Spacer()
                    
                    LiquidMomentumRing(
                        score: project.momentumScore,
                        accentColor: accentColor,
                        projectName: project.name,
                        projectPath: project.path,
                        status: project.activityStatus,
                        isPaused: project.isPaused,
                        isCompleted: project.isCompleted,
                        size: min(geometry.size.width * 0.35, geometry.size.height * 0.75)
                    )
                    
                    AmbientStatsPanel(
                        project: project,
                        accentColor: accentColor
                    )
                    .frame(maxWidth: 250)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Ambient Stats Panel

struct AmbientStatsPanel: View {
    let project: Project
    let accentColor: Color
    @State private var isHovered = false
    @State private var statsVisible = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    
    var body: some View {
        let highContrast = colorSchemeContrast == .increased
        
        ZStack(alignment: .leading) {
            // Vertical divider line (48pt left margin)
            if !highContrast {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1)
                    .offset(x: -48)
                    .overlay(
                        // Accent glow near icons
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        accentColor.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 1)
                            .blur(radius: 4)
                    )
            }
            
            VStack(alignment: .leading, spacing: 18) {
                // Last Activity - Lime tint
                AmbientStatRow(
                    icon: "clock",
                    label: "Last Activity",
                    value: lastActivityText,
                    iconColor: DynamicAccentColor.limeTint,
                    isHovered: isHovered
                )
                .opacity(statsVisible ? 1 : 0)
                .offset(y: reduceMotion ? 0 : (statsVisible ? 0 : 5))
                
                // Commits - Mint blue tint
                AmbientStatRow(
                    icon: "brain.head.profile",
                    label: "Commits",
                    value: "\(project.commitCount)",
                    iconColor: DynamicAccentColor.mintBlueTint,
                    isHovered: isHovered
                )
                .opacity(statsVisible ? 1 : 0)
                .offset(y: reduceMotion ? 0 : (statsVisible ? 0 : 5))
                
                // Days Inactive - Amber tint
                AmbientStatRow(
                    icon: "zzz",
                    label: "Days Inactive",
                    value: project.daysSinceLastActivity == Int.max ? "∞" : "\(project.daysSinceLastActivity)",
                    iconColor: DynamicAccentColor.amberTint,
                    isHovered: isHovered
                )
                .opacity(statsVisible ? 1 : 0)
                .offset(y: reduceMotion ? 0 : (statsVisible ? 0 : 5))
            }
            .padding(.leading, 20)
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                        statsVisible = true
                    }
                } else {
                    statsVisible = true
                }
            }
        }
        .onHover { hovering in
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
    }
    
    private var lastActivityText: String {
        guard project.lastActivityDate != nil else { return "Never" }
        let days = project.daysSinceLastActivity
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days)d ago"
    }
}

// MARK: - Ambient Stat Row

struct AmbientStatRow: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color
    let isHovered: Bool
    @State private var valueChanged = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    
    var body: some View {
        let highContrast = colorSchemeContrast == .increased
        
        HStack(spacing: 20) {
            // Icon with circular mood-tinted glow
            ZStack {
                // Circular glow behind icon
                if !highContrast {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    iconColor.opacity(isHovered ? 0.18 : 0.12),
                                    iconColor.opacity(isHovered ? 0.08 : 0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 28
                            )
                        )
                        .frame(width: 56, height: 56)
                        .blur(radius: 12)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor.opacity(isHovered ? 1.0 : 0.85))
                    .frame(width: 28, height: 28)
            }
            
            // Label (13pt Medium, 60% white)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(1.3)
            
            Spacer()
            
            // Value (18pt Semibold, 100% white)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .opacity(valueChanged ? 0 : 1)
                .offset(y: valueChanged ? -5 : 0)
        }
        .offset(y: reduceMotion ? 0 : (isHovered ? -1 : 0))
        .onChange(of: value) { _ in
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.1)) {
                    valueChanged = true
                }
                withAnimation(.easeOut(duration: 0.15).delay(0.1)) {
                    valueChanged = false
                }
            }
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
    let isCompleted: Bool
    var size: CGFloat = 300
    
    @State private var animateRing = false
    @State private var particleOffset: CGFloat = 0
    @State private var glowPulse: Double = 1.0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var ringSize: CGFloat {
        size * 0.6
    }
    
    private var glowSize: CGFloat {
        size * 0.75
    }
    
    private var lineWidth: CGFloat {
        size * 0.06
    }
    
    // Inner content area should be smaller than ring inner diameter
    private var innerContentSize: CGFloat {
        ringSize - (lineWidth * 1.5) // More generous space for text
    }
    
    private var scoreSize: CGFloat {
        size * 0.18 // Slightly larger than 0.16 but smaller than original 0.2
    }
    
    private var titleSize: CGFloat {
        size * 0.12
    }
    
    private var pathSize: CGFloat {
        size * 0.04
    }
    
    var body: some View {
        VStack(spacing: size * 0.08) {
            // 3D Depth Gradient Ring with Soft Inner Glow
            ZStack {
                // Soft inner glow with subtle pulse (faint, not outer halo)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.04 * glowPulse),
                                accentColor.opacity(0.015 * glowPulse),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: glowSize * 0.3,
                            endRadius: glowSize * 0.5
                        )
                    )
                    .frame(width: glowSize, height: glowSize)
                    .blur(radius: size * 0.08)
                
                // Background track (softer)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.04),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
                    .frame(width: ringSize, height: ringSize)
                    .shadow(color: Color.black.opacity(0.4), radius: size * 0.03, x: 0, y: size * 0.015)
                
                // Liquid gauge ring with reduced brightness (20% less)
                Circle()
                    .trim(from: 0, to: animateRing ? CGFloat(score / 100) : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                accentColor.opacity(0.85),
                                accentColor.opacity(0.7),
                                accentColor.opacity(0.55),
                                accentColor.opacity(0.85)
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accentColor.opacity(0.08), radius: size * 0.015, x: 0, y: 0)
                    .overlay(
                        // Shimmer particle effect (more subtle)
                        Circle()
                            .trim(from: particleOffset, to: particleOffset + 0.015)
                            .stroke(Color.white.opacity(0.5), lineWidth: lineWidth * 0.2)
                            .frame(width: ringSize, height: ringSize)
                            .rotationEffect(.degrees(-90))
                            .blur(radius: 2)
                            .opacity(reduceMotion ? 0 : 0.4)
                    )
                
                // Center content with softer glow - constrained to inner area
                VStack(spacing: size * 0.02) {
                    ZStack {
                        // Softer blurred glow behind digits
                        Text("\(Int(score))%")
                            .font(.system(size: scoreSize, weight: .bold, design: .rounded))
                            .foregroundColor(accentColor)
                            .blur(radius: size * 0.06)
                            .opacity(0.3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: true, vertical: false)
                        
                        // Crisp digits with softer gradient
                        Text("\(Int(score))%")
                            .font(.system(size: scoreSize, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.95),
                                        accentColor.opacity(0.75)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: accentColor.opacity(0.2), radius: size * 0.02, x: 0, y: size * 0.01)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Text("Momentum")
                        .font(.system(size: size * 0.04, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2.5)
                }
                .frame(width: innerContentSize, height: innerContentSize)
            }
            .onAppear {
                withAnimation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.1)) {
                    animateRing = true
                }
                
                if !reduceMotion {
                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                        particleOffset = 1.0
                    }
                    
                    // Subtle glow pulse every 6 seconds (±5% brightness)
                    withAnimation(
                        .easeInOut(duration: 6)
                        .repeatForever(autoreverses: true)
                    ) {
                        glowPulse = 1.05
                    }
                }
            }
            
            // Project Info (softer typography)
            VStack(spacing: size * 0.025) {
                Text(projectName)
                    .font(.system(size: titleSize, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(projectPath)
                    .font(.system(size: pathSize, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .padding(.horizontal, size * 0.1)
            }
            
            // Status Capsule Pill
            GlassStatusPill(status: status, isPaused: isPaused, isCompleted: isCompleted, size: size)
        }
    }
}

// MARK: - Glass Status Pill

struct GlassStatusPill: View {
    let status: Project.ActivityStatus
    let isPaused: Bool
    let isCompleted: Bool
    var size: CGFloat = 300
    
    private var iconSize: CGFloat {
        size * 0.04
    }
    
    private var fontSize: CGFloat {
        size * 0.05
    }
    
    private var hPadding: CGFloat {
        size * 0.06
    }
    
    private var vPadding: CGFloat {
        size * 0.03
    }
    
    var body: some View {
        HStack(spacing: size * 0.04) {
            // Status pill with inner glow instead of outer
            HStack(spacing: size * 0.03) {
                Image(systemName: displayIcon)
                    .font(.system(size: iconSize, weight: .medium))
                Text(statusTitle)
                    .font(.system(size: fontSize, weight: .medium, design: .rounded))
            }
            .foregroundColor(statusColor)
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
            .background(
                ZStack {
                    // Active status and completed use gradient, others use glass
                    if status == .active || isCompleted {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isCompleted ? [
                                        Color.green.opacity(0.8),
                                        Color.green.opacity(0.6)
                                    ] : [
                                        DynamicAccentColor.mediumGreen,
                                        Color(hex: "1A6F43")
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        // Soft glass base for other statuses
                        Capsule()
                            .fill(Color.white.opacity(0.04))
                        
                        // Subtle gradient overlay
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        statusColor.opacity(0.15),
                                        statusColor.opacity(0.08)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Inner shadow for depth
                        Capsule()
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            .blur(radius: 2)
                            .offset(y: 1)
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(status == .active ? 0.4 : 0.25), lineWidth: 1)
            )
            
            // Paused pill (if paused)
            if isPaused {
                HStack(spacing: size * 0.02) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: iconSize))
                    Text("Paused")
                        .font(.system(size: fontSize, weight: .medium, design: .rounded))
                }
                .foregroundColor(.gray)
                .padding(.horizontal, hPadding * 0.9)
                .padding(.vertical, vPadding)
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
        if isCompleted {
            return .white
        }
        return DynamicAccentColor.forStatus(status)
    }
    
    private var displayIcon: String {
        if isCompleted {
            return "checkmark.circle.fill"
        }
        return status.icon
    }
    
    private var statusTitle: String {
        if isCompleted {
            return "Completed"
        }
        // Title Case instead of ALL CAPS
        return status.rawValue.prefix(1).uppercased() + status.rawValue.dropFirst()
    }
}

// MARK: - Modern Split-Pane Goals Section

struct GlassGoalsSection: View {
    let project: Project
    let projectStore: ProjectStore
    @Binding var showingGoalSheet: Bool
    @State private var isAddHovered = false
    @State private var pulseAnimation = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var activeGoalsCount: Int {
        project.goals.filter { !$0.isCompleted }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Horizontal gradient divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.bottom, 24)
            
            // Header row (🎯 Goals + Add Goal)
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DynamicAccentColor.primaryGreen)
                    
                    Text("Goals")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    if !project.goals.isEmpty {
                        Text("\(activeGoalsCount)/\(project.goals.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DynamicAccentColor.primaryGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(DynamicAccentColor.primaryGreen.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
                
                // Add Goal button
                Button(action: { showingGoalSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add Goal")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(DynamicAccentColor.primaryGreen.opacity(isAddHovered ? 1.0 : 0.8))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.2)) {
                        isAddHovered = hovering
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
            
            // Content area
            if project.goals.isEmpty {
                // Centered empty state with glowing ripple
                Button(action: { showingGoalSheet = true }) {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        ZStack {
                            // Glowing ripple animation
                            if !reduceMotion {
                                Circle()
                                    .stroke(DynamicAccentColor.primaryGreen.opacity(0.2), lineWidth: 2)
                                    .frame(width: 60, height: 60)
                                    .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                                    .opacity(pulseAnimation ? 0 : 0.6)
                            }
                            
                            Circle()
                                .fill(DynamicAccentColor.primaryGreen.opacity(0.08))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(DynamicAccentColor.primaryGreen.opacity(isAddHovered ? 1.0 : 0.8))
                        }
                        .scaleEffect(isAddHovered ? 1.05 : 1.0)
                        
                        Text("Add goals for this project")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.2)) {
                        isAddHovered = hovering
                    }
                }
                .onAppear {
                    if !reduceMotion {
                        withAnimation(
                            .easeOut(duration: 3)
                            .repeatForever(autoreverses: false)
                        ) {
                            pulseAnimation = true
                        }
                    }
                }
            } else {
                // Translucent list-style rows
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(project.goals) { goal in
                            ModernGoalRow(goal: goal, project: project, projectStore: projectStore)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Modern Goal Row (macOS Settings Style)

struct ModernGoalRow: View {
    let goal: ProjectGoal
    let project: Project
    let projectStore: ProjectStore
    @State private var isHovered = false
    @State private var isDeleteHovered = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // Delete button (x) on the left
            Button(action: {
                projectStore.deleteGoal(goal, in: project)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isDeleteHovered ? .white.opacity(0.9) : .white.opacity(0.5))
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(isDeleteHovered ? Color.red.opacity(0.8) : Color.white.opacity(0.05))
                    )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) {
                    isDeleteHovered = hovering
                }
            }

            // Accent dot indicator
            Circle()
                .fill(goal.isCompleted ? DynamicAccentColor.successAccent : DynamicAccentColor.primaryGreen)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(goal.isCompleted ? .white.opacity(0.4) : .white.opacity(0.85))
                    .strikethrough(goal.isCompleted)
                    .lineLimit(2)

                if let deadline = goal.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(deadline, style: .date)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(
                        isOverdue(deadline) && !goal.isCompleted
                            ? Color(hex: "F87171")
                            : .white.opacity(0.5)
                    )
                }
            }

            Spacer()

            // Completion toggle button
            Button(action: {
                projectStore.toggleGoal(goal, in: project)
            }) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(goal.isCompleted ? DynamicAccentColor.successAccent : DynamicAccentColor.primaryGreen.opacity(0.6))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(goal.isCompleted ? 0.015 : 0.02))
                .overlay(
                    // Hover highlight with green tint
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isHovered
                                ? DynamicAccentColor.primaryGreen.opacity(0.04)
                                : Color.clear
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
        )
        .scaleEffect(isHovered && !reduceMotion ? 1.002 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func isOverdue(_ deadline: Date) -> Bool {
        deadline < Date()
    }
}

// MARK: - Floating Action Bar

struct FloatingActionBar: View {
    let project: Project
    let togglePause: () -> Void
    let toggleComplete: () -> Void
    let refreshProject: () -> Void
    let showDeleteAlert: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            FloatingActionButton(
                icon: project.isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill",
                color: project.isCompleted ? .orange : .green,
                tooltip: project.isCompleted ? "Mark as Ongoing" : "Mark as Completed",
                action: toggleComplete
            )
            
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
