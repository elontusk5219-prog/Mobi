//
//  GenesisViewModel.swift
//  Mobi
//

import SwiftUI
import Combine

enum LureStage: String, CaseIterable {
    case none
    case visualLure   // idle > 6s: drift + pulse
    case hapticLure   // touching 3s no speech: haptic + hum
    case cognitiveLure // idle > 15s: sendTextQuery + Mystery Purple
}

/// 膝跳反射类型：关键词触发的瞬时视觉微调
private enum ReflexType {
    case freeze   // 冷/冰/静
    case burn     // 火/怒/热
    case heavy    // 沉/累
}

@MainActor
final class GenesisViewModel: ObservableObject {
    /// Soul Casting Protocol: real-time psyche (Warmth, Energy, Chaos) for Amina visual.
    let psycheModel = UserPsycheModel()
    /// Complementary seed (V_Seed = P_Balance − V_User) driving orb appearance.
    @Published private(set) var mobiSeed: MobiSeed = MobiSeed(
        warmth: 0.5,
        energy: 0.4,
        structure: 0.5,
        themeColor: Color(red: 0.2, green: 0.4, blue: 1.0),
        density: 0.5
    )
    /// Genesis phase for visuals (luminousVoid → filling → converging → theSnap).
    @Published private(set) var genesisPhase: GenesisPhase = .luminousVoid

    private let complementaryEngine = ComplementaryEngine()
    /// Entropy 0...1 from 接口AI DeepSeek R1 (conversation diversity); used for ΔSurprise in MobiSeed.
    @Published private(set) var currentEntropy: Double = 0

    @Published var visualScale: CGFloat = 1.0
    @Published var isListening: Bool = false
    @Published var isThinking: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var shouldTriggerImplosion: Bool = false
    /// Gulp: set by ViewModel after 0.28s when listening→thinking; View applies scaleEffect(1.2) then clears.
    @Published var shouldTriggerGulp: Bool = false
    /// Seconds since last tap or voice activity (for "The Itch" / boredom drift).
    @Published var timeSinceLastInteraction: TimeInterval = 0
    /// Lure stage for visuals (drift/pulse, haptic/hum, purple + first words).
    @Published private(set) var lureStage: LureStage = .none
    /// Set by View when finger is down (DragGesture); used for Stage 2.
    @Published var isTouched: Bool = false
    /// Awakening sequence: 0=Void, 1=Ignition, 2=Expansion, 3=Connection, 4=Alive.
    @Published private(set) var startupPhase: Int = 0
    /// Startup overlay opacity (1.0 -> 0 over ~4s). High-key: white or background match.
    @Published var startupOpacity: Double = 1.0
    /// 异步唤醒中：AI 未说第一句前为 true，说完第一句后置 false 并开启麦克风
    @Published var isWakingUp: Bool = true
    /// 第 15 轮结束时先触发 The Snap，白闪后再 recordInteraction + birth。
    @Published var shouldTriggerTheSnap: Bool = false
    /// Soul Hook keyword hit: trigger ink-in-milk pulse with this color (nil = no pulse). View observes and clears after animation.
    @Published var pulseColor: Color?

    /// Visual-semantic sync (Hidden Tag): LLM-driven fluid appearance.
    @Published var fluidColor: VisualCommand.FluidColor?
    /// Aura color queue: last 3 sentiment colors. Index 0 = newest (center), 1 = mid (body), 2 = oldest (background).
    @Published var emotionColors: [Color] = [.blue.opacity(0.55), .purple.opacity(0.45), .cyan.opacity(0.35)]
    @Published var fluidBlur: CGFloat = 60
    @Published var fluidTurbulence: Double = 1.0
    /// TTS lip-sync: turbulence multiplier from normalizedPower when speaking.
    @Published var audioReactiveTurbulence: Double = 1.0
    /// Raw audio power (0...1) for shader/liquid radius: blob throbs when AI speaks.
    @Published var audioPower: Float = 0
    /// TTS 输出电平 0...1，Core Flutter 随语音变化（平滑后）
    @Published var ttsOutputLevel: Float = 0
    /// 15-Turn Soul Profiler: parsed from [METADATA: ...] for particles/debug UI.
    @Published var soulMetadata: SoulMetadata?
    /// Current turn count (0–15) for hunting arc visual tension.
    @Published var turnCount: Int = 0
    /// When true (turns 13+), sphere converges to final soul palette instead of rolling queue.
    @Published var isConverging: Bool = false
    /// Final personality color; set when converging.
    @Published var finalSoulColor: Color?
    /// Harmonious palette for convergence: [base, lighter, darker/hue-shift].
    @Published var cohesivePalette: [Color] = []
    /// When true, coordinator shows IncarnationTransitionView.
    @Published var showIncarnationTransition: Bool = false
    /// Pending transition: set when triggerGenesisComplete; actual transition when speaking→listening (or 8s fallback).
    private var pendingIncarnationTransition: Bool = false
    private var pendingIncarnationTransitionSetTime: Date?
    /// Vibe tremor intensity 0...1 from vibe_keywords in METADATA; drives subtle Shader jitter. Decays over ~4s.
    @Published var vibeTremorIntensity: CGFloat = 0
    /// 膝跳反射：物理下沉 offset（沉/累）
    @Published var reflexOffsetY: CGFloat = 0
    /// Set by commitProfileAndStartGeneration; by 8s either from API or Fallback.
    @Published var resolvedMobiConfig: ResolvedMobiConfig?
    /// Visual DNA from LLM or .default. Room passes to ProceduralMobiView.
    @Published var resolvedVisualDNA: MobiVisualDNA?
    /// 强模型返回的 persona 自然语言描述；nil 时用 SoulProfile.toJSONSummary() 兜底。
    @Published var resolvedRoomPersona: String?
    /// Locked at transition start for Fallback / future API upload.
    private var committedProfile: SoulProfile?
    /// 是否已发起过 commit（第13轮结束时提前发起，避免过渡时再等）
    private var hasCommittedProfile = false
    /// When true, tick() does nothing—reduces GPU/CPU load during IncarnationTransitionView.
    var isTransitionActive: Bool = false
    /// 完整对话 transcript，供强模型生成 Mobi。每轮追加 user / assistant。
    private(set) var transcriptEntries: [(role: String, content: String)] = []

    /// Anima state for AminaFluidView: maps ActivityState to idle/listening/speaking.
    var animaState: AnimaState {
        switch engine.activityState {
        case .listening: return .listening
        case .speaking: return .speaking
        default: return .idle
        }
    }

    /// Single mainColor for AminaFluidView. LLM metadata color (e.g. Red) used exactly—no mixing.
    var animaMainColor: Color {
        mainColorFromMetadata()
    }

    /// Anima Tail: 5x rotation when turnCount >= 13 (convergence overload).
    var convergenceRotationMultiplier: Double { turnCount >= 13 ? 5.0 : 1.0 }
    /// Anima Tail: amplified jitter when turnCount >= 13.
    var convergenceJitterScale: CGFloat { turnCount >= 13 ? 2.0 : 1.0 }

    private let audioVisualizer: AudioVisualizerService
    private let ambientSoundService: AmbientSoundService
    private var lastInteractionTime: Date = Date()
    private var hasTriggeredCognitiveLureThisSession: Bool = false
    private var touchStartTime: Date?
    private var lastHapticLureTime: Date?
    private let engine: MobiEngine
    private var cancellables = Set<AnyCancellable>()
    private var animationPhase: CGFloat = 0
    /// Safety release: if stuck in .thinking or .speaking for > 6s, force idle and unmute.
    private var lastTimeEnteredThinkingOrSpeaking: Date?
    /// When startup overlay was shown; used to force-fade after 4.5s if animation didn’t run.
    private var startupOverlayStartTime: Date?
    private var lastUserInput: String = ""
    private var tickThrottleCounter: Int = 0
    private var lastReflexTime: Date?
    private var preReflexFluidColor: VisualCommand.FluidColor?
    private var preReflexFluidTurbulence: Double = 1.0
    private var reflexResetWorkItem: DispatchWorkItem?

    init(audioVisualizer: AudioVisualizerService, ambientSoundService: AmbientSoundService, engine: MobiEngine) {
        self.audioVisualizer = audioVisualizer
        self.ambientSoundService = ambientSoundService
        self.engine = engine

        engine.$activityState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.handleActivityChange(newState: newState)
                self?.handleWakeUpTransition(newState: newState)
                self?.handleAmbientDucking(newState: newState)
                self?.handleMicGate(newState: newState)
            }
            .store(in: &cancellables)

        engine.$currentMood
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mood in
                self?.ambientSoundService.updateMood(mood)
            }
            .store(in: &cancellables)

        engine.$interactionCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.turnCount = count
            }
            .store(in: &cancellables)

        audioVisualizer.$normalizedPower
            .receive(on: DispatchQueue.main)
            .sink { [weak self] power in
                self?.audioPower = power
                self?.updateVisualScale()
            }
            .store(in: &cancellables)

        AudioPlayerService.shared.$outputLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] raw in
                guard let self else { return }
                let smoothed = self.ttsOutputLevel * 0.6 + raw * 0.4
                self.ttsOutputLevel = smoothed
            }
            .store(in: &cancellables)

        Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
            .store(in: &cancellables)

        psycheModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshMobiSeed() }
            .store(in: &cancellables)

        self.mobiSeed = complementaryEngine.generateMobiSeed(from: psycheModel, entropy: currentEntropy, lastInputText: lastUserInput)
        ambientSoundService.updateSensoryProgress(Float(psycheModel.sensoryProgress))
        fluidColor = VisualCommand.FluidColor.fromWarmthAndTurn(warmth: 0.5, turn: 0)
    }

    private func refreshMobiSeed() {
        mobiSeed = complementaryEngine.generateMobiSeed(from: psycheModel, entropy: currentEntropy, lastInputText: lastUserInput)
    }

    /// User-input-driven mainColor. Orb 仅凭用户输入反应，无 METADATA 依赖。
    private func mainColorFromMetadata() -> Color {
        fluidColor?.swiftUIColor ?? psycheModel.dominantColor
    }

    private func tick() {
        guard !isTransitionActive else { return }
        if turnCount >= 13 {
            tickThrottleCounter += 1
            if tickThrottleCounter % 2 != 0 { return }
        } else {
            tickThrottleCounter = 0
        }
        animationPhase += 0.05 * (2 * CGFloat.pi) / 2
        if animationPhase > 2 * CGFloat.pi { animationPhase -= 2 * CGFloat.pi }
        updateVisualScale()
        isListening = engine.activityState == .listening && audioVisualizer.normalizedPower > 0.1
        isThinking = engine.activityState == .thinking
        isSpeaking = engine.activityState == .speaking
        if isListening {
            lastInteractionTime = Date()
            hasTriggeredCognitiveLureThisSession = false
            interruptLure()
        }
        timeSinceLastInteraction = Date().timeIntervalSince(lastInteractionTime)
        updateGenesisPhase()
        updateLureStage()
        if lureStage == .hapticLure {
            tryFireHapticLure()
        }
        releaseMicGateIfStuck()
        // 保底：若启动遮罩超过 4.5s 仍未淡出，强制淡出
        if let t = startupOverlayStartTime, startupOpacity > 0.01, Date().timeIntervalSince(t) > 4.5 {
            startupOverlayStartTime = nil
            withAnimation(.easeOut(duration: 0.5)) { startupOpacity = 0 }
        }
        if timeSinceLastInteraction > 30.0, !hasTriggeredCognitiveLureThisSession {
            hasTriggeredCognitiveLureThisSession = true
            engine.setActivityState(.seeking)
            DoubaoRealtimeService.shared.sendTextInstruction("Why... is it silent?")
        }
        // 兜底：pending 超过 8s 且处于 listening/idle 时强制触发 Incarnation 过渡（异常流）
        if pendingIncarnationTransition,
           let setAt = pendingIncarnationTransitionSetTime,
           Date().timeIntervalSince(setAt) > 8.0,
           engine.activityState == .listening || engine.activityState == .idle {
            pendingIncarnationTransition = false
            pendingIncarnationTransitionSetTime = nil
            showIncarnationTransition = true
        }
    }

    private func updateGenesisPhase() {
        if genesisPhase == .theSnap { return }
        let progress = psycheModel.sensoryProgress
        if progress <= 0 {
            genesisPhase = .luminousVoid
        } else if progress >= 0.8 {
            genesisPhase = .converging
        } else {
            genesisPhase = .filling
        }
    }

    /// Call from View when The Snap white flash completes; then trigger birth and switch to Room.
    func finishSnapAndBirth() {
        shouldTriggerTheSnap = false
        engine.recordInteraction()
    }

    private func updateLureStage() {
        if isListening || isSpeaking {
            if lureStage != .none { lureStage = .none }
            return
        }
        if timeSinceLastInteraction > 30 {
            lureStage = .cognitiveLure
            return
        }
        if timeSinceLastInteraction > 15 {
            lureStage = .hapticLure
            return
        }
        if timeSinceLastInteraction > 6 {
            lureStage = .visualLure
            return
        }
        lureStage = .none
    }

    /// Stage 2: haptic every 2s (heartbeat/nudge) while idle 15s+
    private func tryFireHapticLure() {
        let now = Date()
        if let last = lastHapticLureTime, now.timeIntervalSince(last) < 2.0 { return }
        lastHapticLureTime = now
        HapticEngine.shared.playSoft()
        HumSoundService.shared.playIfAvailable()
    }

    private func interruptLure() {
        lureStage = .none
        touchStartTime = nil
        lastHapticLureTime = nil
        HumSoundService.shared.stop()
    }

    func setTouching(_ touching: Bool) {
        isTouched = touching
        if touching {
            touchStartTime = Date()
        } else {
            touchStartTime = nil
            lastHapticLureTime = nil
            HumSoundService.shared.stop()
        }
    }

    func clearGulpTrigger() {
        shouldTriggerGulp = false
    }

    private var previousActivityState: ActivityState = .idle
    private var hasEnabledMicAfterWakeUp = false

    /// 根据 activityState 压低/恢复氛围声，避免环境声触发 VAD 误断
    private func handleAmbientDucking(newState: ActivityState) {
        switch newState {
        case .listening:
            ambientSoundService.duckVolume(to: 0.02, duration: 0.5)
        case .speaking:
            ambientSoundService.duckVolume(to: 0.02, duration: 0.5)
        case .idle, .thinking, .seeking:
            ambientSoundService.duckVolume(to: 0.15, duration: 0.5)
        default:
            ambientSoundService.duckVolume(to: 0.15, duration: 0.5)
        }
    }

    /// Half-duplex mic gate: mute uplink while AI is speaking to prevent echo loop.
    private func handleMicGate(newState: ActivityState) {
        switch newState {
        case .speaking:
            if lastTimeEnteredThinkingOrSpeaking == nil { lastTimeEnteredThinkingOrSpeaking = Date() }
            audioVisualizer.isInputMuted = true
            print("[Audio] 🔇 Mic MUTED (AI Speaking)")
        case .thinking:
            if lastTimeEnteredThinkingOrSpeaking == nil { lastTimeEnteredThinkingOrSpeaking = Date() }
        case .listening, .idle, .seeking:
            lastTimeEnteredThinkingOrSpeaking = nil
            audioVisualizer.isInputMuted = false
            print("[Audio] 👂 Mic UNMUTED (User turn)")
        default:
            lastTimeEnteredThinkingOrSpeaking = nil
            break
        }
    }

    /// If stuck in .thinking or .speaking for > 10s, force idle and unmute.
    private func releaseMicGateIfStuck() {
        let state = engine.activityState
        guard state == .thinking || state == .speaking else { return }
        guard let entered = lastTimeEnteredThinkingOrSpeaking else { return }
        guard Date().timeIntervalSince(entered) > 10 else { return }
        lastTimeEnteredThinkingOrSpeaking = nil
        audioVisualizer.isInputMuted = false
        engine.setActivityState(.idle)
        print("[Audio] ⚠️ Mic gate safety release: stuck in \(state.rawValue) > 10s, forced .idle")
    }

    /// AI 开始说第一句时结束唤醒、开启麦克风（仅一次）
    private func handleWakeUpTransition(newState: ActivityState) {
        guard isWakingUp, newState == .speaking, !hasEnabledMicAfterWakeUp else { return }
        hasEnabledMicAfterWakeUp = true
        isWakingUp = false
        audioVisualizer.startMonitoring()
    }

    private func handleActivityChange(newState: ActivityState) {
        if previousActivityState == .listening && newState == .thinking {
            processUserInput(text: engine.currentTranscript)
            shouldTriggerImplosion = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.shouldTriggerImplosion = false
            }
            let gulpDelay: TimeInterval = 0.28
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(gulpDelay * 1_000_000_000))
                self?.shouldTriggerGulp = true
                try? await Task.sleep(nanoseconds: UInt64(0.2 * 1_000_000_000))
                self?.shouldTriggerGulp = false
            }
        }
        // 完整一轮结束：AI 说完 → 计入进化生命值；pending 的 Incarnation 过渡在 1.8s 收尾缓冲后触发
        if previousActivityState == .speaking && (newState == .listening || newState == .idle) {
            ttsOutputLevel = 0
            if pendingIncarnationTransition {
                pendingIncarnationTransition = false
                pendingIncarnationTransitionSetTime = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                    self?.showIncarnationTransition = true
                }
            }
            if engine.interactionCount == 14 {
                shouldTriggerTheSnap = true
                genesisPhase = .theSnap
            } else {
                engine.recordInteraction()
                // 第13轮结束时提前发起 API（第14、15轮 Anima 告别时已有缓冲时间）
                if engine.interactionCount == 13 && !hasCommittedProfile {
                    commitProfileAndStartGeneration()
                }
            }
        }
        // 无 TTS 或 .thinking 路径：从 thinking 进入 listening/idle 时也触发（同 1.8s 延迟）
        if previousActivityState == .thinking && (newState == .listening || newState == .idle) && pendingIncarnationTransition {
            pendingIncarnationTransition = false
            pendingIncarnationTransitionSetTime = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                self?.showIncarnationTransition = true
            }
        }
        previousActivityState = newState
        if newState == .listening || newState == .idle {
            lastTimeEnteredThinkingOrSpeaking = nil
        }
        updateVisualScale()
    }

    /// 膝跳反射：关键词触发的瞬时视觉微调，1.5s 后恢复
    func handleChatContentIncremental(_ accumulated: String) {
        guard !accumulated.isEmpty else { return }
        let now = Date()
        if let last = lastReflexTime, now.timeIntervalSince(last) < 2.0 { return }
        let lower = accumulated.lowercased()
        let type: ReflexType?
        if lower.contains("冷") || lower.contains("冰") || lower.contains("静") {
            type = .freeze
        } else if lower.contains("火") || lower.contains("怒") || lower.contains("热") {
            type = .burn
        } else if lower.contains("沉") || lower.contains("累") {
            type = .heavy
        } else {
            type = nil
        }
        guard let t = type else { return }
        triggerReflex(t)
    }

    private func triggerReflex(_ type: ReflexType) {
        reflexResetWorkItem?.cancel()
        lastReflexTime = Date()
        preReflexFluidColor = fluidColor
        preReflexFluidTurbulence = fluidTurbulence
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
            switch type {
            case .freeze:
                fluidTurbulence = 0.1
                fluidColor = .blue
            case .burn:
                fluidTurbulence = 2.0
                fluidColor = .orange
            case .heavy:
                reflexOffsetY = 20
            }
        }
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in self?.resetReflex() }
        }
        reflexResetWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func resetReflex() {
        reflexResetWorkItem = nil
        withAnimation(.easeOut(duration: 1.0)) {
            reflexOffsetY = 0
            if let c = preReflexFluidColor { fluidColor = c }
            fluidTurbulence = preReflexFluidTurbulence
            preReflexFluidColor = nil
        }
    }

    /// Process user speech: update psyche model, Soul Hooks scripting, Orb 颜色/形态（每轮可见变化），transcript 收集。
    private func processUserInput(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        lastUserInput = text
        transcriptEntries.append((role: "user", content: text))
        psycheModel.updateRealtime(inputText: text, audioAmplitude: Float(audioVisualizer.normalizedPower))
        psycheModel.incrementTurn()
        withAnimation(.interpolatingSpring(stiffness: 150, damping: 14)) {
            fluidColor = VisualCommand.FluidColor.fromWarmthAndTurn(warmth: psycheModel.warmth, turn: psycheModel.conversationTurn)
            injectSentimentColor(psycheModel.dominantColor)
        }
        if let color = UserPsycheModel.scanForSoulHookPulseColor(in: text) {
            triggerVisualPulse(color: color)
        }
        fireSoulHookForCurrentTurn()
        let progress = psycheModel.sensoryProgress
        let turn = psycheModel.conversationTurn
        ambientSoundService.updateSensoryProgress(Float(progress))
        if turn >= 11 {
            ambientSoundService.updateGenesisLatePhase(turn: turn)
        }
        if progress > 0.8 {
            HeartbeatEngine.shared.updateProgress(progress)
        } else {
            HeartbeatEngine.shared.stop()
        }
        Task {
            let e = await JiekouAIEntropyService.shared.fetchEntropy(utterances: psycheModel.sessionTranscriptSnippets)
            await MainActor.run {
                currentEntropy = e
                refreshMobiSeed()
            }
        }
    }

    /// 主路径：收到 ASR 451 用户语音时调用。Turn 源为 interactionCount+1，与 processUserInput 逻辑一致。
    func processUserInputFromASR(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let effectiveTurn = min(15, engine.interactionCount + 1)
        psycheModel.conversationTurn = effectiveTurn
        lastUserInput = text
        transcriptEntries.append((role: "user", content: text))
        psycheModel.updateRealtime(inputText: text, audioAmplitude: Float(audioVisualizer.normalizedPower))
        withAnimation(.interpolatingSpring(stiffness: 150, damping: 14)) {
            fluidColor = VisualCommand.FluidColor.fromWarmthAndTurn(warmth: psycheModel.warmth, turn: effectiveTurn)
            injectSentimentColor(psycheModel.dominantColor)
        }
        if let color = UserPsycheModel.scanForSoulHookPulseColor(in: text) {
            triggerVisualPulse(color: color)
        }
        fireSoulHookForCurrentTurn()
        let progress = psycheModel.sensoryProgress
        ambientSoundService.updateSensoryProgress(Float(progress))
        if effectiveTurn >= 11 {
            ambientSoundService.updateGenesisLatePhase(turn: effectiveTurn)
        }
        if progress > 0.8 {
            HeartbeatEngine.shared.updateProgress(progress)
        } else {
            HeartbeatEngine.shared.stop()
        }
        Task {
            let e = await JiekouAIEntropyService.shared.fetchEntropy(utterances: psycheModel.sessionTranscriptSnippets)
            await MainActor.run {
                currentEntropy = e
                refreshMobiSeed()
            }
        }
    }

    /// Soul Hooks: inject ACT-specific goal so LLM cannot drift; reserved-user nudge.
    /// 注意：501 在后端会被当作用户消息，若在用户发言后发送会干扰对话流。后端已从 200 音频自动获取用户输入并回复，故暂不发送 501，仅保留本地 state 更新。
    private func fireSoulHookForCurrentTurn() {
        // 501 已禁用：后端从 200 音频自动触发 LLM 回复，在用户发言后发 501 会被当作下一条用户消息导致后续轮次混乱。仅保留本地 state 更新（psyche、transcript 等）。
    }

    /// Trigger ink-in-milk pulse on the core. View observes pulseColor and animates; clear after delay.
    func triggerVisualPulse(color: Color) {
        pulseColor = color
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            pulseColor = nil
        }
    }

    /// Switch to final soul palette (turns 13+). Sphere stops rolling colors and converges to a harmonious set based on finalColor.
    func triggerConvergence(finalColor: Color) {
        guard !isConverging else { return }
        isConverging = true
        finalSoulColor = finalColor
        let lighter = finalColor.blended(with: .white, amount: 0.25)
        let darker = finalColor.blended(with: Color(white: 0.15), amount: 0.2)
        cohesivePalette = [finalColor, lighter, darker]
    }

    /// Call at IncarnationTransitionView onAppear (0s)，或第13轮结束时提前调用。优先 transcript → 强模型；否则 SoulProfile → 旧 API。
    func commitProfileAndStartGeneration() {
        guard !hasCommittedProfile else { return }
        hasCommittedProfile = true
        committedProfile = psycheModel.buildSoulProfile()
        resolvedMobiConfig = nil
        resolvedVisualDNA = nil
        resolvedRoomPersona = nil
        guard let profile = committedProfile else { return }
        let transcriptJSON = buildTranscriptJSON()
        Task { @MainActor in
            let result = await GenesisCommitAPI.commit(transcriptJSON: transcriptJSON, profile: profile)
            if case .success(let response) = result {
                let hex = MobiColorPalette.resolveToHex(response.colorHex) ?? response.colorHex
                resolvedMobiConfig = ResolvedMobiConfig(color: Color.hex(hex))
                resolvedVisualDNA = response.visualDNA
                resolvedRoomPersona = response.persona
                if let memories = response.memories, !memories.isEmpty {
                    MemoryDiaryService.addBirthMemories(memories)
                }
            }
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            if resolvedMobiConfig == nil || resolvedVisualDNA == nil {
                applyFallbackConfig()
            }
        }
    }

    /// 供强模型 API 使用的 transcript JSON。格式: [{"role":"user"|"assistant","content":"..."}]
    func buildTranscriptJSON() -> String {
        let arr = transcriptEntries.map { ["role": $0.role, "content": $0.content] }
        guard let data = try? JSONSerialization.data(withJSONObject: arr),
              let str = String(data: data, encoding: .utf8) else { return "[]" }
        return str
    }

    /// Apply Fallback config：API 失败时用 PersonalityToDNAMapper 从 SoulProfile 推导 DNA。
    private func applyFallbackConfig() {
        let dna = committedProfile.map { PersonalityToDNAMapper.map(from: $0) } ?? MobiVisualDNA.default
        resolvedMobiConfig = ResolvedMobiConfig(color: Color.hex(dna.bodyColorHex))
        resolvedVisualDNA = dna
    }

    /// Incremented each time a new sentiment color is injected; view uses it to trigger a brief pulse.
    @Published var emotionPulseTrigger: Int = 0

    /// Pushes a new sentiment color into the aura queue (FIFO, max 3). Use spring animation for liquid morph.
    private func injectSentimentColor(_ newColor: Color) {
        withAnimation(.spring(response: 2.0, dampingFraction: 0.8)) {
            emotionColors.insert(newColor, at: 0)
            if emotionColors.count > 3 {
                emotionColors.removeLast()
            }
        }
        emotionPulseTrigger += 1
    }

    /// Process LLM reply: strip METADATA_UPDATE and [METADATA: ...], update draft, apply visual command. Transition when currentTurn == 15.
    func processLLMResponse(text: String) {
        reflexResetWorkItem?.cancel()
        reflexResetWorkItem = nil
        reflexOffsetY = 0
        print("[Genesis] processLLMResponse called, len=\(text.count)")
        let currentTurn = min(15, engine.interactionCount + 1)
        let (textAfterMeta, draftUpdate, triggerGenesisComplete, legacyMetadata) = SoulMetadataParser.parseAndStripAll(text: text, currentTurn: currentTurn)

        let metadata = legacyMetadata
        if let metadata = metadata {
            soulMetadata = metadata
        }
        if let draft = draftUpdate {
            var normalizedDraft = draft
            if let it = draft.intimacyTag?.lowercased() {
                normalizedDraft.intimacyTag = (it == "close" ? "high" : (it == "distant" ? "low" : it))
            }
            psycheModel.updateDraftFromMetadata(normalizedDraft)
        } else if let metadata = metadata {
            let legacyDraft = MetadataDraftUpdate(
                energyTag: metadata.energyTag,
                intimacyTag: metadata.intimacyTag,
                colorId: metadata.finalSoulColor ?? metadata.color,
                vibeKeywords: nil,
                thoughtProcess: nil,
                currentMood: nil,
                energyLevel: nil,
                openness: nil,
                communicationStyle: nil,
                shellType: nil,
                personalityBase: nil
            )
            psycheModel.updateDraftFromMetadata(legacyDraft)
        }

        let (cleanText, _) = VisualCommandParser.parseAndStrip(text: textAfterMeta)
        if !cleanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            transcriptEntries.append((role: "assistant", content: cleanText))
        }
        let turn = metadata?.turn ?? currentTurn
        if turn >= 13, !isConverging {
            triggerConvergence(finalColor: psycheModel.dominantColor)
        }
        if triggerGenesisComplete {
            pendingIncarnationTransition = true
            pendingIncarnationTransitionSetTime = Date()
        }
    }

    private func updateVisualScale() {
        switch engine.activityState {
        case .listening:
            visualScale = 1.0 + 0.8 * CGFloat(audioVisualizer.normalizedPower)
            audioReactiveTurbulence = 1.0
        case .idle, .seeking:
            visualScale = 1.0 + 0.05 * sin(animationPhase)
            audioReactiveTurbulence = 1.0
        case .thinking:
            visualScale = 1.0 + 0.1 * sin(animationPhase * 5)
            audioReactiveTurbulence = 1.0
        case .speaking:
            visualScale = 1.0 + 0.3 * CGFloat(audioVisualizer.normalizedPower)
            audioReactiveTurbulence = 1.0 + 0.5 * Double(audioVisualizer.normalizedPower)
        default:
            visualScale = 1.0
            audioReactiveTurbulence = 1.0
        }
    }

    func startAudioMonitoring() {
        engine.setActivityState(.listening)
        DoubaoRealtimeService.shared.connect()
        // 异步唤醒：仅在非 isWakingUp 时延迟开麦；isWakingUp 时等 AI 说第一句后再在 handleWakeUpTransition 里开麦
        guard !isWakingUp else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s
            audioVisualizer.startMonitoring()
        }
    }

    /// Run the Awakening sequence: Void -> Ignition (1s) -> Expansion (3s) -> Connection (5s) -> Alive.
    func startAwakeningSequence() {
        startupPhase = 0
        startupOpacity = 1.0
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Phase 1: Ignition (1s)
            startupPhase = 1
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Phase 2: Expansion (3s total)
            startupPhase = 2
            startGenesisAmbient() // Nebula + ambient fade in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Phase 3: Connection (5s total)
            startupPhase = 3
            startAudioMonitoring()
            withAnimation(.easeOut(duration: 4.0)) { startupOpacity = 0.0 }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            startupPhase = 4
        }
    }

    /// Gradual immersion + 异步唤醒：先连接与注入人设，2s 后发 Wake-Up，AI 说第一句后再开麦
    func triggerStartupSequence() {
        isWakingUp = true
        hasEnabledMicAfterWakeUp = false
        startupPhase = 0
        startupOpacity = 1.0
        startupOverlayStartTime = Date()
        withAnimation(.easeOut(duration: 3.0)) { startupOpacity = 0.0 }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000) // T=3
            startupPhase = 2
            try? await Task.sleep(nanoseconds: 1_000_000_000) // T=4
            startupPhase = 3
            startAudioMonitoring() // 仅连接；麦克风在 AI 说第一句时由 handleWakeUpTransition 开启
            try? await Task.sleep(nanoseconds: 1_000_000_000) // T=5
            startupPhase = 4
            lastInteractionTime = Date().addingTimeInterval(-10)
        }
    }

    /// Start Genesis ambient loop with 3s fade-in. Call from view onAppear.
    func startGenesisAmbient() {
        ambientSoundService.playGenesisLoop()
        ambientSoundService.fadeIn(duration: 3.0)
    }

    /// Fade out ambient over 2s and stop. Call from view onDisappear.
    func stopGenesisAmbient() {
        ambientSoundService.fadeOut(duration: 2.0)
    }

    func recordInteraction() {
        lastInteractionTime = Date()
        hasTriggeredCognitiveLureThisSession = false
        interruptLure()
        engine.recordInteraction()
    }
}

// MARK: - Color blending for cohesive palette
private extension Color {
    func blended(with other: Color, amount: Double) -> Color {
        let u1 = UIColor(self)
        let u2 = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 1
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 1
        u1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        u2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = max(0, min(1, amount))
        let r = r1 + (r2 - r1) * t
        let g = g1 + (g2 - g1) * t
        let b = b1 + (b2 - b1) * t
        return Color(red: Double(r), green: Double(g), blue: Double(b))
    }
}
