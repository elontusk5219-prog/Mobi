//
//  DependencyContainer.swift
//  Mobi
//

import AVFoundation
import Combine
import Foundation

final class DependencyContainer {
    let mobiEngine = MobiEngine.shared
    var evolutionManager: EvolutionManager { mobiEngine.evolution }
    let audioVisualizerService = AudioVisualizerService()
    var audioPlayerService: AudioPlayerService { AudioPlayerService.shared }
    let ambientSoundService = AmbientSoundService()
    let doubaoRealtimeService = DoubaoRealtimeService.shared

    init() {
        doubaoRealtimeService.setAudioPlayer(audioPlayerService)
        audioVisualizerService.playbackReferenceProvider = { [weak ambientSoundService] count in
            ambientSoundService?.getPlaybackReference(frameCount: count)
        }
        configureAudioSession()
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            // .voiceChat enables hardware AEC (subtract speaker from mic). Half-duplex backup: mic gate in AudioVisualizerService when AI is speaking.
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[Audio] Failed to configure session: \(error)")
        }
        #endif
    }
}
