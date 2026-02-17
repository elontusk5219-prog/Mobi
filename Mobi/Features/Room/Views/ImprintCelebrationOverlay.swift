//
//  ImprintCelebrationOverlay.swift
//  Mobi
//
//  学说话「教会」庆祝：粒子/闪光 + Star 教会了我：X，2s 后自动消失。设计见 newborn 学说话上瘾计划。
//

import SwiftUI

struct ImprintCelebrationOverlay: View {
    let word: String
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.bounce, value: opacity)
                Text("Star 教会了我：\(word)")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                opacity = 1
                scale = 1
            }
        }
    }
}

#if DEBUG
struct ImprintCelebrationOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ImprintCelebrationOverlay(word: "水")
    }
}
#endif
