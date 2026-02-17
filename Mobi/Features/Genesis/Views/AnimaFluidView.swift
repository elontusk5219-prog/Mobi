//
//  AnimaFluidView.swift
//  Mobi
//
//  Luminous Void: fluid mesh blurs (4–6 overlapping blurred gradients), pure SwiftUI.
//  Data-bound pulse and warmth; 8s collapse (Spin → Flash → Swap).
//

import SwiftUI

// MARK: - Gemini palette

private let kIndigo = Color(red: 0.29, green: 0.22, blue: 0.49)
private let kCoral = Color(red: 0.98, green: 0.45, blue: 0.42)
private let kMint = Color(red: 0.40, green: 0.85, blue: 0.75)
private let kCyan = Color(red: 0.35, green: 0.78, blue: 0.92)
private let kGeminiColors: [Color] = [kIndigo, kCoral, kMint, kCyan]

// MARK: - AnimaFluidView

struct AnimaFluidView: View {
    @ObservedObject var viewModel: GenesisViewModel
    @Binding var isCollapsing: Bool
    var onCollapseComplete: (() -> Void)?

    @State private var collapseStartTime: Date?
    @State private var showMobiPlaceholder: Bool = false
    @State private var hasCalledOnComplete: Bool = false

    private let circleCount = 6
    private let collapseDuration: TimeInterval = 8

    private var isStreaming: Bool { viewModel.isThinking || viewModel.isSpeaking }
    private var warmth: Double { min(1, max(0, viewModel.psycheModel.warmth)) }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            TimelineView(.animation) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let progress = collapseProgress(now: now)
                let spinProgress = min(1, progress * 2) // 0–0.5 -> 0–1 for 0–4s

                ZStack {
                    Color.hex("F5F5F7")
                        .ignoresSafeArea()

                    if progress < 0.75 {
                        fluidLayer(size: size, center: center, t: now, spinProgress: spinProgress, progress: progress)
                            .scaleEffect(isStreaming ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isStreaming)
                    }

                    if progress >= 0.75 {
                        MobiCharacterPlaceholderView()
                            .scaleEffect(showMobiPlaceholder ? 1.0 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showMobiPlaceholder)
                    }

                    Color.white
                        .opacity(whiteOverlayOpacity(progress))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                .onChange(of: progress) { _, p in
                    if p >= 0.75, !showMobiPlaceholder { showMobiPlaceholder = true }
                    if p >= 1, !hasCalledOnComplete {
                        hasCalledOnComplete = true
                        isCollapsing = false
                        onCollapseComplete?()
                    }
                }
            }
        }
        .onChange(of: isCollapsing) { _, new in
            if new { collapseStartTime = Date() }
        }
    }

    private func collapseProgress(now: TimeInterval) -> Double {
        guard isCollapsing, let start = collapseStartTime else { return 0 }
        let elapsed = now - start.timeIntervalSinceReferenceDate
        return min(1, elapsed / collapseDuration)
    }

    // MARK: - Fluid layer (4–6 circles, Timeline-driven offset/scale, blur, multiply)

    private func fluidLayer(size: CGSize, center: CGPoint, t: TimeInterval, spinProgress: Double, progress: Double) -> some View {
        ZStack {
            fluidCircle(index: 0, size: size, center: center, t: t)
            fluidCircle(index: 1, size: size, center: center, t: t)
            fluidCircle(index: 2, size: size, center: center, t: t)
            fluidCircle(index: 3, size: size, center: center, t: t)
            fluidCircle(index: 4, size: size, center: center, t: t)
            fluidCircle(index: 5, size: size, center: center, t: t)
        }
        .blur(radius: isCollapsing ? (100 - 90 * spinProgress) : 80)
        .scaleEffect(isCollapsing ? (1 - 0.9 * spinProgress) : 1)
        .rotationEffect(.degrees(isCollapsing ? 720 * spinProgress : 0))
        .blendMode(.multiply)
    }

    private func fluidCircle(index: Int, size: CGSize, center: CGPoint, t: TimeInterval) -> some View {
        let color = circleColor(index: index)
        let (offset, scale) = circleMotion(index: index, size: size, t: t)
        return Circle()
            .fill(color.opacity(0.9))
            .frame(width: circleSize(index: index, size: size), height: circleSize(index: index, size: size))
            .scaleEffect(scale)
            .offset(x: offset.width, y: offset.height)
            .position(center)
    }

    private func circleSize(index: Int, size: CGSize) -> CGFloat {
        let base = min(size.width, size.height) * 0.55
        let variation = CGFloat([0.9, 1.0, 1.1, 0.85, 1.05, 0.95][index % 6])
        return base * variation
    }

    private func circleMotion(index: Int, size: CGSize, t: TimeInterval) -> (CGSize, CGFloat) {
        let i = Double(index)
        let freq1 = 0.4 + i * 0.08
        let freq2 = 0.3 + i * 0.06
        let amp = min(size.width, size.height) * 0.22
        let dx = sin(t * freq1 + i * 0.7) * amp + cos(t * 0.2 + i) * amp * 0.5
        let dy = cos(t * freq2 + i * 0.5) * amp + sin(t * 0.25 + i * 1.2) * amp * 0.5
        let scale = 0.85 + 0.15 * sin(t * 0.5 + i * 0.4)
        return (CGSize(width: dx, height: dy), scale)
    }

    private func circleColor(index: Int) -> Color {
        let base = kGeminiColors[index % kGeminiColors.count]
        let warm = Color(red: 0.98, green: 0.5, blue: 0.3)
        return Color(
            red: (1 - warmth) * base.components.red + warmth * warm.components.red,
            green: (1 - warmth) * base.components.green + warmth * warm.components.green,
            blue: (1 - warmth) * base.components.blue + warmth * warm.components.blue
        )
    }

    private func whiteOverlayOpacity(_ progress: Double) -> Double {
        if progress < 0.5 { return 0 }
        if progress < 0.75 { return (progress - 0.5) / 0.25 }
        return 1 - (progress - 0.75) / 0.25
    }
}

// MARK: - Color components (for interpolation)

private extension Color {
    var components: (red: Double, green: Double, blue: Double) {
        #if canImport(UIKit)
        typealias PlatformColor = UIColor
        #else
        typealias PlatformColor = NSColor
        #endif
        let platform = PlatformColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        platform.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

// MARK: - Mobi placeholder (in-file; replace with 3D/Rive later)

private struct MobiCharacterPlaceholderView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 60)
                .fill(
                    LinearGradient(
                        colors: [Color.hex("F5F5F7"), Color(white: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 160)
                .shadow(color: Color.gray.opacity(0.3), radius: 16, x: 0, y: 8)
            Text("Mobi")
                .font(.title2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    AnimaFluidView(
        viewModel: GenesisViewModel(
            audioVisualizer: AudioVisualizerService(),
            ambientSoundService: AmbientSoundService(),
            engine: MobiEngine.shared
        ),
        isCollapsing: .constant(false)
    )
}
