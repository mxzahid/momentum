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
    var borderOpacity: Double = 0.1
    var shadowRadius: CGFloat = 30
    var shadowOpacity: Double = 0.25
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    
    func body(content: Content) -> some View {
        let highContrast = colorSchemeContrast == .increased
        
        content
            .background(
                ZStack {
                    // Ultra-dark glass background
                    if reduceTransparency || highContrast {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(white: 0.15))
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .opacity(0.6)
                    }
                    
                    // Subtle highlight edge (light bleed) - disabled in high contrast
                    if !highContrast {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
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
                        lineWidth: highContrast ? 2 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 3
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

// MARK: - Dynamic Accent Colors

struct DynamicAccentColor {
    static func forMomentum(_ score: Double) -> Color {
        if score > 70 { return .green }      // Active
        if score > 40 { return .blue }       // Cooling
        if score > 20 { return .orange }     // Inactive
        return .red                           // Dormant
    }
    
    static func forStatus(_ status: Project.ActivityStatus) -> Color {
        switch status {
        case .active: return .green
        case .cooling: return .blue
        case .inactive: return .orange
        case .dormant: return .red
        }
    }
}

// MARK: - Static Gradient Background

struct AmbientGradientBackground: View {
    let accentColor: Color
    
    var body: some View {
        ZStack {
            // Deep space gray with very subtle tint
            LinearGradient(
                colors: [
                    Color(hue: 0.0, saturation: 0.02, brightness: 0.10),
                    Color(hue: 0.0, saturation: 0.01, brightness: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Very subtle ambient accent glow (static)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.03),
                            accentColor.opacity(0.01),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 400
                    )
                )
                .blur(radius: 80)
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

