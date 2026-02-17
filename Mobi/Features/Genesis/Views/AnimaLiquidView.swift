//
//  AnimaLiquidView.swift
//  Mobi
//
//  Soul Distillation: Ink-in-milk liquid metaballs with ShaderLibrary (threshold + vortex).
//  State 1: Potential (pale drift). State 2: Color injection (drop from edge). State 3: Collapse (vortex).
//

import SwiftUI

private let kOffWhite = Color(red: 0.96, green: 0.96, blue: 0.97) // #F5F5F7
private let kPotentialColors: [Color] = [
    Color(white: 0.75),
    Color(white: 0.78),
    Color(red: 0.7, green: 0.75, blue: 0.85),
    Color(red: 0.72, green: 0.78, blue: 0.88),
]

struct AnimaLiquidView: View {
    @ObservedObject var viewModel: GenesisViewModel
    @State private var vortexStrength: Float = 0
    /// 液滴飞行进度 0→1（边缘到中心）
    @State private var injectedDropProgress: CGFloat = 0
    /// 到达中心后的扩散/融入进度 0→1（透明度降低、轻微放大，视觉上融入）
    @State private var injectedDropBlendProgress: CGFloat = 0
    @State private var lastInjectedColor: VisualCommand.FluidColor?
    @State private var showInjectedDrop: Bool = false
    /// 已融入的色调，持续参与 blob 混合，使颜色留在画面里
    @State private var blendedTint: VisualCommand.FluidColor?

    private let circleCount = 6
    private let baseRadius: CGFloat = 140
    /// Audio lip-sync: radius = baseRadius * (1.0 + power * 0.2)
    private var radiusScale: CGFloat {
        1.0 + CGFloat(viewModel.audioPower) * 0.2
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let strength = vortexStrength

            ZStack {
                Color(red: 0.96, green: 0.96, blue: 0.97)
                    .ignoresSafeArea()

                // State 1 + 2: Liquid blob (circles + blur + threshold shader)
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate * viewModel.fluidTurbulence * viewModel.audioReactiveTurbulence
                    ZStack {
                        blobCircles(size: size, center: center, t: t)
                        // 已融入的色调：大范围柔和高斯，让颜色持续留在画面里
                        if let tint = blendedTint {
                            Circle()
                                .fill(tint.swiftUIColor.opacity(0.18))
                                .frame(width: baseRadius * 3, height: baseRadius * 3)
                                .position(center)
                                .blur(radius: 80)
                        }
                        if showInjectedDrop, let color = lastInjectedColor {
                            injectedDropCircle(color: color, center: center, size: size)
                        }
                    }
                    .blur(radius: 30)
                    .blendMode(.multiply)
                    .layerEffect(ShaderLibrary.thresholdLayer(), maxSampleOffset: .zero)
                }
                .scaleEffect(radiusScale)
            }
            .visualEffect { content, proxy in
                return content
                    .distortionEffect(
                        ShaderLibrary.vortexDistortion(
                            .float(strength),
                            .float2(Float(proxy.size.width / 2), Float(proxy.size.height / 2))
                        ),
                        maxSampleOffset: .init(width: 500, height: 500)
                    )
            }
        }
        .ignoresSafeArea()
        .onChange(of: viewModel.fluidColor) { _, newColor in
            guard let newColor = newColor else { return }
            lastInjectedColor = newColor
            blendedTint = newColor
            injectedDropProgress = 0
            injectedDropBlendProgress = 0
            showInjectedDrop = true
            // 阶段一：液滴柔和飞入（缓动，约 1.4s）
            withAnimation(.easeInOut(duration: 1.4)) {
                injectedDropProgress = 1
            }
            // 阶段二：到达后扩散融入（透明度降低、轻微放大），约 2s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 2.0)) {
                    injectedDropBlendProgress = 1
                }
            }
            // 阶段三：液滴层隐藏，色调已通过 blendedTint 留在 blob 里
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                showInjectedDrop = false
            }
        }
        .onChange(of: viewModel.shouldTriggerTheSnap) { _, shouldCollapse in
            guard shouldCollapse else { return }
            withAnimation(.easeIn(duration: 3.0)) {
                vortexStrength = 10
            }
        }
    }

    // MARK: - Blob circles (State 1: pale drift)

    private func blobCircles(size: CGSize, center: CGPoint, t: TimeInterval) -> some View {
        ZStack {
            ForEach(0..<circleCount, id: \.self) { i in
                let (dx, dy) = driftOffset(index: i, size: size, t: t)
                let r = baseRadius * (0.9 + 0.2 * sin(t * 0.3 + Double(i)))
                Circle()
                    .fill(kPotentialColors[i % kPotentialColors.count].opacity(0.85))
                    .frame(width: r * 2, height: r * 2)
                    .position(x: center.x + dx, y: center.y + dy)
            }
        }
    }

    private func driftOffset(index: Int, size: CGSize, t: TimeInterval) -> (CGFloat, CGFloat) {
        let i = Double(index)
        let amp: CGFloat = min(size.width, size.height) * 0.2
        let dx = sin(t * 0.25 + i * 0.8) * amp + cos(t * 0.15 + i) * amp * 0.5
        let dy = cos(t * 0.22 + i * 0.6) * amp + sin(t * 0.18 + i * 1.2) * amp * 0.5
        return (dx, dy)
    }

    // MARK: - State 2: Injected color drop (edge -> center, then blend)

    private func injectedDropCircle(color: VisualCommand.FluidColor, center: CGPoint, size: CGSize) -> some View {
        let startX = size.width * 0.12
        let startY = size.height * 0.12
        let x = startX + (center.x - startX) * injectedDropProgress
        let y = startY + (center.y - startY) * injectedDropProgress
        // 飞行时由小变大；融入阶段再轻微放大，视觉上扩散
        let flyScale = 0.5 + 0.5 * injectedDropProgress
        let blendScale = 1.0 + 0.6 * injectedDropBlendProgress
        let r = baseRadius * 0.38 * flyScale * blendScale
        // 融入阶段透明度降低，与背景自然过渡
        let opacity = 0.88 - 0.6 * injectedDropBlendProgress
        return Circle()
            .fill(color.swiftUIColor.opacity(opacity))
            .frame(width: r * 2, height: r * 2)
            .position(x: x, y: y)
            .blur(radius: 8 + 12 * injectedDropBlendProgress)
    }
}
