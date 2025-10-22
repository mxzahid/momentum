import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var projectStore: ProjectStore
    @State private var currentStep = 0
    @State private var selectedStyle: MotivationStyle = .friendly
    @State private var selectedFolders: [String] = []
    @State private var showingFolderPicker = false
    @State private var enableAI = false
    @State private var isDiscovering = false
    
    let steps = ["Welcome", "Motivation Style", "Select Projects", "Ready"]
    
    var body: some View {
        ZStack {
            // Cosmic background
            CosmicBackground()
            
            VStack(spacing: 0) {
                // Content - Using ZStack with transitions instead of TabView
                ZStack {
                    if currentStep == 0 {
                        WelcomeStep(onContinue: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                currentStep += 1
                            }
                        })
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else if currentStep == 1 {
                        MotivationStyleStep(selectedStyle: $selectedStyle)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else if currentStep == 2 {
                        ProjectSelectionStep(
                            selectedFolders: $selectedFolders,
                            showingFolderPicker: $showingFolderPicker
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    // } else if currentStep == 3 {
                    //     AIFeaturesStep(enableAI: $enableAI)
                    //         .transition(.asymmetric(
                    //             insertion: .move(edge: .trailing).combined(with: .opacity),
                    //             removal: .move(edge: .leading).combined(with: .opacity)
                    //         ))
                    } else if currentStep == 3 {
                        ReadyStep(isDiscovering: $isDiscovering)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Bottom navigation hidden on first step; centered CTA is inside WelcomeStep
                if currentStep > 0 {
                    HStack(spacing: 6) {
                        if currentStep > 0 {
                            ModernButton(text: "Back", style: .secondary) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    currentStep -= 1
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if currentStep < steps.count - 1 {
                            ModernButton(
                                text: "Continue",
                                style: .primary,
                                disabled: currentStep == 2 && selectedFolders.isEmpty
                            ) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    currentStep += 1
                                }
                            }
                        } else {
                            ModernButton(
                                text: isDiscovering ? "Discovering..." : "Get Started",
                                style: .primary,
                                disabled: isDiscovering
                            ) {
                                completeOnboarding()
                            }
                        }
                    }
                    .frame(maxWidth: 600)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
                    .padding(.top, 0)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 700, minHeight: 800)
    }
    
    private func completeOnboarding() {
        isDiscovering = true
        
        // Save settings
        settingsManager.updateMotivationStyle(selectedStyle)
        // settingsManager.toggleAIInsights(enableAI)
        
        for folder in selectedFolders {
            settingsManager.addWatchFolder(folder)
        }
        
        // Discover projects
        Task {
            await projectStore.discoverProjects(in: selectedFolders)
            
            await MainActor.run {
                settingsManager.completeOnboarding()
                isDiscovering = false
            }
        }
    }
}

// MARK: - Cosmic Components

struct CosmicBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base gradient - slightly desaturated for better UI contrast
            LinearGradient(
                colors: [
                    Color(red: 0.043, green: 0.043, blue: 0.071),  // #0B0B12
                    Color(red: 0.086, green: 0.066, blue: 0.12),    // Slightly desaturated
                    Color(red: 0.118, green: 0.106, blue: 0.173)    // #1E1B2C
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            // Cosmic overlay
            CosmicStarsView()
        }
    }
}

struct CosmicStarsView: View {
    @State private var stars: [Star] = []
    
    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
        let duration: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .opacity(star.opacity)
                        .position(x: star.x, y: star.y)
                        .modifier(TwinkleModifier(duration: star.duration))
                }
            }
            .onAppear {
                generateStars(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateStars(in size: CGSize) {
        stars = (0..<100).map { _ in
            Star(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 0.5...2),
                opacity: Double.random(in: 0.2...0.8),
                duration: Double.random(in: 1...3)
            )
        }
    }
}

struct TwinkleModifier: ViewModifier {
    let duration: Double
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct ModernButton: View {
    let text: String
    let style: ButtonStyleType
    var disabled: Bool = false
    let action: () -> Void
    @State private var isHovered = false
    
    enum ButtonStyleType {
        case primary, secondary
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Group {
                        if style == .primary {
                            // Cyan gradient accent button
                            LinearGradient(
                                colors: [
                                    Color(red: 0.231, green: 0.51, blue: 0.969),  // #3b82f6
                                    Color(red: 0.024, green: 0.714, blue: 0.831)  // #06b6d4
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            // Neutral glass background
                            Color.white.opacity(0.05)
                        }
                    }
                )
                .cornerRadius(12)
                .shadow(
                    color: style == .primary ? Color(red: 0.024, green: 0.714, blue: 0.831).opacity(0.4) : Color.black.opacity(0.3),
                    radius: isHovered ? 16 : 12,
                    x: 0,
                    y: 4
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            style == .primary ? 
                            LinearGradient(
                                colors: [
                                    Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.6), // #38bdf8
                                    Color(red: 0.024, green: 0.714, blue: 0.831).opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .scaleEffect(disabled ? 0.95 : (isHovered ? 1.02 : 1.0))
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Steps

struct WelcomeStep: View {
    let onContinue: () -> Void
    @State private var rocketOffset: CGFloat = 0
    @State private var rocketScale: CGFloat = 0.5
    @State private var glowOpacity: Double = 0.3
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero Rocket with Glow
            ZStack {
                // Soft radial glow behind rocket - cyan accent
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.22, green: 0.741, blue: 0.969).opacity(glowOpacity * 0.4),  // #38bdf8
                                Color(red: 0.231, green: 0.51, blue: 0.969).opacity(glowOpacity * 0.25), // #3b82f6
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                
                Image(systemName: "rocket.fill")
                    .font(.system(size: 100, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.22, green: 0.741, blue: 0.969)  // #38bdf8
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.4), radius: 20, x: 0, y: 10)
                    .scaleEffect(rocketScale)
                    .offset(y: rocketOffset)
                    .accessibilityHidden(true)
            }
            .frame(height: 180)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    rocketScale = 1.0
                }
                
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                        rocketOffset = -7
                        glowOpacity = 0.5
                    }
                }
            }
            .padding(.bottom, 32)
            
            // Title & Subtitle
            VStack(spacing: 10) {
                Text("Welcome to Momentum")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .accessibilityAddTraits(.isHeader)
                
                Text("Stop sending your projects into the abyss")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 520)
            }
            .padding(.bottom, 36)
            
            // Centered CTA for the first screen
            HStack {
                Spacer()
                ModernButton(text: "Let's Go!", style: .primary) {
                    onContinue()
                }
                Spacer()
            }
            .padding(.top, 12)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
    }
}

struct SimpleFeatureText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 16))
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity)
    }
}

struct CosmicFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))  // Neutral glass
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.741, blue: 0.969),  // #38bdf8
                                Color(red: 0.231, green: 0.51, blue: 0.969)   // #3b82f6
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

struct MotivationStyleStep: View {
    @Binding var selectedStyle: MotivationStyle
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("Choose Your Motivation Style")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("How should Momentum talk to you?")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 28)
            .padding(.bottom, 16)
            
            VStack(spacing: 16) {
                ForEach(MotivationStyle.allCases, id: \.self) { style in
                    CosmicMotivationCard(
                        style: style,
                        isSelected: selectedStyle == style
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedStyle = style
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(maxWidth: 740)
            .padding(.bottom, 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
    }
}

struct CosmicMotivationCard: View {
    let style: MotivationStyle
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(style.rawValue)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                    
                    Text(style.description)
                        .font(.system(size: 15))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.231, green: 0.51, blue: 0.969),   // #3b82f6
                                        Color(red: 0.024, green: 0.714, blue: 0.831)   // #06b6d4
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .shadow(color: Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.6), radius: 8)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(22)
            .background(
                ZStack {
                    // Neutral glass base
                    Color.white.opacity(isSelected ? 0.05 : 0.03)
                    
                    // Subtle inner border glow on selected
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.15),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .blur(radius: 2)
                    }
                }
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? 
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.8),  // #38bdf8
                                Color(red: 0.231, green: 0.51, blue: 0.969).opacity(0.5)   // #3b82f6
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : 
                        LinearGradient(
                            colors: [Color.white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.3) : Color.black.opacity(0.1),
                radius: isSelected ? 16 : 8,
                x: 0,
                y: isSelected ? 8 : 4
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (isHovered ? 1.01 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            if !isSelected {
                isHovered = hovering
            }
        }
    }
}

struct ProjectSelectionStep: View {
    @Binding var selectedFolders: [String]
    @Binding var showingFolderPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderSection
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(selectedFolders, id: \.self) { folder in
                        FolderRow(folder: folder, onRemove: {
                            withAnimation {
                                selectedFolders.removeAll { $0 == folder }
                            }
                        })
                    }
                    
                    AddFolderButton(action: { showingFolderPicker = true })
                    
                    if selectedFolders.isEmpty {
                        EmptyFoldersView()
                    }
                }
                .frame(maxWidth: 550)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                let path = url.path
                if !selectedFolders.contains(path) {
                    withAnimation {
                        selectedFolders.append(path)
                    }
                }
            }
        }
    }
    
    private var HeaderSection: some View {
        VStack(spacing: 12) {
            Text("Where Are Your Projects?")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Select folders where you keep your side projects")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 150)
        .padding(.bottom, 20)
    }
}

struct FolderRow: View {
    let folder: String
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            FolderIcon()
            
            Text(folder)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(isHovered ? 0.7 : 0.5))
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))  // Neutral glass
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct FolderIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))  // Neutral glass
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.3),  // Cyan outline
                            lineWidth: 1
                        )
                )
            
            Image(systemName: "folder.fill")
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.741, blue: 0.969),  // #38bdf8
                            Color(red: 0.231, green: 0.51, blue: 0.969)   // #3b82f6
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}

struct AddFolderButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.741, blue: 0.969),  // #38bdf8
                                Color(red: 0.231, green: 0.51, blue: 0.969)   // #3b82f6
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("Add Folder")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.white.opacity(0.05))  // Neutral glass
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.741, blue: 0.969).opacity(isHovered ? 0.5 : 0.3),
                                Color(red: 0.231, green: 0.51, blue: 0.969).opacity(isHovered ? 0.3 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct EmptyFoldersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.4),  // #38bdf8
                            Color(red: 0.231, green: 0.51, blue: 0.969).opacity(0.25)  // #3b82f6
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text("No folders selected yet")
                .foregroundColor(.white.opacity(0.6))
                .font(.body)
            
            Text("Common locations: ~/Projects, ~/Code, ~/Developer")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 32)
    }
}

struct AIFeaturesStep: View {
    @Binding var enableAI: Bool
    @State private var sparkleRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.25),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 70, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.741, blue: 0.969),
                                Color(red: 0.231, green: 0.51, blue: 0.969),
                                Color.white.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(sparkleRotation))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    sparkleRotation = 15
                }
            }
            
            VStack(spacing: 12) {
                Text("AI-Powered Insights")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Get personalized project recommendations")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 18) {
                CosmicFeatureRow(icon: "chart.bar.doc.horizontal", text: "Analyze your work patterns")
                CosmicFeatureRow(icon: "lightbulb", text: "Suggest next steps for projects")
                CosmicFeatureRow(icon: "quote.bubble", text: "Personalized motivation")
            }
            .padding(.vertical, 12)
            
            Toggle(isOn: $enableAI) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Enable AI Insights")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Requires Ollama running locally")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .toggleStyle(.switch)
            .tint(Color(red: 0.22, green: 0.741, blue: 0.969))  // Cyan accent
            .padding(20)
            .background(Color.white.opacity(0.05))  // Neutral glass
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            
            if enableAI {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.22, green: 0.741, blue: 0.969),
                                        Color(red: 0.231, green: 0.51, blue: 0.969)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Text("Make sure Ollama is installed")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text("Install from: ollama.ai")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.leading, 26)
                }
                .padding(16)
                .background(Color.white.opacity(0.05))  // Neutral glass
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.3),
                            lineWidth: 1
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
        }
        .frame(maxWidth: 550)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: enableAI)
    }
}

struct ReadyStep: View {
    @Binding var isDiscovering: Bool
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            if isDiscovering {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.3),  // Cyan glow
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                        .scaleEffect(pulseScale)
                    
                    ProgressView()
                        .scaleEffect(2)
                        .tint(Color(red: 0.22, green: 0.741, blue: 0.969))
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseScale = 1.3
                    }
                }
                
                Text("Discovering your projects...")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 32)
            } else {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.8, blue: 0.5).opacity(glowOpacity),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 90, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.9, blue: 0.6),
                                    Color(red: 0.3, green: 0.8, blue: 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.6), radius: 20)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowOpacity = 0.6
                    }
                }
                
                VStack(spacing: 16) {
                    Text("You're All Set!")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Momentum will start tracking your projects automatically")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                }
                .padding(.top, 24)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
    }
}

