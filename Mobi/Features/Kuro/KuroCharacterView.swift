//
//  KuroCharacterView.swift
//  Mobi
//
//  Kuro 视觉：深黑、几何体、边缘锐利、浮空。占位用 SwiftUI 几何形状，后续可替换为 Lottie/贴图。
//

import SwiftUI

struct KuroCharacterView: View {
    /// 是否显示「手持」道具（写字板 / 账单）
    var accessory: KuroAccessory? = nil
    /// 尺寸缩放
    var scale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .bottom) {
            // 主体：黑色菱形/几何体，锐利描边
            bodyShape
            if let acc = accessory {
                accessoryView(acc)
            }
        }
        .scaleEffect(scale)
    }

    private var bodyShape: some View {
        Group {
            if UIImage(named: "KuroCharacter") != nil {
                Image("KuroCharacter")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 72)
            } else {
                // 菱形 + 锐利边缘（猫头鹰/几何体占位）
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black)
                        .frame(width: 56, height: 72)
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 56, height: 72)
                    HStack(spacing: 12) {
                        capsuleEye
                        capsuleEye
                    }
                }
            }
        }
    }

    private var capsuleEye: some View {
        Capsule()
            .fill(Color.white.opacity(0.9))
            .frame(width: 8, height: 14)
    }

    private func accessoryView(_ acc: KuroAccessory) -> some View {
        Group {
            switch acc {
            case .clipboard:
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 44, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .offset(y: 8)
            case .bill:
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.15))
                    .frame(width: 52, height: 36)
                    .overlay(
                        Text("账单")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    )
                    .offset(y: 6)
            }
        }
    }
}

enum KuroAccessory {
    case clipboard  // 进化考核：写字板
    case bill      // 能量账单
}

#if DEBUG
struct KuroCharacterView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 24) {
                KuroCharacterView(accessory: nil)
                KuroCharacterView(accessory: .clipboard)
                KuroCharacterView(accessory: .bill)
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
