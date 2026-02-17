//
//  ProceduralMobiView.swift
//  Mobi
//
//  Cute squishy blob with breathe, drag, poke, lip-sync, tracking eyes, and DNA material rendering.
//

import SwiftUI

struct ProceduralMobiView: View {
    let primaryColor: Color
    /// DNA from Genesis (nil = use default and primaryColor as fallback).
    var dna: MobiVisualDNA? = nil
    /// Live drag translation for future softness/squash-stretch.
    var dragStretch: CGSize = .zero
    var isSpeaking: Bool = false
    var isListening: Bool = false
    var lookDirection: CGSize = .zero
    /// D3 平行陪伴：idle 时做自己的事；.playing 时轻微摇摆。
    var idleActivity: IdleActivity? = nil
    /// Personality slot progress 0.0–1.0 (from EvolutionManager). Nil = hide.
    var personalitySlotProgress: Double? = nil
    /// MobiBrain: 呼吸幅度倍数（arousal 高→>1，低→<1）
    var breathScaleMultiplier: Double = 1.0
    /// MobiBrain: 呼吸频率倍数（arousal 高→1.3，低→0.7）
    var breathFrequencyMultiplier: Double = 1.0
    /// MobiBrain: 是否处于 startled，短暂 squash 0.85
    var isStartled: Bool = false
    /// 画像置信度衰减；为 true 时表现轻微「不确定感」视觉
    var confidenceDecay: Bool = false
    /// Soul Vessel 填充 0–1；nil 时用 personalitySlotProgress
    var vesselFillProgress: Double? = nil
    /// 经验获得时液面激荡 + 光点飞入
    var vesselAgitated: Bool = false
    /// 满溢后仅展示胸口印记（只进不退）
    var vesselHasOverflowed: Bool = false
    /// 满溢动画阶段（裂纹→炸裂→融入）；nil = 正常瓶身
    var vesselOverflowPhase: VesselOverflowPhase? = nil
    /// 生命阶段：newborn 无四肢/尾巴/嘴；child Chiikawa 风；adult 更成熟。
    var lifeStage: LifeStage = .newborn
    /// 精力耗尽时瘫软表现（缩小、略下沉）
    var energyDepleted: Bool = false
    var onPoke: (() -> Void)?
    var onLongPress: (() -> Void)?
    var onVesselTap: (() -> Void)?
    var onVesselLongPress: (() -> Void)?

    @State private var isBlinking = false
    @State private var pokeScale: CGFloat = 1.0
    @State private var isBeingPetted = false

    private var effectiveDNA: MobiVisualDNA { dna ?? .default }
    private var eyeSocketSpacing: CGFloat {
        0.12 + effectiveDNA.eyeSpacing * 0.18
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.033)) { context in
            mobiContent(proxy: context)
        }
    }

    @ViewBuilder
    private func mobiContent(proxy: TimelineViewDefaultContext) -> some View {
        let t = proxy.date.timeIntervalSinceReferenceDate
        let decayJitter = confidenceDecay ? 0.04 * sin(t * 0.4) : 0
        let idleSway = (idleActivity == .playing) ? 0.015 * sin(t * 0.8) : 0
        // 三阶段动画节奏：child 更活泼（呼吸略快），adult 更沉稳（略慢），newborn 默认
        let stageBreathFreq: Double = lifeStage == .child ? 1.15 : (lifeStage == .adult ? 0.9 : 1.0)
        let stageBreathAmp: Double = lifeStage == .child ? 1.08 : (lifeStage == .adult ? 0.95 : 1.0)
        let stageAdjustedPhase = t * 1.2 * breathFrequencyMultiplier * stageBreathFreq + decayJitter + idleSway * 10
        let stageAdjustedScale = (1.0 + 0.03 * sin(stageAdjustedPhase) * stageBreathAmp) * breathScaleMultiplier
        let (lipY, lipX) = isSpeaking
            ? (1.0 + 0.05 * sin(stageAdjustedPhase * 3), 1.0 - 0.05 * abs(sin(stageAdjustedPhase * 3)))
            : (1.0, 1.0)
        GeometryReader { geometry in
            blobContent(w: geometry.size.width, h: geometry.size.height, breathScale: stageAdjustedScale, breathPhase: stageAdjustedPhase, lipSyncScaleY: lipY, lipSyncScaleX: lipX)
        }
    }

    @ViewBuilder
    private func blobContent(w: CGFloat, h: CGFloat, breathScale: CGFloat, breathPhase: Double, lipSyncScaleY: CGFloat, lipSyncScaleX: CGFloat) -> some View {
        let effectivePokeScale: CGFloat = isStartled ? 0.85 : pokeScale
        let eyeOffset = CGSize(
            width: min(8, max(-8, lookDirection.width * 0.5)),
            height: min(6, max(-6, lookDirection.height * 0.5))
        )
        // 三阶段视觉差异：体型（newborn 明显更小、adult 更饱满）、显隐（四肢/尾巴/嘴仅 child+）
        let bodyRatioW: CGFloat = lifeStage == .adult ? 0.85 : (lifeStage == .child ? 0.78 : 0.72)
        let bodyRatioH: CGFloat = lifeStage == .adult ? 0.9 : (lifeStage == .child ? 0.82 : 0.76)
        let bodyW = w * bodyRatioW * breathScale
        let bodyH = h * bodyRatioH * breathScale
        let stageScale: CGFloat = lifeStage == .newborn ? 0.88 : 1.0  // newborn 整体明显更小，更易区分
        let stageSaturation: Double = lifeStage == .newborn ? 0.88 : (lifeStage == .adult ? 1.08 : 1.0)  // newborn 略淡，adult 更饱和
        let palette = MobiPalette.from(id: effectiveDNA.paletteId)
        let paletteColors = dna != nil ? palette.colors : [primaryColor, primaryColor.opacity(0.9)]
        let accentColor = paletteColors[0]
        let softness = effectiveDNA.softness
        let bodyShapeFactor = effectiveDNA.bodyShapeFactor
        let dragStretchScaleX = 1.0 + min(0.15, max(-0.15, dragStretch.width / 400)) * (0.5 + softness * 0.5)
        let dragStretchScaleY = 1.0 + min(0.15, max(-0.15, dragStretch.height / 400)) * (0.5 + softness * 0.5)

        ZStack {
            // Body with material rendering
            MobiBodyMaterialView(
                paletteColors: paletteColors,
                bodyColorHex: effectiveDNA.bodyColorHex,
                materialId: effectiveDNA.materialId,
                bodyForm: effectiveDNA.bodyForm ?? "round",
                bodyShapeFactor: bodyShapeFactor,
                width: bodyW,
                height: bodyH
            )
            .scaleEffect(x: effectivePokeScale * lipSyncScaleX * dragStretchScaleX, y: effectivePokeScale * lipSyncScaleY * dragStretchScaleY)

            // Fuzziness overlay (semi-transparent circles along outline)
            if effectiveDNA.fuzziness > 0.1 {
                FuzzyOverlayView(fuzziness: effectiveDNA.fuzziness, bodyForm: effectiveDNA.bodyForm ?? "round", bodyW: bodyW, bodyH: bodyH)
                    .scaleEffect(x: effectivePokeScale * lipSyncScaleX * dragStretchScaleX, y: effectivePokeScale * lipSyncScaleY * dragStretchScaleY)
            }

            // Limbs + Tail（child/adult；置于身体之上、五官之下）
            MobiLimbsView(lifeStage: lifeStage, bodySize: CGSize(width: bodyW, height: bodyH), accentColor: accentColor)
                .scaleEffect(x: effectivePokeScale * lipSyncScaleX * dragStretchScaleX, y: effectivePokeScale * lipSyncScaleY * dragStretchScaleY)
            MobiTailView(lifeStage: lifeStage, bodySize: CGSize(width: bodyW, height: bodyH), accentColor: accentColor)
                .scaleEffect(x: effectivePokeScale * lipSyncScaleX * dragStretchScaleX, y: effectivePokeScale * lipSyncScaleY * dragStretchScaleY)

            // Blush (渐变腮红，中心到边缘 0.5→0，更萌)
            if effectiveDNA.blushOpacity > 0.01 {
                let blushColor = Color(red: 1, green: 0.6, blue: 0.65).opacity(effectiveDNA.blushOpacity * 0.5)
                HStack(spacing: bodyW * 0.5) {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [blushColor, blushColor.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: bodyW * 0.08
                            )
                        )
                        .frame(width: bodyW * 0.14, height: bodyH * 0.11)
                        .offset(x: -bodyW * 0.25, y: bodyH * 0.1)
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [blushColor, blushColor.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: bodyW * 0.08
                            )
                        )
                        .frame(width: bodyW * 0.14, height: bodyH * 0.11)
                        .offset(x: bodyW * 0.25, y: bodyH * 0.1)
                }
                .scaleEffect(x: dragStretchScaleX, y: dragStretchScaleY)
            }

            // Eyes (16 types from MobiAssetViews)
            HStack(spacing: w * eyeSocketSpacing) {
                MobiEyeView(eyeShape: effectiveDNA.eyeShape, isBlinking: isBlinking, lookOffset: eyeOffset)
                    .scaleEffect(effectiveDNA.eyeScale)
                MobiEyeView(eyeShape: effectiveDNA.eyeShape, isBlinking: isBlinking, lookOffset: eyeOffset)
                    .scaleEffect(effectiveDNA.eyeScale)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: lookDirection)
            .offset(y: -h * 0.05)

            // Ears (16 types from MobiAssetViews)
            MobiEarOverlayView(earType: effectiveDNA.earType ?? "hamster", accentColor: accentColor, bodySize: CGSize(width: bodyW, height: bodyH))
                .scaleEffect(x: effectivePokeScale * lipSyncScaleX * dragStretchScaleX, y: effectivePokeScale * lipSyncScaleY * dragStretchScaleY)

            // Mouth（child/adult 阶段；性格映射嘴型）
            if lifeStage == .child || lifeStage == .adult {
                MobiMouthView(
                    mouthShape: effectiveDNA.mouthShape ?? "gentle",
                    isSpeaking: isSpeaking,
                    accentColor: accentColor,
                    bodySize: CGSize(width: bodyW, height: bodyH)
                )
                .scaleEffect(x: effectivePokeScale * lipSyncScaleX * dragStretchScaleX, y: effectivePokeScale * lipSyncScaleY * dragStretchScaleY)
            }

            // Soul Vessel（灵器）= 人格槽；瓶身填充由 personalitySlotProgress（用户画像完整度）驱动；点击/长按优先于身体戳击
            Group {
                if vesselHasOverflowed {
                    SoulVesselChestMarkView(soulColor: accentColor)
                } else if let phase = vesselOverflowPhase, phase == .done {
                    SoulVesselChestMarkView(soulColor: accentColor)
                } else {
                    SoulVesselView(
                        fillProgress: vesselFillProgress ?? personalitySlotProgress ?? 0,
                        soulColor: accentColor,
                        shapeType: soulVesselShapeFromMaterial(effectiveDNA.materialId),
                        breathPhase: breathPhase,
                        isAgitated: vesselAgitated,
                        overflowPhase: vesselOverflowPhase
                    )
                    .contentShape(Rectangle())
                    .highPriorityGesture(TapGesture().onEnded { onVesselTap?() })
                    .highPriorityGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in onVesselLongPress?() })
                }
            }
            .scaleEffect(x: effectivePokeScale * lipSyncScaleX * dragStretchScaleX, y: effectivePokeScale * lipSyncScaleY * dragStretchScaleY)
            .offset(y: bodyH * 0.18)

        }
        .saturation(stageSaturation)
        .scaleEffect((isBeingPetted ? 1.02 : 1.0) * stageScale * (energyDepleted ? 0.88 : 1.0))
        .offset(y: energyDepleted ? 15 : 0)
        .rotationEffect(.degrees(idleActivity == .playing ? 2 * sin(breathPhase * 0.67) : 0))
        .animation(.easeInOut(duration: 0.2), value: isBeingPetted)
        .animation(.easeInOut(duration: 0.35), value: energyDepleted)
        .frame(width: w, height: h)
        .shadow(color: isListening ? accentColor.opacity(0.6) : .clear, radius: 20, x: 0, y: 0)
        .contentShape(BodyFormContentShape(bodyForm: effectiveDNA.bodyForm ?? "round", bodyFractionW: 0.8 * breathScale, bodyFractionH: 0.85 * breathScale))
        .onTapGesture { pokeAnimation() }
        .onLongPressGesture(minimumDuration: 0.6, maximumDistance: 15, pressing: { isBeingPetted = $0 }, perform: { onLongPress?() })
        .onAppear { startBlinkingLoop() }
    }

    private func pokeAnimation() {
        HapticEngine.shared.playSoft()
        onPoke?()
        AudioPlayerService.shared.playOneShot(resource: "squeak_1", ext: "mp3")
        let dna = effectiveDNA
        withAnimation(.easeOut(duration: 0.08)) { pokeScale = 0.9 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(
                response: 0.8 - dna.movementResponse * 0.5,
                dampingFraction: 1.0 - dna.bounciness * 0.7
            )) { pokeScale = 1.0 }
        }
    }

    private func startBlinkingLoop() {
        let interval = Double.random(in: 2.0...6.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            withAnimation(.easeInOut(duration: 0.1)) { isBlinking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) { isBlinking = false }
                startBlinkingLoop()
            }
        }
    }
}

// MARK: - Material body view
private struct MobiBodyMaterialView: View {
    let paletteColors: [Color]
    let bodyColorHex: String
    let materialId: String
    var bodyForm: String = "round"
    var bodyShapeFactor: Double = 0
    let width: CGFloat
    let height: CGFloat

    private var baseColor: Color {
        Color.hex(bodyColorHex)
    }

    private var shapeFactorScale: (x: CGFloat, y: CGFloat) {
        (1.0 - CGFloat(bodyShapeFactor) * 0.08, 1.0 + CGFloat(bodyShapeFactor) * 0.04)
    }

    private static let keyLightCenter = UnitPoint(x: 0.35, y: 0.25)

    var body: some View {
        ZStack {
            switch materialId {
            case "fuzzy_felt":
                fuzzyFeltBody()
            case "gummy_jelly":
                gummyJellyBody()
            case "matte_clay":
                matteClayBody()
            case "smooth_plastic":
                smoothPlasticBody()
            default:
                matteClayBody()
            }
        }
        .scaleEffect(x: shapeFactorScale.x, y: shapeFactorScale.y)
        .frame(width: width, height: height)
    }

    private func bodyFillGradient() -> RadialGradient {
        RadialGradient(
            colors: [paletteColors[1], paletteColors[0]],
            center: Self.keyLightCenter,
            startRadius: 0,
            endRadius: width * 0.6
        )
    }

    private func bottomDarkeningOverlay() -> some View {
        MobiBodyFormShape(bodyForm: bodyForm)
            .fill(
                LinearGradient(
                    colors: [.clear, baseColor.opacity(0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blendMode(.multiply)
    }

    private func rimLightStroke() -> some View {
        MobiBodyFormShape(bodyForm: bodyForm)
            .stroke(paletteColors[0].opacity(0.25), lineWidth: 2.5)
    }

    private func fuzzyFeltBody() -> some View {
        ZStack {
            MobiBodyFormShape(bodyForm: bodyForm)
                .fill(bodyFillGradient())
            NoiseGenerator.generateNoiseImage(width: 256, height: 256, intensity: 0.08)
                .resizable(resizingMode: .tile)
                .blendMode(.softLight)
                .mask(MobiBodyFormShape(bodyForm: bodyForm))
            bottomDarkeningOverlay()
            rimLightStroke()
        }
        .blur(radius: 1.5)
        .drawingGroup()
    }

    private func gummyJellyBody() -> some View {
        ZStack {
            // Inner dark core
            MobiBodyFormShape(bodyForm: bodyForm)
                .scale(x: 0.7, y: 0.75)
                .fill(baseColor.opacity(0.6))
                .offset(y: height * 0.03)
            // Main body translucent
            MobiBodyFormShape(bodyForm: bodyForm)
                .fill(
                    RadialGradient(
                        colors: [paletteColors[1].opacity(0.9), paletteColors[0].opacity(0.85)],
                        center: Self.keyLightCenter,
                        startRadius: 0,
                        endRadius: width * 0.6
                    )
                )
                .opacity(0.8)
            bottomDarkeningOverlay()
            // Rim light top-left (existing)
            MobiBodyFormShape(bodyForm: bodyForm)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.7), .white.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
            rimLightStroke()
        }
    }

    private func matteClayBody() -> some View {
        ZStack {
            MobiBodyFormShape(bodyForm: bodyForm)
                .fill(bodyFillGradient())
            bottomDarkeningOverlay()
            MobiBodyFormShape(bodyForm: bodyForm)
                .stroke(baseColor.opacity(0.4), lineWidth: 2.5)
            rimLightStroke()
        }
    }

    private func smoothPlasticBody() -> some View {
        ZStack(alignment: .topLeading) {
            MobiBodyFormShape(bodyForm: bodyForm)
                .fill(bodyFillGradient())
            bottomDarkeningOverlay()
            // Specular highlight (略缩小、略透明，减塑料感)
            Ellipse()
                .fill(.white.opacity(0.55))
                .frame(width: width * 0.18, height: height * 0.1)
                .offset(x: width * 0.38, y: height * 0.18)
            MobiBodyFormShape(bodyForm: bodyForm)
                .stroke(baseColor.opacity(0.4), lineWidth: 2.5)
            rimLightStroke()
        }
    }
}

// MARK: - Fuzzy overlay (outline fuzz along body form contour)
private struct FuzzyOverlayView: View {
    let fuzziness: Double
    let bodyForm: String
    let bodyW: CGFloat
    let bodyH: CGFloat

    var body: some View {
        let count = Int(20 + fuzziness * 15)
        let radius = 2.0 + fuzziness * 3
        let points = outlinePoints(bodyForm: bodyForm, bodyW: bodyW, bodyH: bodyH, count: count)
        ZStack {
            ForEach(0..<points.count, id: \.self) { i in
                let pt = points[i]
                Circle()
                    .fill(.white.opacity(0.15 * fuzziness))
                    .frame(width: radius * 2, height: radius * 2)
                    .offset(x: pt.x - bodyW / 2, y: pt.y - bodyH / 2)
            }
        }
    }

    private func outlinePoints(bodyForm: String, bodyW: CGFloat, bodyH: CGFloat, count: Int) -> [CGPoint] {
        let rect = CGRect(x: 0, y: 0, width: bodyW, height: bodyH)
        let path = MobiBodyFormShape(bodyForm: bodyForm).path(in: rect)
        let center = CGPoint(x: bodyW / 2, y: bodyH / 2)
        var points: [CGPoint] = []
        for i in 0..<count {
            let angle = Double(i) / Double(count) * .pi * 2
            let dx = cos(angle) * bodyW / 2
            let dy = sin(angle) * bodyH / 2
            var r: CGFloat = 0.4
            for step in stride(from: CGFloat(0.4), through: 1.4, by: 0.02) {
                let pt = CGPoint(x: center.x + dx * step, y: center.y + dy * step)
                if path.contains(pt) { r = step } else { break }
            }
            points.append(CGPoint(x: center.x + dx * r, y: center.y + dy * r))
        }
        return points
    }
}
