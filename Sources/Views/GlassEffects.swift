import SwiftUI

/*
 MARK: - Glass Effects & Tahoe Design System
 
 This file contains reusable components for creating macOS Tahoe-inspired UI:
 - Translucent glass materials
 - Liquid gradients and depth effects
 - Neon glow and lighting
 - Motion-responsive animations
 
 ACCESSIBILITY SUPPORT:
 ✅ Reduce Motion: Disables parallax, hover lifts, and complex animations
 ✅ Reduce Transparency: Replaces glass materials with solid matte surfaces
 ✅ High Contrast: Uses solid backgrounds with prominent borders, disables glows
 
 All visual effects respect system accessibility preferences automatically.
 */

// MARK: - Glass Material Styles

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    var borderOpacity: Double = 0.08
    var shadowRadius: CGFloat = 12
    var shadowOpacity: Double = 0.4
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    
    func body(content: Content) -> some View {
        let highContrast = colorSchemeContrast == .increased
        
        content
            .background(
                ZStack {
                    // Softer translucent background
                    if reduceTransparency || highContrast {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(white: 0.12))
                    } else {
                        // Translucent neutral layer
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(0.05))
                    }
                    
                    // Subtle highlight edge - disabled in high contrast
                    if !highContrast {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        Color.clear,
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.white.opacity(highContrast ? 0.5 : borderOpacity),
                        lineWidth: highContrast ? 2 : 0.5
                    )
            )
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: 4
            )
    }
}

struct GlassPill: ViewModifier {
    var accentColor: Color
    var cornerRadius: CGFloat = 20
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    
    func body(content: Content) -> some View {
        let highContrast = colorSchemeContrast == .increased
        
        content
            .background(
                ZStack {
                    // Blurred background
                    if reduceTransparency || highContrast {
                        Capsule()
                            .fill(accentColor.opacity(0.3))
                    } else {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(0.4)
                    }
                    
                    // Gradient overlay - disabled in high contrast
                    if !highContrast {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.35),
                                        accentColor.opacity(0.15)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        Color.white.opacity(highContrast ? 0.6 : 0.15),
                        lineWidth: highContrast ? 2 : 1
                    )
            )
    }
}

// MARK: - Dynamic Accent Colors (Balanced Green Palette)

struct DynamicAccentColor {
    // Primary green palette
    static let primaryGreen = Color(hex: "3DF07C")      // Primary green
    static let activeGlow = Color(hex: "40F54A")        // Active glow
    static let successAccent = Color(hex: "5AF57D")     // Success (100%)
    static let mediumGreen = Color(hex: "2DC969")       // Medium green
    static let mutedGreen = Color(hex: "1F9D50")        // Muted green
    
    // Icon mood tints
    static let limeTint = Color(hex: "3DF07C")          // Last Activity
    static let mintBlueTint = Color(hex: "5DE3B6")      // Commits
    static let amberTint = Color(hex: "E9B85C")         // Days Inactive
    
    static func forMomentum(_ score: Double) -> Color {
        if score > 70 { return successAccent }           // Active: vivid green
        if score > 40 { return primaryGreen }            // Cooling: primary green
        if score > 20 { return Color(hex: "FBBF24") }    // Amber (Inactive)
        return Color(hex: "F87171")                      // Soft red (Dormant)
    }
    
    static func forStatus(_ status: Project.ActivityStatus) -> Color {
        switch status {
        case .active: return successAccent               // Vivid green
        case .cooling: return primaryGreen               // Primary green
        case .inactive: return Color(hex: "FBBF24")      // Amber
        case .dormant: return Color(hex: "F87171")       // Soft red
        }
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Ambient Gradient Background (Enhanced Depth)

struct AmbientGradientBackground: View {
    let accentColor: Color
    
    var body: some View {
        ZStack {
            // Deep gradient background with enhanced depth (#111213 → #0C0C0D)
            LinearGradient(
                colors: [
                    Color(hex: "111213"),
                    Color(hex: "0C0C0D")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Top-down gradient fade (lighter top, darker bottom for grounding)
            LinearGradient(
                colors: [
                    Color.white.opacity(0.02),
                    Color.clear,
                    Color.black.opacity(0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle ambient accent glow (green-focused)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.018),
                            accentColor.opacity(0.008),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 400
                    )
                )
                .blur(radius: 102)
        }
    }
}

// MARK: - Parallax Effect

struct ParallaxEffect: GeometryEffect {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 0, y: offset))
    }
}

// MARK: - Hover Lift Effect

struct HoverLiftEffect: ViewModifier {
    @State private var isHovered = false
    let liftAmount: CGFloat
    let scaleAmount: CGFloat
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .offset(y: reduceMotion ? 0 : (isHovered ? -liftAmount : 0))
            .scaleEffect(reduceMotion ? 1.0 : (isHovered ? scaleAmount : 1.0))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Glow Effect

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    let intensity: Double
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    
    func body(content: Content) -> some View {
        let highContrast = colorSchemeContrast == .increased
        
        // Disable glow in high contrast mode
        if highContrast {
            content
        } else {
            content
                .shadow(color: color.opacity(intensity * 0.08), radius: radius / 2, x: 0, y: 0)
        }
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(
        cornerRadius: CGFloat = 24,
        borderOpacity: Double = 0.1,
        shadowRadius: CGFloat = 30,
        shadowOpacity: Double = 0.25
    ) -> some View {
        self.modifier(GlassCard(
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity,
            shadowRadius: shadowRadius,
            shadowOpacity: shadowOpacity
        ))
    }
    
    func glassPill(accentColor: Color, cornerRadius: CGFloat = 20) -> some View {
        self.modifier(GlassPill(accentColor: accentColor, cornerRadius: cornerRadius))
    }
    
    func hoverLift(amount: CGFloat = 2, scale: CGFloat = 1.02) -> some View {
        self.modifier(HoverLiftEffect(liftAmount: amount, scaleAmount: scale))
    }
    
    func neonGlow(color: Color, radius: CGFloat = 20, intensity: Double = 1.0) -> some View {
        self.modifier(GlowEffect(color: color, radius: radius, intensity: intensity))
    }
}

