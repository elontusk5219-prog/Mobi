//
//  RoomParallaxBackground.swift
//  Mobi
//
//  3-layer parallax: Far (Stars/Sky), Mid (Walls/Window), tinted by soul color.
//

import SwiftUI

struct RoomParallaxBackground: View {
    let themeColor: Color
    let parallaxOffset: CGSize
    let parallaxFactorFar: CGFloat = 0.25
    let parallaxFactorMid: CGFloat = 0.55

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                // Layer 1: Far - Stars/Sky (subtle gradient, moves least)
                LinearGradient(
                    colors: [
                        Color(white: 0.12),
                        Color(white: 0.18),
                        themeColor.opacity(0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay(
                    StarFieldView()
                        .opacity(0.6)
                )
                .frame(width: w * 1.1, height: h * 1.1)
                .offset(x: parallaxOffset.width * parallaxFactorFar, y: parallaxOffset.height * parallaxFactorFar)
                .clipped()

                // Layer 2: Mid - Walls + Window
                ProceduralRoomBackground(themeColor: themeColor)
                    .frame(width: w, height: h)
                    .offset(x: parallaxOffset.width * parallaxFactorMid, y: parallaxOffset.height * parallaxFactorMid)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
    }
}

private struct StarFieldView: View {
    var body: some View {
        Canvas { context, size in
            let count = 40
            for i in 0..<count {
                let x = CGFloat(i * 31 % Int(size.width + 100)) - 50
                let y = CGFloat(i * 17 % Int(size.height + 100)) - 50
                let r = CGFloat(i % 3) * 0.5 + 1
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                    with: .color(.white.opacity(0.4 + Double(i % 5) * 0.1))
                )
            }
        }
    }
}
