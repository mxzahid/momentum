import SwiftUI

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(
                        piece: piece,
                        isAnimating: isAnimating,
                        containerSize: geometry.size
                    )
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
                // Start animation after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isAnimating = true
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink,
            Color(hex: "38BDF8"), Color(hex: "F59E0B"), Color(hex: "EC4899")
        ]
        
        let shapes: [ConfettiShape] = [.circle, .square, .triangle, .diamond]
        
        // Generate 50 confetti pieces
        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                color: colors.randomElement() ?? .blue,
                shape: shapes.randomElement() ?? .circle,
                startX: CGFloat.random(in: 0...size.width),
                startY: -50,
                endY: size.height + 100,
                duration: Double.random(in: 2.0...3.5),
                delay: Double.random(in: 0...0.5),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 2...5),
                horizontalDrift: CGFloat.random(in: -100...100)
            )
        }
    }
}

// MARK: - Confetti Piece Model

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let shape: ConfettiShape
    let startX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let duration: Double
    let delay: Double
    let rotation: Double
    let rotationSpeed: Double
    let horizontalDrift: CGFloat
}

enum ConfettiShape {
    case circle, square, triangle, diamond
}

// MARK: - Confetti Piece View

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let isAnimating: Bool
    let containerSize: CGSize
    
    var body: some View {
        Group {
            switch piece.shape {
            case .circle:
                Circle()
                    .fill(piece.color)
            case .square:
                Rectangle()
                    .fill(piece.color)
            case .triangle:
                Triangle()
                    .fill(piece.color)
            case .diamond:
                Diamond()
                    .fill(piece.color)
            }
        }
        .frame(width: 10, height: 10)
        .rotationEffect(.degrees(isAnimating ? piece.rotation * piece.rotationSpeed : 0))
        .offset(
            x: isAnimating ? piece.horizontalDrift : 0,
            y: isAnimating ? piece.endY - piece.startY : 0
        )
        .position(x: piece.startX, y: piece.startY)
        .opacity(isAnimating ? 0 : 1)
        .animation(
            .easeIn(duration: piece.duration)
            .delay(piece.delay),
            value: isAnimating
        )
    }
}

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Confetti Container

struct ConfettiContainer: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if isPresented {
                        ConfettiView()
                            .edgesIgnoringSafeArea(.all)
                            .onAppear {
                                print("🎉 Confetti appeared!")
                                // Auto-dismiss after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                    print("🎉 Confetti dismissed")
                                    isPresented = false
                                }
                            }
                    }
                }
            )
    }
}

extension View {
    func confetti(isPresented: Binding<Bool>) -> some View {
        self.modifier(ConfettiContainer(isPresented: isPresented))
    }
}
