//
//  RoomContainerView.swift
//  Mobi
//
//  Post-Genesis "First Room". Parallax background, day/night cycle, Mobi drop entrance.
//  MobiBrain 驱动：tick 注入刺激、lookTarget、seeking → sendTextInstruction。
//

import SwiftUI
import Combine

/// 供 Room tick 与回调共享：沉默计时、seeking 是否已触发、lookDirection 平滑、当前拖拽、glance（D3）、重复词教会、布置联动
private final class RoomBrainTickState: ObservableObject {
    @Published var lastVoiceOrTouchTime: Date?
    @Published var hasTriggeredSeekingThisSession = false
    @Published var hasReportedSilenceThisSpan = false
    @Published var lookDirection: CGSize = .zero
    @Published var currentDrag: CGSize = .zero
    @Published var glanceOffset: CGSize = .zero
    @Published var idleActivity: IdleActivity?
    var lastGlanceTime: Date?
    var currentSessionId: String?
    var repeatWordTracker = RepeatWordTracker()
    /// 布置物体后 Mobi 看向该位置；tick 优先使用此 override，3s 后清空
    var lookAtFurnitureOverride: CGSize? = nil
}

/// D3 平行陪伴：idle 时 Mobi 做自己的事；playing = 轻微摇摆，gazing = 发呆。
enum IdleActivity {
    case playing
    case gazing
}

/// D4 晚安流程阶段：画画 → 说晚安 → 钻被 → 屏暗
enum GoodnightPhase: String {
    case drawing
    case saying
    case underCovers
    case screenDim
}

struct RoomContainerView: View {
    let container: DependencyContainer
    @EnvironmentObject private var engine: MobiEngine
    @ObservedObject private var evolution = EvolutionManager.shared
    @ObservedObject private var energyManager = EnergyManager.shared
    @StateObject private var parallaxService = ParallaxMotionService.shared
    @StateObject private var brain = MobiBrain(attachmentFromIntimacyLevel: EvolutionManager.shared.state.intimacyLevel)
    @StateObject private var tickState = RoomBrainTickState()
    /// Background image name in Asset Catalog (e.g. "HomeBackground"). Nil = procedural parallax.
    var backgroundImageName: String? = nil
    /// Cartoon Mobi image name in Asset Catalog (e.g. "MobiPlaceholder"). Nil = procedural shape.
    var mobiImageName: String? = "MobiPlaceholder"
    /// Accent/soul color for placeholder when mobi image is nil.
    private var accentColor: Color {
        engine.resolvedMobiConfig?.color ?? Color(red: 0.3, green: 0.2, blue: 0.6)
    }
    var showTitle: Bool = true

    @State private var mobiDropOffset: CGFloat = -500
    @State private var mobiPosition: CGSize = .zero
    @State private var mobiLiveTranslation: CGSize = .zero
    @State private var hasPlayedLandThud = false
    @State private var showMemoryDiary = false
    @State private var showRoomDecor = false
    @State private var placedFurniture: [PlacedFurniture] = []
    @State private var vesselAgitated = false
    @State private var previousSlotProgress: Double = 0
    @State private var showSoulSyncSheet = false
    /// Soul Vessel 满溢动画阶段；序列仅触发一次，与 evolution.vesselHasOverflowed 一致。
    @State private var vesselOverflowPhase: VesselOverflowPhase? = nil
    /// D4 晚安流程：22 点后进入 Room 时触发。
    @State private var goodnightPhase: GoodnightPhase? = nil
    @State private var goodnightMobiYOffset: CGFloat = 0
    @State private var goodnightMobiScale: CGFloat = 1.0
    @State private var goodnightOverlayOpacity: Double = 0
    /// 故事触发时的轻量提示（「Mobi 在想一件事」），约 2.5s 后消失
    @State private var showStoryHint = false
    /// Kuro 行政 overlay（长按巢穴召唤）
    @State private var showKuroAdmin = false
    /// 从 Kuro 行政进入设置
    @State private var showSettings = false
    /// Day 1 监护人协议（首次进 Room 未签署时展示）；首次用 welcomeIntro 替代
    @State private var showKuroGuardian = false
    /// 开场介绍（星露谷风格，替代 guardian 首次弹窗，内嵌权限请求）
    @State private var showKuroWelcomeIntro = false
    /// 进化考核：人格槽满溢时先弹 Kuro，用户确认后再进入裂纹序列
    @State private var showKuroEvolution = false
    /// 精力耗尽时 Kuro 持账单出场
    @State private var showKuroEnergyBill = false
    /// Kuro 机制介绍轻量提示（情境触发，每类只展示一次）
    @State private var showKuroTip: KuroTipKey? = nil
    /// 学说话「教会」庆祝 overlay（Star 教会了我：X）；2s 后自动消失
    @State private var showImprintCelebration: String? = nil

    private static let userDirection = CGSize(width: 0, height: 30)
    private static let seekingThreshold: TimeInterval = 12.0
    private static let tickInterval: TimeInterval = 0.05
    private static let lookLerpFactor: CGFloat = 0.15
    private static let glanceSilenceThreshold: TimeInterval = 60.0
    private static let glanceCooldownSeconds: TimeInterval = 180.0

    private var isDaytime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour < 18
    }

    private func evolutionAdjustedColor(_ base: Color) -> Color {
        evolution.hasUnlocked(.colorShift)
            ? Color(red: 1.0, green: 0.4, blue: 0.5)
            : base
    }

    /// 管线 Build Phase 将 portrait 复制到 Asset Catalog，命名为 MobiPortraitNewborn/Child/Adult
    private func generatedPortraitAssetName(for stage: LifeStage) -> String? {
        switch stage {
        case .newborn: return "MobiPortraitNewborn"
        case .child: return "MobiPortraitChild"
        case .adult: return "MobiPortraitAdult"
        case .genesis: return nil
        }
    }

    private var dayNightGradient: LinearGradient {
        if isDaytime {
            LinearGradient(colors: [.orange.opacity(0.15), .blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            // D4: 晚上（22–6）房间更暗
            LinearGradient(colors: [.purple.opacity(0.45), .black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
        }
    }

    @ViewBuilder
    private var kuroTipOverlay: some View {
        if let key = showKuroTip {
            KuroTipOverlayView(tipKey: key, onDismiss: { showKuroTip = nil })
        }
    }

    @ViewBuilder
    private func furnitureLayer(size: CGSize) -> some View {
        ForEach(placedFurniture) { p in
            furnitureShape(for: p)
                .frame(width: 40, height: 40)
                .position(x: p.x * size.width, y: p.y * size.height)
        }
    }

    @ViewBuilder
    private func furnitureShape(for p: PlacedFurniture) -> some View {
        let type = p.furnitureType ?? .cup
        Group {
            switch type {
            case .cup:
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brown.opacity(0.8))
                    .frame(width: 20, height: 28)
            case .pillow:
                Ellipse()
                    .fill(Color.pink.opacity(0.7))
                    .frame(width: 36, height: 28)
            case .frame:
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.brown, lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.5)))
                    .frame(width: 32, height: 36)
            case .rug:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.5))
                    .frame(width: 60, height: 24)
            case .lamp:
                Circle()
                    .fill(Color.yellow.opacity(0.9))
                    .frame(width: 24, height: 24)
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let parallaxForeground = parallaxService.parallaxOffset

            ZStack {
                // 优先：显式传入；其次：HomeBackground 存在时使用；否则程序化视差
                let bgName = backgroundImageName ?? "HomeBackground"
                if UIImage(named: bgName) != nil {
                    Image(bgName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .ignoresSafeArea()
                } else {
                    ZStack(alignment: .bottomTrailing) {
                        RoomParallaxBackground(themeColor: accentColor, parallaxOffset: parallaxService.parallaxOffset)
                        if evolution.hasUnlocked(.coffeeCup) {
                            CoffeeCupDoodle()
                                .frame(width: 50, height: 60)
                                .offset(x: -40, y: -80)
                        }
                    }
                }

                // 家具层（布置的房间物品）
                furnitureLayer(size: size)

                // Day/Night overlay
                Rectangle()
                    .fill(dayNightGradient)
                    .blendMode(.overlay)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()

                // D4 晚安屏暗 overlay
                if goodnightOverlayOpacity > 0 {
                    Color.black
                        .opacity(goodnightOverlayOpacity)
                        .ignoresSafeArea()
                }

                // Kuro 视觉层：在 Mobi 后面，左下角，有图用图否则淡色占位
                Group {
                    if UIImage(named: "KuroCharacter") != nil {
                        Image("KuroCharacter")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 72)
                            .shadow(radius: 4, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.15))
                            .frame(width: 56, height: 72)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 12)
                .padding(.bottom, 120)

                // Mobi (Foreground layer with parallax, draggable)
                // 优先：管线同步到 Asset Catalog 的 MobiPortrait{Stage}；其次 mobiImageName；否则 ProceduralMobiView
                Group {
                    if let stageName = generatedPortraitAssetName(for: evolution.effectiveStage),
                       UIImage(named: stageName) != nil {
                        Image(stageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size.width * 0.6, height: size.width * 0.6)
                    } else if let name = mobiImageName, UIImage(named: name) != nil {
                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size.width * 0.6, height: size.width * 0.6)
                    } else {
                        ProceduralMobiView(
                            primaryColor: evolutionAdjustedColor(accentColor),
                            dna: engine.resolvedVisualDNA,
                            dragStretch: mobiLiveTranslation,
                            isSpeaking: engine.activityState == .speaking,
                            isListening: engine.activityState == .listening,
                            lookDirection: CGSize(
                                width: tickState.lookDirection.width + tickState.glanceOffset.width,
                                height: tickState.lookDirection.height + tickState.glanceOffset.height
                            ),
                            idleActivity: tickState.idleActivity,
                            personalitySlotProgress: evolution.personalitySlotProgress,
                            breathScaleMultiplier: brain.breathScaleMultiplier,
                            breathFrequencyMultiplier: brain.breathFrequencyMultiplier,
                            isStartled: brain.isStartled,
                            confidenceDecay: evolution.confidenceDecay,
                            vesselAgitated: vesselAgitated,
                            vesselHasOverflowed: evolution.vesselHasOverflowed,
                            vesselOverflowPhase: vesselOverflowPhase,
                            lifeStage: evolution.effectiveStage,
                            energyDepleted: energyManager.isDepleted,
                            onPoke: {
                                tickState.lastVoiceOrTouchTime = Date()
                                brain.receiveTouchPoke(light: true, location: .zero)
                                BehaviorReportingService.shared.record(event: .poke, sessionId: tickState.currentSessionId)
                            },
                            onLongPress: {
                                tickState.lastVoiceOrTouchTime = Date()
                                BehaviorReportingService.shared.record(event: .longPress, sessionId: tickState.currentSessionId)
                            },
                            onVesselTap: {
                                tickState.lastVoiceOrTouchTime = Date()
                                HapticEngine.shared.playSoft()
                                AudioPlayerService.shared.playOneShot(resource: "squeak_1", ext: "mp3")
                                BehaviorReportingService.shared.record(event: .vesselTap, sessionId: tickState.currentSessionId)
                            },
                            onVesselLongPress: {
                                tickState.lastVoiceOrTouchTime = Date()
                                BehaviorReportingService.shared.record(event: .vesselLongPress, sessionId: tickState.currentSessionId)
                                showSoulSyncSheet = true
                            }
                        )
                        .frame(width: size.width * 0.6, height: size.width * 0.6)
                    }
                }
                .position(center)
                .offset(x: mobiPosition.width + mobiLiveTranslation.width, y: mobiPosition.height + mobiLiveTranslation.height + mobiDropOffset + goodnightMobiYOffset)
                .offset(x: parallaxForeground.width * 1.0, y: parallaxForeground.height * 1.0)
                .scaleEffect(goodnightMobiScale)
                .gesture(
                    DragGesture()
                        .onChanged { mobiLiveTranslation = $0.translation }
                        .onEnded { t in
                            mobiPosition.width += t.translation.width
                            mobiPosition.height += t.translation.height
                            mobiLiveTranslation = .zero
                            BehaviorReportingService.shared.record(event: .drag, sessionId: tickState.currentSessionId)
                        }
                )
                .onChange(of: mobiLiveTranslation) { _, newValue in tickState.currentDrag = newValue }
        .onReceive(Timer.publish(every: Self.tickInterval, on: .main, in: .common).autoconnect()) { _ in
            let now = Date()
            let power = container.audioVisualizerService.normalizedPower
            if power > 0.1 { tickState.lastVoiceOrTouchTime = now }
            let silence = tickState.lastVoiceOrTouchTime.map { now.timeIntervalSince($0) } ?? 0
            brain.receiveVoice(presence: power, deltaTime: Self.tickInterval)
            brain.receiveSilence(duration: silence, deltaTime: Self.tickInterval)
            if tickState.currentDrag != .zero {
                brain.receiveTouchDrag(direction: tickState.currentDrag, deltaTime: Self.tickInterval)
            }
            if engine.activityState == .speaking {
                brain.receiveAISpeaking(deltaTime: Self.tickInterval)
            }
            brain.tick(deltaTime: Self.tickInterval)
            var target: CGSize
            if let override = tickState.lookAtFurnitureOverride {
                target = override
            } else if engine.activityState == .listening && power > 0.1 {
                target = Self.userDirection
            } else if tickState.currentDrag != .zero {
                target = CGSize(
                    width: min(20, max(-20, tickState.currentDrag.width * 0.1)),
                    height: min(20, max(-20, tickState.currentDrag.height * 0.1))
                )
            } else if brain.isSeeking {
                target = CGSize(width: Double.random(in: -10...10), height: Double.random(in: -10...10))
            } else {
                target = CGSize(width: tickState.lookDirection.width * 0.95, height: tickState.lookDirection.height * 0.95)
            }
            tickState.lookDirection = CGSize(
                width: tickState.lookDirection.width + (target.width - tickState.lookDirection.width) * Self.lookLerpFactor,
                height: tickState.lookDirection.height + (target.height - tickState.lookDirection.height) * Self.lookLerpFactor
            )
            if brain.isSeeking && silence >= Self.seekingThreshold && !tickState.hasTriggeredSeekingThisSession {
                let stage = evolution.effectiveStage
                let useNewbornGibberish = stage == .newborn && ImprintService.getCurrentUserImprints().count < 3
                let newbornPhase = NewbornSpeechPhase.from(imprintCount: ImprintService.getCurrentUserImprints().count, hasHeardUserSpeech: NewbornSpeechState.currentUserHasHeardUserSpeech)
                if newbornPhase.suppressesSeeking { return }
                tickState.hasTriggeredSeekingThisSession = true
                let stories = StoryPool.availableStories(stage: stage, triggerType: .silence)
                if let story = stories.first, !useNewbornGibberish {
                    StoryPool.markTriggered(storyId: story.id)
                    DoubaoRealtimeService.shared.sendTextInstruction("Say this as Mobi, to Star: \(story.confusionText)")
                    showStoryHint = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        showStoryHint = false
                    }
                } else {
                    let instruction = MobiPrompts.seekingInstruction(stage: stage, confidenceDecay: evolution.confidenceDecay, brainStateContext: brain.stateContextForPrompt, useNewbornGibberish: useNewbornGibberish)
                    DoubaoRealtimeService.shared.sendTextInstruction(instruction)
                }
                engine.setActivityState(.seeking)
                if !KuroTipStore.currentUserHasShown(.seeking) {
                    KuroTipStore.markCurrentUserShown(.seeking)
                    DispatchQueue.main.async { showKuroTip = .seeking }
                }
            }
            if silence >= 15 && !tickState.hasReportedSilenceThisSpan {
                tickState.hasReportedSilenceThisSpan = true
                BehaviorReportingService.shared.record(event: .silenceInterval(durationSeconds: Int(silence)), sessionId: tickState.currentSessionId)
            }
            if silence < 2 { tickState.hasReportedSilenceThisSpan = false }
            energyManager.tickConsumeIfNeeded(now: now)
            if energyManager.currentEnergy <= 30, !energyManager.isDepleted, !KuroTipStore.currentUserHasShown(.energyLow) {
                KuroTipStore.markCurrentUserShown(.energyLow)
                DispatchQueue.main.async { showKuroTip = .energyLow }
            }
            // D3: idle 时平行陪伴视觉；silence > 3 且非 seeking/说/听
            let isIdle = silence > 3 && !brain.isSeeking && engine.activityState != .speaking && engine.activityState != .listening
            tickState.idleActivity = isIdle ? .playing : nil
            // D3: glance — 沉默 > 60s 且距上次 glance > 3min 时，短暂偏转眼神
            if silence >= Self.glanceSilenceThreshold {
                let canGlance = tickState.lastGlanceTime == nil || (now.timeIntervalSince(tickState.lastGlanceTime!) >= Self.glanceCooldownSeconds)
                if canGlance {
                    tickState.lastGlanceTime = now
                    tickState.glanceOffset = CGSize(width: Double.random(in: -12...12), height: Double.random(in: -12...12))
                }
            }
            tickState.glanceOffset = CGSize(
                width: tickState.glanceOffset.width * 0.97,
                height: tickState.glanceOffset.height * 0.97
            )
        }

                if showTitle {
                    VStack(spacing: 12) {
                        Text("First Room")
                            .font(.title2)
                            .foregroundStyle(.primary)
                        Text("Genesis complete.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    Button {
                        showRoomDecor = true
                    } label: {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .padding(12)
                    }
                    Button {
                        showMemoryDiary = true
                    } label: {
                        Image(systemName: "book.closed.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .padding(12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 50)
                .padding(.trailing, 20)

                if showStoryHint {
                    Text("Mobi 在想一件事")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 56)
                        .animation(.easeInOut(duration: 0.25), value: showStoryHint)
                }

                // Kuro 触控层：透明，长按召唤行政（保证不被 Mobi 完全遮挡时仍可触发）
                Color.clear
                    .frame(width: 72, height: 72)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, 12)
                    .padding(.bottom, 120)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 0.9) {
                        showKuroAdmin = true
                    }

                DebugOverlayView(
                    engine: engine,
                    doubao: container.doubaoRealtimeService,
                    psycheModel: nil,
                    soulMetadata: nil,
                    onJumpToRoom: nil,
                    onStageJumpInRoom: { stage in
                        let useNewbornGibberish = (stage == .newborn) && ImprintService.getCurrentUserImprints().count < 3
                        let script = StoryPool.firstScriptForStage(stage, useNewbornGibberish: useNewbornGibberish)
                        DoubaoRealtimeService.shared.sendTextInstruction(script)
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showKuroAdmin) {
            KuroOverlayView(
                mode: .admin(
                    onSettings: {
                        showKuroAdmin = false
                        showSettings = true
                    },
                    onReset: {
                        engine.resetToGenesis()
                        container.doubaoRealtimeService.disconnect()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            container.doubaoRealtimeService.connect()
                        }
                    }
                )
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showKuroGuardian) {
            KuroOverlayView(
                mode: .guardian(
                    onRequestPermissions: { completion in
                        GuardianProtocolStore.requestMicAndNotificationPermission(completion: completion)
                    },
                    onClose: { _ in
                        GuardianProtocolStore.markGuardianProtocolCompleted(userId: UserIdentityService.currentUserId)
                        container.audioVisualizerService.startMonitoring()
                    }
                )
            )
        }
        .fullScreenCover(isPresented: $showKuroWelcomeIntro) {
            KuroOverlayView(
                mode: .welcomeIntro(
                    onRequestPermissions: { completion in
                        GuardianProtocolStore.requestMicAndNotificationPermission(completion: completion)
                    },
                    onClose: { granted in
                        GuardianProtocolStore.markGuardianProtocolCompleted(userId: UserIdentityService.currentUserId)
                        if granted {
                            container.audioVisualizerService.startMonitoring()
                        }
                    }
                )
            )
        }
        .fullScreenCover(isPresented: $showKuroEvolution) {
            KuroOverlayView(
                mode: .evolution(onPermit: {
                    showKuroEvolution = false
                    vesselOverflowPhase = .cracks
                })
            )
        }
        .onChange(of: energyManager.isDepleted) { _, depleted in
            if depleted { showKuroEnergyBill = true }
        }
        .fullScreenCover(isPresented: $showKuroEnergyBill) {
            KuroOverlayView(
                mode: .energy(
                    onPurchase: { completion in
                        Task {
                            await EnergyStoreService.shared.loadProducts()
                            let ok = await EnergyStoreService.shared.purchase()
                            await MainActor.run { completion(ok) }
                        }
                    },
                    onDismiss: { }
                )
            )
        }
        .overlay { kuroTipOverlay }
        .overlay {
            if let word = showImprintCelebration {
                ImprintCelebrationOverlay(word: word)
            }
        }
        .onChange(of: engine.activityState) { _, newState in
            // 麦克风门：Mobi 说话时静音上行，避免 TTS 被拾进麦克风→ASR→当成用户输入（回声/自体输出当输入）
            switch newState {
            case .speaking:
                container.audioVisualizerService.isInputMuted = true
            case .listening, .idle, .seeking:
                container.audioVisualizerService.isInputMuted = false
            default:
                break
            }
        }
        .onAppear {
            placedFurniture = FurniturePlacementService.loadPlacements()
            // 同步麦克风门初始状态（避免从 Genesis 切到 Room 时沿用旧的 mute 状态）
            container.audioVisualizerService.isInputMuted = (engine.activityState == .speaking)
            // 切换账号后 engine 可能为 nil，用 fallback 避免串号或空白
            if engine.resolvedMobiConfig == nil {
                engine.setResolvedMobiConfig(ResolvedMobiConfig.fallback)
            }
            if engine.resolvedVisualDNA == nil {
                engine.setResolvedVisualDNA(.default)
            }
            if engine.roomPersonaPrompt == nil {
                engine.setRoomPersona("You are Mobi, warm and curious.")
            }
            previousSlotProgress = evolution.personalitySlotProgress
            tickState.lastVoiceOrTouchTime = Date()
            tickState.currentSessionId = UUID().uuidString
            BehaviorReportingService.shared.record(event: .sessionStart, sessionId: tickState.currentSessionId)
            parallaxService.start()
            // Day 1 开场介绍（星露谷风格）替代监护人协议：未签署时先弹 welcomeIntro（内嵌权限），协议完成后再启麦
            if GuardianProtocolStore.currentUserHasCompletedGuardianProtocol {
                container.audioVisualizerService.startMonitoring()
            } else {
                showKuroWelcomeIntro = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                mobiDropOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                if !hasPlayedLandThud {
                    hasPlayedLandThud = true
                    AudioPlayerService.shared.playOneShot(resource: "land_thud", ext: "mp3")
                }
            }
            // D4: 晚上（22–6）进入 Room 时，延迟后启动晚安流程
            if TimeOfDay.current == .evening {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    goodnightPhase = .drawing
                }
            }
            Task {
                await evolution.fetchAndApplyProfile()
                let memoryContext = await EverMemOSMemoryService.fetchMemoriesForSession(stage: evolution.effectiveStage)
                await MainActor.run {
                    let imprints = ImprintService.getCurrentUserImprints().prefix(8)
                    let imprintBullets = imprints.map { rec in
                        let c = rec.content.trimmingCharacters(in: .whitespacesAndNewlines)
                        return c.count > 80 ? String(c.prefix(80)) + "…" : c
                    }.filter { !$0.isEmpty }
                    let imprintBlock = imprintBullets.isEmpty ? "" : imprintBullets.joined(separator: "；")
                    var finalMemoryContext = memoryContext
                    if !imprintBlock.isEmpty {
                        finalMemoryContext = (finalMemoryContext.isEmpty ? "" : finalMemoryContext + "\n\n") + "Star 教会了我：\(imprintBlock)"
                    }
                    let useDay1IceBreaker = evolution.effectiveStage == .newborn && !Day1IceBreakerState.currentUserHasCompletedDay1IceBreaker
                    let useMorningDreamReport = !useDay1IceBreaker && TimeOfDay.current == .morning
                    let useNamingRitual = evolution.effectiveStage == .newborn && Day1IceBreakerState.currentUserHasCompletedDay1IceBreaker && !Day1IceBreakerState.currentUserConfirmedAsStar
                    let useNewbornGibberish = evolution.effectiveStage == .newborn && ImprintService.getCurrentUserImprints().count < 3
                    let newbornPhase = NewbornSpeechPhase.from(imprintCount: ImprintService.getCurrentUserImprints().count, hasHeardUserSpeech: NewbornSpeechState.currentUserHasHeardUserSpeech)
                    DoubaoRealtimeService.shared.shouldSuppressTTS = newbornPhase.suppressesTTS
                    DoubaoRealtimeService.shared.prepareForRoom(
                        personaJSON: engine.roomPersonaPrompt,
                        memoryContext: finalMemoryContext.isEmpty ? nil : finalMemoryContext,
                        confidenceDecay: evolution.confidenceDecay,
                        stage: evolution.effectiveStage,
                        languageHabits: evolution.languageHabits,
                        useDay1IceBreaker: useDay1IceBreaker,
                        useMorningDreamReport: useMorningDreamReport,
                        useNamingRitual: useNamingRitual,
                        useNewbornGibberish: useNewbornGibberish
                    )
                    DoubaoRealtimeService.shared.onChatContent = { [evolution] text in
                        Task { @MainActor in
                            evolution.recordRoomInteraction()
                            EnergyManager.shared.consumeOneTurn()
                            if !Day1IceBreakerState.currentUserHasCompletedDay1IceBreaker {
                                let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                if t.contains("好") || t.contains("Mobi") || t.contains("Star") || t.contains("是") || t.contains("对") {
                                    Day1IceBreakerState.markCurrentUserDay1IceBreakerCompleted()
                                }
                            }
                            // 命名仪式：Mobi 说「好，那我是 Mobi，你是 Star」后标记 Star 已确认
                            if !Day1IceBreakerState.currentUserConfirmedAsStar {
                                let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                if t.contains("Mobi") && t.contains("Star") && (t.contains("好") || t.contains("那我是")) {
                                    Day1IceBreakerState.markCurrentUserConfirmedAsStar()
                                }
                            }
                            ImprintService.tryExtractAndStore(from: text)
                        }
                        EverMemOSMemoryService.storeTurnIfComplete(assistantContent: text)
                    }
                    DoubaoRealtimeService.shared.onUserUtterance = { [evolution, tickState, brain] text in
                        Task { @MainActor in
                            NewbornSpeechState.markCurrentUserHeardUserSpeech()
                            DoubaoRealtimeService.shared.shouldSuppressTTS = NewbornSpeechPhase.current().suppressesTTS
                            tickState.lastVoiceOrTouchTime = Date()
                            evolution.scanAndRecordKeywords(in: text)
                            if evolution.effectiveStage == .newborn, ImprintService.getCurrentUserImprints().count < 5 {
                                let (success, word) = tickState.repeatWordTracker.addUtterance(text)
                                if success, let w = word, !w.isEmpty {
                                    ImprintService.storeLearnedWord(w)
                                    tickState.repeatWordTracker.reset()
                                    showImprintCelebration = w
                                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                                    haptic.impactOccurred()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showImprintCelebration = nil
                                    }
                                }
                            }
                            brain.receiveKeyword(text)
                            let lower = text.lowercased()
                            let emotionKeywords = ["难过", "哭", "伤心", "累", "压力", "不开心", "委屈", "难受"]
                            if emotionKeywords.contains(where: { lower.contains($0) }) {
                                let stories = StoryPool.availableStories(stage: evolution.effectiveStage, triggerType: .emotion)
                                if let story = stories.first {
                                    StoryPool.markTriggered(storyId: story.id)
                                    DoubaoRealtimeService.shared.sendTextInstruction("[User expressed sadness. As Mobi, say this to Star:] \(story.confusionText)")
                                }
                            }
                        }
                        EverMemOSMemoryService.recordUserUtterance(text)
                    }
                    DoubaoRealtimeService.shared.connect()
                }
            }
        }
        .onDisappear {
            BehaviorReportingService.shared.record(event: .sessionEnd, sessionId: tickState.currentSessionId)
            tickState.repeatWordTracker.reset()
            parallaxService.stop()
            DoubaoRealtimeService.shared.onChatContent = nil
            DoubaoRealtimeService.shared.onUserUtterance = nil
            DoubaoRealtimeService.shared.disconnect()
        }
        .sheet(isPresented: $showMemoryDiary) {
            MemoryDiaryView()
        }
        .sheet(isPresented: $showRoomDecor) {
            RoomDecorView(themeColor: accentColor) { _, x, y in
                let dx = (x - 0.5) * 200
                let dy = (y - 0.5) * 200
                tickState.lookAtFurnitureOverride = CGSize(width: dx, height: dy)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    tickState.lookAtFurnitureOverride = nil
                }
            }
        }
        .sheet(isPresented: $showSoulSyncSheet) {
            SoulSyncSheetView(syncRate: evolution.personalitySlotProgress)
        }
        .onChange(of: showSoulSyncSheet) { oldValue, newValue in
            if oldValue == true, newValue == false, !KuroTipStore.currentUserHasShown(.soulVessel) {
                KuroTipStore.markCurrentUserShown(.soulVessel)
                showKuroTip = .soulVessel
            }
        }
        .onChange(of: showRoomDecor) { _, closed in
            if closed { placedFurniture = FurniturePlacementService.loadPlacements() }
        }
        .onChange(of: showMemoryDiary) { oldValue, newValue in
            if oldValue == true, newValue == false, !KuroTipStore.currentUserHasShown(.diary) {
                KuroTipStore.markCurrentUserShown(.diary)
                showKuroTip = .diary
            }
        }
        .onChange(of: evolution.personalitySlotProgress) { oldValue, newValue in
            if newValue > previousSlotProgress {
                vesselAgitated = true
                previousSlotProgress = newValue
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    vesselAgitated = false
                }
            }
            if newValue >= 1.0, !evolution.vesselHasOverflowed, vesselOverflowPhase == nil {
                showKuroEvolution = true
            }
        }
        .onChange(of: goodnightPhase) { _, newValue in
            guard let phase = newValue else { return }
            switch phase {
            case .drawing:
                if !KuroTipStore.currentUserHasShown(.goodnight) {
                    KuroTipStore.markCurrentUserShown(.goodnight)
                    showKuroTip = .goodnight
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    DoubaoRealtimeService.shared.sendTextInstruction("作为 Mobi，对 Star 说晚安，然后准备睡觉。")
                    goodnightPhase = .saying
                }
            case .saying:
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        goodnightMobiYOffset = 80
                        goodnightMobiScale = 0.6
                    }
                    goodnightPhase = .underCovers
                }
            case .underCovers:
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        goodnightOverlayOpacity = 0.9
                    }
                    goodnightPhase = .screenDim
                }
            case .screenDim:
                break
            }
        }
        .onChange(of: vesselOverflowPhase) { _, newValue in
            guard let phase = newValue else { return }
            switch phase {
            case .cracks:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    vesselOverflowPhase = .burst
                }
            case .burst:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    vesselOverflowPhase = .merge
                }
            case .merge:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    vesselOverflowPhase = .done
                }
            case .done:
                evolution.markVesselOverflowed()
                vesselOverflowPhase = nil
            }
        }
    }
}
