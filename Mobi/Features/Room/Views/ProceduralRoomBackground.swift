//
//  ProceduralRoomBackground.swift
//  Mobi
//
//  Minimal wall + floor, tinted by soul color.
//

import SwiftUI

struct ProceduralRoomBackground: View {
    let themeColor: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(Color(white: 0.95))
                    .frame(height: proxy.size.height * 0.75)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.375)

                Rectangle()
                    .fill(Color(white: 0.92))
                    .frame(height: proxy.size.height * 0.25)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.875)

                Rectangle()
                    .fill(themeColor)
                    .opacity(0.08)
                    .blendMode(.multiply)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
    }
}
