//
//  KuroTipOverlayView.swift
//  Mobi
//
//  Kuro 机制介绍轻量浮层：小号 Kuro + 单句气泡，3–5 秒自动消失或轻触消失，不打断主流程。
//

import SwiftUI

struct KuroTipOverlayView: View {
    let tipKey: KuroTipKey
    var onDismiss: (() -> Void)? = nil

    @State private var opacity: Double = 0
    private let autoDismissSeconds: Double = 4.0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }

            VStack(spacing: 12) {
                KuroCharacterView(accessory: nil, scale: 0.55)
                VStack(spacing: 6) {
                    Text(KuroGibberishGenerator.gibberish(for: tipKey.rawValue))
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(KuroScripts.script(for: tipKey))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .frame(maxWidth: 280)
            }
            .padding(.bottom, 100)
            .opacity(opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.25))
        .ignoresSafeArea()
        .onTapGesture { dismiss() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { opacity = 1 }
            KuroVoiceSynthesizer.shared.speak(KuroGibberishGenerator.gibberish(for: tipKey.rawValue))
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissSeconds) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        KuroVoiceSynthesizer.shared.stop()
        withAnimation(.easeOut(duration: 0.2)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss?()
        }
    }
}

#if DEBUG
struct KuroTipOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        KuroTipOverlayView(tipKey: .soulVessel)
    }
}
#endif
