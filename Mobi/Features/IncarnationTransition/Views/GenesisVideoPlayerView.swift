//
//  GenesisVideoPlayerView.swift
//  Mobi
//
//  AVPlayerLayer-based video player. No SwiftUI controls. Tries multiple filename variations.
//

import SwiftUI
import AVFoundation

struct GenesisVideoPlayerView: UIViewRepresentable {
    var elapsed: Double
    var triggerTime: Double

    /// 视频是否可用；不可用时 IncarnationTransitionView 可显示 fallback 视觉。
    static var isVideoAvailable: Bool { _videoAvailable }
    private static var _videoAvailable = false

    /// Shared player: avoids creating hundreds of AVPlayers when parent re-renders.
    private static let sharedPlayer: AVPlayer = {
        let videoNames = ["genesis_transition", "genesis_video"]
        var url: URL?

        for name in videoNames {
            url = Bundle.main.url(forResource: name, withExtension: "mp4", subdirectory: "Resources")
                ?? Bundle.main.url(forResource: name, withExtension: "mp4")
            if url != nil { break }
        }

        guard let finalURL = url else {
            print("[GenesisVideo] genesis_transition.mp4 not found; using visual fallback.")
            return AVPlayer()
        }

        _videoAvailable = true
        let avPlayer = AVPlayer(url: finalURL)
        avPlayer.actionAtItemEnd = .pause
        return avPlayer
    }()

    func makeUIView(context: Context) -> UIView {
        VideoUIView(player: Self.sharedPlayer)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if elapsed >= triggerTime && Self.sharedPlayer.timeControlStatus != .playing {
            Self.sharedPlayer.play()
        }
    }
}

class VideoUIView: UIView {
    var playerLayer: AVPlayerLayer

    init(player: AVPlayer) {
        playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)

        backgroundColor = .black
        playerLayer.backgroundColor = UIColor.black.cgColor
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// MARK: - 视频缺失时的视觉 fallback：径向光晕渐变，模拟 Genesis 过渡

struct GenesisVideoFallbackView: View {
    var elapsed: Double

    var body: some View {
        GeometryReader { geo in
            let progress = max(0, min(1, (elapsed - 9) / 14))
            let radius = max(geo.size.width, geo.size.height) * (0.3 + progress * 1.2)
            RadialGradient(
                colors: [
                    Color.white.opacity(0.15 + progress * 0.2),
                    Color.cyan.opacity(0.08),
                    Color.black
                ],
                center: .center,
                startRadius: 0,
                endRadius: radius
            )
        }
    }
}
