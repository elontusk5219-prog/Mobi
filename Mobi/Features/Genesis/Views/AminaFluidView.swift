//
//  AminaFluidView.swift
//  Mobi
//
//  Planetary atmosphere + broken corona: Earth-like flowing layers,
//  irregular multi-colored halo, volumetric specular highlights (3D celestial body).
//

import SwiftUI

struct AminaFluidView: View {
    var elapsed: Double? = nil
    var transitionMode: Bool = false
    var externalTime: Double = 0
    var state: AnimaState = .idle
    var dominantColor: Color = .cyan
    /// Vibe tremor 0...1 from METADATA vibe_keywords; drives subtle Shader jitter.
    var vibeTremorIntensity: CGFloat = 0
    /// Audio power 0...1 for breathing when speaking; drives distortion amplitude.
    var audioPower: Float = 0
    /// TTS 输出电平 0...1，Core Flutter 随语音变化
    var ttsOutputLevel: Float = 0
    /// 膝跳反射：物理下沉 offset（沉/累）
    var reflexOffsetY: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let effectiveElapsed = elapsed ?? (transitionMode ? externalTime : t)
                let breathingComponent: CGFloat = state == .speaking
                    ? CGFloat(audioPower) * 0.5
                    : (1 + sin(t * 2)) * 0.04
                let effectiveIntensity = vibeTremorIntensity + breathingComponent
                let sizeW = Float(geo.size.width)
                let sizeH = Float(geo.size.height)
                let centerX = sizeW * 0.5
                let centerY = sizeH * 0.5
                ZStack {
                    // 背景：完全静态，不参与任何 distortion
                    RadialGradient(
                        gradient: Gradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.12), .black]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 500
                    )
                    .ignoresSafeArea()

                    // Orb 层：光晕 + 球体（球体边界 organicBlob 运动 + 不规则模糊）
                    orbLayerContent(
                        elapsed: effectiveElapsed,
                        sphereBlobIntensity: 0.5 + CGFloat(ttsOutputLevel) * 0.35,
                        blobTime: t,
                        centerX: centerX, centerY: centerY, sizeW: sizeW, sizeH: sizeH
                    )
                        .layerEffect(
                            ShaderLibrary.etherealOrbOrganic(
                                .float(t),
                                .float2(centerX, centerY),
                                .float2(sizeW, sizeH),
                                .float(ttsOutputLevel)
                            ),
                            maxSampleOffset: .init(width: 64, height: 64)
                        )
                        .visualEffect { content, _ in
                            content.distortionEffect(
                                ShaderLibrary.vibeTremorDistortion(
                                    .float(t),
                                    .float(Float(effectiveIntensity))
                                ),
                                maxSampleOffset: .init(width: 6, height: 6)
                            )
                        }
                }
                .layerEffect(ShaderLibrary.noiseGrain(.float(Float(t))), maxSampleOffset: .init(width: 2, height: 2))
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func orbLayerContent(
        elapsed: Double,
        sphereBlobIntensity: CGFloat = 0.4,
        blobTime: Double = 0,
        centerX: Float = 0, centerY: Float = 0, sizeW: Float = 400, sizeH: Float = 400
    ) -> some View {
        ZStack {
                // ==========================================
                // LAYER 1: THE BROKEN CORONA (The Sun's Halo)
                // 章鱼节律：慢速、各层独立运动、TTS 电平驱动起伏幅度
                // ==========================================
                let haloLevel = CGFloat(ttsOutputLevel)
                let undulationAmp: CGFloat = 18 + haloLevel * 25  // 静时轻柔，说话时起伏更大
                let slowBase: Double = 0.4
                ZStack {
                    Ellipse()
                        .fill(dominantColor.opacity(0.5))
                        .frame(width: 340, height: 200)
                        .rotationEffect(.degrees(elapsed * 2.5))
                        .offset(
                            x: sin(elapsed * slowBase) * undulationAmp + cos(elapsed * 0.3) * 8,
                            y: cos(elapsed * slowBase * 1.1) * undulationAmp * 0.8 + sin(elapsed * 0.25) * 6
                        )

                    Ellipse()
                        .fill(Color.hex("FF1493").opacity(0.4))
                        .frame(width: 220, height: 350)
                        .rotationEffect(.degrees(-elapsed * 3 + 45))
                        .offset(
                            x: cos(elapsed * slowBase * 0.9) * undulationAmp * 1.1 + sin(elapsed * 0.35) * 10,
                            y: sin(elapsed * slowBase * 1.2) * undulationAmp * 0.7 - cos(elapsed * 0.28) * 8
                        )

                    Ellipse()
                        .fill(Color.hex("FFD700").opacity(0.3))
                        .frame(width: 300, height: 250)
                        .rotationEffect(.degrees(elapsed * 1.8 + 90))
                        .offset(
                            x: sin(elapsed * slowBase * 0.8) * undulationAmp * 0.9 - cos(elapsed * 0.22) * 12,
                            y: cos(elapsed * slowBase * 1.05) * undulationAmp + sin(elapsed * 0.31) * 7
                        )
                }
                .drawingGroup()
                .blur(radius: 10)
                .opacity(state == .listening ? 0.85 : 0.5)
                .scaleEffect(state == .listening ? 1.12 : 1.0)

                // ==========================================
                // LAYER 2–4: 球体 + 高光 + Core（球体-光晕边界做 organicBlob 泡泡式不规则）
                // ==========================================
                sphereLayerContent(elapsed: elapsed)
                    .visualEffect { content, _ in
                        content.distortionEffect(
                            ShaderLibrary.organicBlobRadial(
                                .float(blobTime),
                                .float(Float(sphereBlobIntensity)),
                                .float2(centerX, centerY),
                                .float(ttsOutputLevel)
                            ),
                            maxSampleOffset: .init(width: 32, height: 32)
                        )
                    }
                    .layerEffect(
                        ShaderLibrary.sphereVariableEdgeSoft(
                            .float(blobTime),
                            .float2(centerX, centerY),
                            .float2(sizeW, sizeH)
                        ),
                        maxSampleOffset: .init(width: 36, height: 36)
                    )
        }
        .offset(y: reflexOffsetY)
            .animation(.easeInOut(duration: 0.7), value: state)
            .animation(.easeInOut(duration: 0.9), value: dominantColor)
            .animation(.easeInOut(duration: 0.6), value: reflexOffsetY)
            .animation(.easeOut(duration: 0.08), value: ttsOutputLevel)
            .ignoresSafeArea()
    }

    /// 球体 + 高光 + Core（L2–L4），仅此部分参与 organicBlob 边界变形
    @ViewBuilder
    private func sphereLayerContent(elapsed: Double) -> some View {
        ZStack {
            // LAYER 2: THE PLANETARY BODY (Earth's Atmosphere)
            ZStack {
                Circle().fill(Color.black.opacity(0.3)).frame(width: 260, height: 260)
                Circle()
                    .fill(dominantColor.opacity(0.8))
                    .frame(width: 200, height: 200)
                    .offset(x: sin(elapsed * 0.9) * 40, y: cos(elapsed * 0.8) * 40)
                Circle()
                    .fill(Color.hex("FF1493").opacity(0.7))
                    .frame(width: 180, height: 180)
                    .offset(x: cos(elapsed * 1.2) * -50, y: sin(elapsed * 1.1) * 30)
                Circle()
                    .fill(Color.hex("FFD700").opacity(0.6))
                    .frame(width: 160, height: 160)
                    .offset(x: sin(elapsed * 1.5) * 30, y: cos(elapsed * 1.3) * -40)
            }
            .drawingGroup()
            .blur(radius: 8)
            .mask(Circle().frame(width: 260, height: 260))

            // LAYER 3: VOLUMETRIC HIGHLIGHTS & 3D FRESNEL
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.7), .clear]),
                        center: .topLeading,
                        startRadius: 10,
                        endRadius: 180
                    )
                )
                .frame(width: 260, height: 260)
                .blendMode(.plusLighter)

            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, dominantColor.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 6
                )
                .frame(width: 260, height: 260)
                .blur(radius: 4)

            // LAYER 4: VOICE REACTIVITY (The Core Flutter)
            let coreSize: CGFloat = state == .speaking ? (60 + CGFloat(ttsOutputLevel) * 50) : 60
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            dominantColor.opacity(0.9),
                            dominantColor.opacity(0.5 + CGFloat(ttsOutputLevel) * 0.3),
                            Color.white.opacity(0.3 + CGFloat(ttsOutputLevel) * 0.5)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: coreSize * 0.6
                    )
                )
                .frame(width: coreSize, height: coreSize)
                .blur(radius: min(12, 6 + CGFloat(ttsOutputLevel) * 6))
                .opacity(state == .speaking ? (0.5 + CGFloat(ttsOutputLevel) * 0.45) : 0.0)
                .blendMode(.plusLighter)
        }
    }
}

