//
//  MobiAssetViews.swift
//  Mobi
//
//  16 eye shapes, 16 ear types, 16 body forms. SwiftUI Shape components for ProceduralMobiView.
//

import SwiftUI

/// 眼白 softened：轻微淡蓝紫偏、opacity 0.25，减硬感
private let eyeScleraColor = Color(red: 0.94, green: 0.95, blue: 1.0).opacity(0.25)

// MARK: - 16 Eye Shapes

struct MobiEyeView: View {
    var eyeShape: String
    var isBlinking: Bool
    var lookOffset: CGSize = .zero

    var body: some View {
        Group {
            switch eyeShape.lowercased() {
            case "droopy": DroopyEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "line": LineEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "sharp": SharpEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "gentle": GentleEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "sleepy": SleepyEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "dot": DotEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "star": StarEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "heart": HeartEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "diamond": DiamondEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "crescent": CrescentEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "wide": WideEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "narrow": NarrowEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "upturned": UpturnedEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "curious": CuriousEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            case "sparkle": SparkleEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            default: RoundEye().view(isBlinking: isBlinking, lookOffset: lookOffset)
            }
        }
        .frame(width: 32, height: 32)
    }
}

private struct RoundEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            Circle().fill(eyeScleraColor).frame(width: 28, height: 28)
            ZStack(alignment: .topLeading) {
                Circle().fill(.black.opacity(0.85)).frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Circle().fill(.white.opacity(0.95)).frame(width: 6, height: 6).offset(x: 4, y: 4)
                Circle().fill(.white.opacity(0.8)).frame(width: 2, height: 2).offset(x: 8, y: 8)
            }
            .offset(x: lookOffset.width, y: lookOffset.height)
        }.scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct DroopyEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            Ellipse().fill(eyeScleraColor).frame(width: 28, height: 22)
            ZStack(alignment: .topLeading) {
                Ellipse().fill(.black.opacity(0.85)).frame(width: 22, height: 18)
                    .overlay(Ellipse().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Ellipse().fill(.white.opacity(0.95)).frame(width: 5, height: 4).offset(x: 3, y: 3)
                Circle().fill(.white.opacity(0.8)).frame(width: 2, height: 2).offset(x: 6, y: 6)
            }
            .offset(x: lookOffset.width * 0.8, y: lookOffset.height + 2)
        }.scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct LineEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            Capsule().fill(eyeScleraColor).frame(width: 24, height: 8)
            ZStack(alignment: .topLeading) {
                Capsule().fill(.black.opacity(0.85)).frame(width: 18, height: 6)
                    .overlay(Capsule().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Ellipse().fill(.white.opacity(0.95)).frame(width: 4, height: 3).offset(x: 2, y: 1)
            }
            .offset(x: lookOffset.width * 0.5, y: lookOffset.height)
        }.scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct SharpEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            SharpEyeShape().fill(eyeScleraColor).frame(width: 28, height: 24)
            ZStack(alignment: .topLeading) {
                SharpEyeShape().fill(.black.opacity(0.9)).frame(width: 22, height: 18)
                    .overlay(SharpEyeShape().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Ellipse().fill(.white.opacity(0.95)).frame(width: 5, height: 4).offset(x: 3, y: 3)
                Circle().fill(.white.opacity(0.8)).frame(width: 2, height: 2).offset(x: 6, y: 6)
            }
            .offset(x: lookOffset.width, y: lookOffset.height)
        }.scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct SharpEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect)
        return p
    }
}

private struct GentleEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            Circle().fill(eyeScleraColor.opacity(0.9)).frame(width: 30, height: 30)
            ZStack(alignment: .topLeading) {
                Circle().fill(.black.opacity(0.75)).frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Circle().fill(.white.opacity(0.95)).frame(width: 6, height: 6).offset(x: 4, y: 4)
                Circle().fill(.white.opacity(0.8)).frame(width: 2, height: 2).offset(x: 9, y: 9)
            }
            .offset(x: lookOffset.width * 0.7, y: lookOffset.height * 0.7)
        }.scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct SleepyEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            SleepyEyeShape().fill(eyeScleraColor).frame(width: 28, height: 14)
            ZStack(alignment: .topLeading) {
                SleepyEyeShape().fill(.black.opacity(0.85)).frame(width: 22, height: 10)
                    .overlay(SleepyEyeShape().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Ellipse().fill(.white.opacity(0.95)).frame(width: 4, height: 3).offset(x: 3, y: 2)
            }
            .offset(x: lookOffset.width * 0.5, y: 1)
        }.scaleEffect(y: isBlinking ? 0.05 : 1.0)
    }
}

private struct SleepyEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect)
        return p
    }
}

private struct DotEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            Circle().fill(.black.opacity(0.9)).frame(width: 8, height: 8)
                .overlay(Circle().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
            Circle().fill(.white.opacity(0.95)).frame(width: 2, height: 2).offset(x: 2, y: 2)
        }
        .offset(x: lookOffset.width, y: lookOffset.height)
        .scaleEffect(isBlinking ? 0.2 : 1.0)
    }
}

private struct StarEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            StarShape(points: 5).fill(.black.opacity(0.85)).frame(width: 24, height: 24)
                .overlay(StarShape(points: 5).stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
            Circle().fill(.white.opacity(0.95)).frame(width: 5, height: 5).offset(x: 4, y: 4)
        }
        .offset(x: lookOffset.width, y: lookOffset.height)
        .scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct StarShape: Shape {
    let points: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let r2 = i % 2 == 0 ? r : r * 0.4
            let pt = CGPoint(x: c.x + CGFloat(cos(angle) as Double) * r2, y: c.y + CGFloat(sin(angle) as Double) * r2)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

private struct HeartEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            HeartShape().fill(.black.opacity(0.85)).frame(width: 22, height: 20)
                .overlay(HeartShape().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
            Circle().fill(.white.opacity(0.95)).frame(width: 4, height: 4).offset(x: 4, y: 4)
        }
        .offset(x: lookOffset.width, y: lookOffset.height)
        .scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.9))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.25), control1: CGPoint(x: w * 0.5, y: h * 0.6), control2: CGPoint(x: 0, y: h * 0.5))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.9), control1: CGPoint(x: 0, y: 0), control2: CGPoint(x: w * 0.25, y: h * 0.5))
        p.addCurve(to: CGPoint(x: w, y: h * 0.25), control1: CGPoint(x: w * 0.75, y: h * 0.5), control2: CGPoint(x: w, y: 0))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.9), control1: CGPoint(x: w, y: h * 0.5), control2: CGPoint(x: w * 0.5, y: h * 0.6))
        p.closeSubpath()
        return p
    }
}

private struct DiamondEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            DiamondShape().fill(.black.opacity(0.85)).frame(width: 20, height: 24)
                .overlay(DiamondShape().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
            Circle().fill(.white.opacity(0.95)).frame(width: 4, height: 4).offset(x: 5, y: 6)
        }
        .offset(x: lookOffset.width, y: lookOffset.height)
        .scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

private struct CrescentEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            CrescentShape().fill(.black.opacity(0.85)).frame(width: 24, height: 18)
                .overlay(CrescentShape().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
            Ellipse().fill(.white.opacity(0.95)).frame(width: 5, height: 4).offset(x: 5, y: 4)
        }
        .offset(x: lookOffset.width, y: lookOffset.height)
        .scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct CrescentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: 0, y: rect.height * 0.2, width: rect.width, height: rect.height * 0.6))
        return p
    }
}

private struct WideEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            Circle().fill(eyeScleraColor.opacity(0.9)).frame(width: 30, height: 30)
            ZStack(alignment: .topLeading) {
                Circle().fill(.black.opacity(0.9)).frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Circle().fill(.white.opacity(0.95)).frame(width: 6, height: 6).offset(x: 4, y: 4)
                Circle().fill(.white.opacity(0.8)).frame(width: 2, height: 2).offset(x: 9, y: 9)
            }
            .offset(x: lookOffset.width, y: lookOffset.height)
        }.scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct NarrowEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            Ellipse().fill(eyeScleraColor).frame(width: 20, height: 28)
            ZStack(alignment: .topLeading) {
                Ellipse().fill(.black.opacity(0.85)).frame(width: 14, height: 22)
                    .overlay(Ellipse().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Ellipse().fill(.white.opacity(0.95)).frame(width: 4, height: 5).offset(x: 2, y: 3)
                Circle().fill(.white.opacity(0.8)).frame(width: 2, height: 2).offset(x: 5, y: 7)
            }
            .offset(x: lookOffset.width * 0.6, y: lookOffset.height)
        }.scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct UpturnedEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            UpturnedEyeShape().fill(eyeScleraColor).frame(width: 26, height: 20)
            ZStack(alignment: .topLeading) {
                UpturnedEyeShape().fill(.black.opacity(0.85)).frame(width: 20, height: 16)
                    .overlay(UpturnedEyeShape().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Ellipse().fill(.white.opacity(0.95)).frame(width: 5, height: 4).offset(x: 3, y: 3)
                Circle().fill(.white.opacity(0.8)).frame(width: 2, height: 2).offset(x: 6, y: 6)
            }
            .offset(x: lookOffset.width, y: lookOffset.height - 1)
        }.scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct UpturnedEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect)
        return p
    }
}

private struct CuriousEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            Ellipse().fill(eyeScleraColor).frame(width: 24, height: 26).rotationEffect(.degrees(-8))
            ZStack(alignment: .topLeading) {
                Ellipse().fill(.black.opacity(0.85)).frame(width: 18, height: 22)
                    .overlay(Ellipse().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Ellipse().fill(.white.opacity(0.95)).frame(width: 5, height: 5).offset(x: 3, y: 3)
                Circle().fill(.white.opacity(0.8)).frame(width: 2, height: 2).offset(x: 6, y: 6)
            }
            .rotationEffect(.degrees(-8))
            .offset(x: lookOffset.width, y: lookOffset.height)
        }.scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

private struct SparkleEye {
    func view(isBlinking: Bool, lookOffset: CGSize) -> some View {
        ZStack {
            Circle().fill(eyeScleraColor.opacity(0.9)).frame(width: 28, height: 28)
            ZStack(alignment: .topLeading) {
                Circle().fill(.black.opacity(0.85)).frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color(white: 0.35).opacity(0.8), lineWidth: 0.5))
                Circle().fill(.white.opacity(0.95)).frame(width: 5, height: 5).offset(x: 3, y: 3)
                Circle().fill(.white.opacity(0.8)).frame(width: 2, height: 2).offset(x: 6, y: 6)
            }
            .offset(x: lookOffset.width, y: lookOffset.height)
            ForEach(0..<4, id: \.self) { i in
                Rectangle().fill(.white.opacity(0.8)).frame(width: 2, height: 6).offset(y: -10).rotationEffect(.degrees(Double(i) * 45))
            }
        }.scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
}

// MARK: - 16 Ear Types

struct MobiEarOverlayView: View {
    var earType: String
    var accentColor: Color
    var bodySize: CGSize

    @ViewBuilder
    var body: some View {
        if earType.lowercased() != "none" {
        switch earType.lowercased() {
        case "rabbit": RabbitEars(color: accentColor).view(size: bodySize)
        case "hamster": HamsterEars(color: accentColor).view(size: bodySize)
        case "bear": BearEars(color: accentColor).view(size: bodySize)
        case "cat": CatEars(color: accentColor).view(size: bodySize)
        case "dog": DogEars(color: accentColor).view(size: bodySize)
        case "fox": FoxEars(color: accentColor).view(size: bodySize)
        case "mouse": MouseEars(color: accentColor).view(size: bodySize)
        case "pig": PigEars(color: accentColor).view(size: bodySize)
        case "owl": OwlEars(color: accentColor).view(size: bodySize)
        case "panda": PandaEars(color: accentColor).view(size: bodySize)
        case "sheep": SheepEars(color: accentColor).view(size: bodySize)
        case "butterfly": ButterflyEars(color: accentColor).view(size: bodySize)
        case "leaf": LeafEars(color: accentColor).view(size: bodySize)
        case "star": StarEars(color: accentColor).view(size: bodySize)
        case "floppy": FloppyEars(color: accentColor).view(size: bodySize)
        default: HamsterEars(color: accentColor).view(size: bodySize)
        }
        }
    }
}

private struct RabbitEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.15) {
            Ellipse().fill(color).frame(width: size.width * 0.12, height: size.height * 0.4).offset(y: -size.height * 0.55)
            Ellipse().fill(color).frame(width: size.width * 0.12, height: size.height * 0.4).offset(y: -size.height * 0.55)
        }
    }
}

private struct HamsterEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.5) {
            Circle().fill(color).frame(width: size.width * 0.2, height: size.width * 0.2).offset(x: -size.width * 0.35, y: -size.height * 0.48)
            Circle().fill(color).frame(width: size.width * 0.2, height: size.width * 0.2).offset(x: size.width * 0.35, y: -size.height * 0.48)
        }
    }
}

private struct BearEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.45) {
            Ellipse().fill(color).frame(width: size.width * 0.25, height: size.width * 0.28).offset(x: -size.width * 0.4, y: -size.height * 0.5)
            Ellipse().fill(color).frame(width: size.width * 0.25, height: size.width * 0.28).offset(x: size.width * 0.4, y: -size.height * 0.5)
        }
    }
}

private struct CatEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.2) {
            Triangle().fill(color).frame(width: size.width * 0.2, height: size.height * 0.3).rotationEffect(.degrees(-15)).offset(x: -size.width * 0.35, y: -size.height * 0.58)
            Triangle().fill(color).frame(width: size.width * 0.2, height: size.height * 0.3).rotationEffect(.degrees(15)).offset(x: size.width * 0.35, y: -size.height * 0.58)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct DogEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.2) {
            Ellipse().fill(color).frame(width: size.width * 0.15, height: size.height * 0.35).rotationEffect(.degrees(-20)).offset(x: -size.width * 0.38, y: -size.height * 0.5)
            Ellipse().fill(color).frame(width: size.width * 0.15, height: size.height * 0.35).rotationEffect(.degrees(20)).offset(x: size.width * 0.38, y: -size.height * 0.5)
        }
    }
}

private struct FoxEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.1) {
            Triangle().fill(color).frame(width: size.width * 0.22, height: size.height * 0.35).rotationEffect(.degrees(-12)).offset(x: -size.width * 0.38, y: -size.height * 0.6)
            Triangle().fill(color).frame(width: size.width * 0.22, height: size.height * 0.35).rotationEffect(.degrees(12)).offset(x: size.width * 0.38, y: -size.height * 0.6)
        }
    }
}

private struct MouseEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.35) {
            Circle().fill(color).frame(width: size.width * 0.35, height: size.width * 0.35).offset(x: -size.width * 0.25, y: -size.height * 0.52)
            Circle().fill(color).frame(width: size.width * 0.35, height: size.width * 0.35).offset(x: size.width * 0.25, y: -size.height * 0.52)
        }
    }
}

private struct PigEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.6) {
            Ellipse().fill(color).frame(width: size.width * 0.12, height: size.width * 0.15).offset(x: -size.width * 0.42, y: -size.height * 0.48)
            Ellipse().fill(color).frame(width: size.width * 0.12, height: size.width * 0.15).offset(x: size.width * 0.42, y: -size.height * 0.48)
        }
    }
}

private struct OwlEars {
    let color: Color
    func view(size: CGSize) -> some View {
        Ellipse().fill(color.opacity(0.3)).frame(width: size.width * 0.08, height: size.height * 0.12).offset(y: -size.height * 0.52)
    }
}

private struct PandaEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.5) {
            ZStack {
                Circle().fill(color).frame(width: size.width * 0.22, height: size.width * 0.22)
                Circle().stroke(.black, lineWidth: 2).frame(width: size.width * 0.22, height: size.width * 0.22)
            }.offset(x: -size.width * 0.36, y: -size.height * 0.5)
            ZStack {
                Circle().fill(color).frame(width: size.width * 0.22, height: size.width * 0.22)
                Circle().stroke(.black, lineWidth: 2).frame(width: size.width * 0.22, height: size.width * 0.22)
            }.offset(x: size.width * 0.36, y: -size.height * 0.5)
        }
    }
}

private struct SheepEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.4) {
            Ellipse().fill(color).frame(width: size.width * 0.18, height: size.width * 0.22).rotationEffect(.degrees(-25)).offset(x: -size.width * 0.38, y: -size.height * 0.5)
            Ellipse().fill(color).frame(width: size.width * 0.18, height: size.width * 0.22).rotationEffect(.degrees(25)).offset(x: size.width * 0.38, y: -size.height * 0.5)
        }
    }
}

private struct ButterflyEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.1) {
            ButterflyShape().fill(color).frame(width: size.width * 0.25, height: size.height * 0.2).offset(y: -size.height * 0.55)
        }
    }
}

private struct ButterflyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        p.addEllipse(in: CGRect(x: c.x - rect.width * 0.4, y: 0, width: rect.width * 0.35, height: rect.height * 0.9))
        p.addEllipse(in: CGRect(x: c.x - rect.width * 0.05, y: 0, width: rect.width * 0.35, height: rect.height * 0.9))
        p.addEllipse(in: CGRect(x: c.x + rect.width * 0.15, y: 0, width: rect.width * 0.35, height: rect.height * 0.9))
        p.addEllipse(in: CGRect(x: c.x + rect.width * 0.5, y: 0, width: rect.width * 0.35, height: rect.height * 0.9))
        return p
    }
}

private struct LeafEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.3) {
            LeafShape().fill(color).frame(width: size.width * 0.15, height: size.height * 0.25).offset(x: -size.width * 0.38, y: -size.height * 0.52)
            LeafShape().fill(color).frame(width: size.width * 0.15, height: size.height * 0.25).scaleEffect(x: -1, y: 1).offset(x: size.width * 0.38, y: -size.height * 0.52)
        }
    }
}

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: 0))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: 0), control: CGPoint(x: 0, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

private struct StarEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.2) {
            StarShape(points: 4).fill(color).frame(width: size.width * 0.15, height: size.width * 0.15).offset(x: -size.width * 0.38, y: -size.height * 0.52)
            StarShape(points: 4).fill(color).frame(width: size.width * 0.15, height: size.width * 0.15).offset(x: size.width * 0.38, y: -size.height * 0.52)
        }
    }
}

private struct FloppyEars {
    let color: Color
    func view(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.05) {
            Ellipse().fill(color).frame(width: size.width * 0.18, height: size.height * 0.5).rotationEffect(.degrees(-30)).offset(x: -size.width * 0.4, y: -size.height * 0.2)
            Ellipse().fill(color).frame(width: size.width * 0.18, height: size.height * 0.5).rotationEffect(.degrees(30)).offset(x: size.width * 0.4, y: -size.height * 0.2)
        }
    }
}

// MARK: - 16 Body Form Shapes

/// Returns a Shape for the given body form. Used by MobiBodyMaterialView.
struct MobiBodyFormShape: Shape {
    var bodyForm: String

    func path(in rect: CGRect) -> Path {
        switch bodyForm.lowercased() {
        case "rounded_square": return RoundedSquareBody.path(in: rect)
        case "triangular": return TriangularBody.path(in: rect)
        case "oval": return OvalBody.path(in: rect)
        case "pear": return PearBody.path(in: rect)
        case "droplet": return DropletBody.path(in: rect)
        case "bean": return BeanBody.path(in: rect)
        case "cloud": return CloudBody.path(in: rect)
        case "star": return StarBody.path(in: rect)
        case "heart": return HeartBody.path(in: rect)
        case "pill": return PillBody.path(in: rect)
        case "potato": return PotatoBody.path(in: rect)
        case "bell": return BellBody.path(in: rect)
        case "mushroom": return MushroomBody.path(in: rect)
        case "bubble": return BubbleBody.path(in: rect)
        case "blob": return BlobBody.path(in: rect)
        default: return RoundBody.path(in: rect)
        }
    }
}

/// Content shape for hit-testing: body form centered in view rect.
struct BodyFormContentShape: Shape {
    var bodyForm: String
    var bodyFractionW: CGFloat
    var bodyFractionH: CGFloat

    func path(in rect: CGRect) -> Path {
        let bodyW = rect.width * bodyFractionW
        let bodyH = rect.height * bodyFractionH
        let bodyRect = CGRect(
            x: rect.midX - bodyW / 2,
            y: rect.midY - bodyH / 2,
            width: bodyW,
            height: bodyH
        )
        return MobiBodyFormShape(bodyForm: bodyForm).path(in: bodyRect)
    }
}

private struct RoundBody {
    static func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}

private struct RoundedSquareBody {
    static func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) * 0.2
        return Path(roundedRect: rect, cornerRadius: r)
    }
}

private struct TriangularBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.15))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.maxY - rect.height * 0.1), control: CGPoint(x: rect.maxX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY - rect.height * 0.1), control: CGPoint(x: rect.midX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.15), control: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

private struct OvalBody {
    static func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect.insetBy(dx: -rect.width * 0.1, dy: 0))
    }
}

private struct PearBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: rect.width * 0.15, y: 0, width: rect.width * 0.7, height: rect.height * 0.6))
        p.addEllipse(in: CGRect(x: rect.width * 0.2, y: rect.height * 0.5, width: rect.width * 0.6, height: rect.height * 0.5))
        return p
    }
}

private struct DropletBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.1), control: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.1), control: CGPoint(x: rect.midX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

private struct BeanBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect.insetBy(dx: rect.width * 0.05, dy: rect.height * 0.02))
        return p
    }
}

private struct CloudBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: 0, y: rect.height * 0.2, width: rect.width * 0.5, height: rect.height * 0.5))
        p.addEllipse(in: CGRect(x: rect.width * 0.25, y: 0, width: rect.width * 0.5, height: rect.height * 0.6))
        p.addEllipse(in: CGRect(x: rect.width * 0.5, y: rect.height * 0.2, width: rect.width * 0.5, height: rect.height * 0.5))
        return p
    }
}

private struct StarBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let r2 = i % 2 == 0 ? r : r * 0.6
            let pt = CGPoint(x: c.x + CGFloat(cos(angle) as Double) * r2, y: c.y + CGFloat(sin(angle) as Double) * r2)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

private struct HeartBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.85))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.25), control1: CGPoint(x: w * 0.5, y: h * 0.65), control2: CGPoint(x: 0, y: h * 0.45))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.85), control1: CGPoint(x: 0, y: 0), control2: CGPoint(x: w * 0.2, y: h * 0.5))
        p.addCurve(to: CGPoint(x: w, y: h * 0.25), control1: CGPoint(x: w * 0.8, y: h * 0.5), control2: CGPoint(x: w, y: 0))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.85), control1: CGPoint(x: w, y: h * 0.45), control2: CGPoint(x: w * 0.5, y: h * 0.65))
        p.closeSubpath()
        return p
    }
}

private struct PillBody {
    static func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect.insetBy(dx: -rect.width * 0.2, dy: rect.height * 0.1))
    }
}

private struct PotatoBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect.insetBy(dx: rect.width * 0.02, dy: rect.height * 0.05))
        return p
    }
}

private struct BellBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.1))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.maxY - rect.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.maxY - rect.height * 0.1), control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.1))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.1))
        p.closeSubpath()
        return p
    }
}

private struct MushroomBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: rect.width * 0.1, y: 0, width: rect.width * 0.8, height: rect.height * 0.5))
        let stem = Path(roundedRect: CGRect(x: rect.width * 0.35, y: rect.height * 0.45, width: rect.width * 0.3, height: rect.height * 0.55), cornerRadius: 8)
        p.addPath(stem)
        return p
    }
}

private struct BubbleBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: 0, y: rect.height * 0.05, width: rect.width, height: rect.height * 0.9))
        return p
    }
}

private struct BlobBody {
    static func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect.insetBy(dx: rect.width * 0.02, dy: rect.height * 0.02))
        return p
    }
}

// MARK: - Personality Slot View (花纹/挂件/贴纸/能量条/收藏格)

/// 人格槽：根据 slotProgress 和 slotType 在 Mobi 身体上显示进度
struct PersonalitySlotView: View {
    var slotProgress: Double
    var slotType: String = "sticker"
    var accentColor: Color
    var bodySize: CGSize

    private let maxSlots = 7

    private var filledCount: Int {
        min(maxSlots, max(0, Int(ceil(slotProgress * Double(maxSlots)))))
    }

    @ViewBuilder
    var body: some View {
        if slotProgress > 0 {
            switch slotType.lowercased() {
            case "pattern": patternView
            case "pendant": pendantView
            case "energy_bar": energyBarView
            case "collection": collectionView
            default: stickerView
            }
        }
    }

    private var stickerView: some View {
        ZStack {
            ForEach(0..<filledCount, id: \.self) { i in
                slotBadge(at: i)
            }
        }
    }

    private var patternView: some View {
        PatternSlotShape(progress: min(1.0, slotProgress * 1.5))
            .stroke(accentColor.opacity(0.7), lineWidth: 2)
            .frame(width: bodySize.width * 0.6, height: bodySize.height * 0.5)
            .offset(y: bodySize.height * 0.05)
    }

    private var pendantView: some View {
        ZStack {
            ForEach(0..<filledCount, id: \.self) { i in
                pendantBead(at: i)
            }
        }
    }

    private var energyBarView: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(accentColor.opacity(0.3))
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: max(0, bodySize.width * 0.5 * slotProgress - 4), height: 6)
                .padding(2)
        }
        .frame(width: bodySize.width * 0.5, height: 8)
        .offset(y: bodySize.height * 0.35)
    }

    private var collectionView: some View {
        let size = min(bodySize.width * 0.12, bodySize.height * 0.12)
        return HStack(spacing: 4) {
            ForEach(0..<maxSlots, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < filledCount ? accentColor : accentColor.opacity(0.2))
                    .frame(width: size, height: size)
            }
        }
        .offset(y: bodySize.height * 0.25)
    }

    private func slotBadge(at index: Int) -> some View {
        let angle = Double(index) / Double(maxSlots) * .pi * 0.6 + .pi * 0.2
        let r = min(bodySize.width, bodySize.height) * 0.32
        let x = cos(angle) * r
        let y = sin(angle) * r + bodySize.height * 0.08
        return Circle()
            .fill(accentColor.opacity(0.9))
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
            .offset(x: x, y: y)
    }

    private func pendantBead(at index: Int) -> some View {
        let angle = Double(index) / Double(maxSlots) * .pi * 0.5 + .pi * 0.35
        let r = min(bodySize.width, bodySize.height) * 0.28
        let x = cos(angle) * r
        let y = sin(angle) * r + bodySize.height * 0.12
        return Ellipse()
            .fill(accentColor)
            .frame(width: 8, height: 12)
            .overlay(Ellipse().stroke(.white.opacity(0.4), lineWidth: 1))
            .offset(x: x, y: y)
    }
}

private struct PatternSlotShape: Shape {
    var progress: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let steps = Int(8 + progress * 8)
        for i in 0..<steps {
            let t = Double(i) / Double(max(1, steps))
            let x = w * (0.2 + t * 0.6)
            let y = h * (0.3 + 0.4 * sin(t * .pi * 2))
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        return p
    }
}

// MARK: - Limbs View（四肢 · Chiikawa 风）

/// 四肢：child 短粗，adult 略细长；newborn 不渲染。
struct MobiLimbsView: View {
    var lifeStage: LifeStage
    var bodySize: CGSize
    var accentColor: Color

    @ViewBuilder
    private func limbCapsule(width w: CGFloat, height h: CGFloat) -> some View {
        Capsule()
            .fill(accentColor)
            .frame(width: w, height: h)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: w, height: h)
                    .scaleEffect(1.08)
                    .blur(radius: 2)
            )
    }

    var body: some View {
        if lifeStage == .child || lifeStage == .adult {
            let isAdult = lifeStage == .adult
            let armLen = bodySize.width * (isAdult ? 0.28 : 0.24)
            let armW = bodySize.width * (isAdult ? 0.06 : 0.08)
            let legLen = bodySize.height * (isAdult ? 0.22 : 0.2)
            let legW = bodySize.width * (isAdult ? 0.07 : 0.09)
            ZStack {
                // 左臂（边缘软化：同形略放大 + accentColor.opacity(0.2) + blur 2）
                limbCapsule(width: armW, height: armLen)
                    .rotationEffect(.degrees(-25))
                    .offset(x: -bodySize.width * 0.42, y: bodySize.height * 0.05)
                // 右臂
                limbCapsule(width: armW, height: armLen)
                    .rotationEffect(.degrees(25))
                    .offset(x: bodySize.width * 0.42, y: bodySize.height * 0.05)
                // 左腿
                limbCapsule(width: legW, height: legLen)
                    .offset(x: -bodySize.width * 0.22, y: bodySize.height * 0.55)
                // 右腿
                limbCapsule(width: legW, height: legLen)
                    .offset(x: bodySize.width * 0.22, y: bodySize.height * 0.55)
            }
        }
    }
}

// MARK: - Tail View（尾巴）

/// 尾巴：child 可见，adult 弱化，newborn 不渲染。
struct MobiTailView: View {
    var lifeStage: LifeStage
    var bodySize: CGSize
    var accentColor: Color

    var body: some View {
        if lifeStage == .child || lifeStage == .adult {
            let isAdult = lifeStage == .adult
            let tailW = bodySize.width * (isAdult ? 0.06 : 0.08)
            let tailH = bodySize.height * (isAdult ? 0.12 : 0.16)
            let baseOpacity = isAdult ? 0.5 : 1.0
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(min(1, baseOpacity * 1.1)),
                            accentColor.opacity(baseOpacity * 0.85)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(tailW, tailH) * 0.6
                    )
                )
                .frame(width: tailW, height: tailH)
                .rotationEffect(.degrees(-35))
                .offset(x: bodySize.width * 0.35, y: bodySize.height * 0.5)
        }
    }
}

// MARK: - Mouth View（嘴巴 · 性格映射）

/// 嘴巴形状，由 mouth_shape 决定；child/adult 阶段渲染。说话时 isSpeaking 可拉长/张开。
struct MobiMouthView: View {
    var mouthShape: String
    var isSpeaking: Bool
    var accentColor: Color
    var bodySize: CGSize

    private let mouthWidth: CGFloat = 0.2
    private let mouthHeight: CGFloat = 0.04

    var body: some View {
        let w = bodySize.width * mouthWidth
        let h = bodySize.height * mouthHeight
        let speakScale = isSpeaking ? 1.3 : 1.0
        MobiMouthShape(shapeType: mouthShape)
            .stroke(Color(white: 0.25), lineWidth: 1.5)
            .frame(width: w * speakScale, height: h * speakScale)
            .offset(y: bodySize.height * 0.2)
    }
}

private struct MobiMouthShape: Shape {
    var shapeType: String

    func path(in rect: CGRect) -> Path {
        switch shapeType.lowercased() {
        case "smile": return mouthSmilePath(in: rect)
        case "grin": return mouthGrinPath(in: rect)
        case "line": return mouthLinePath(in: rect)
        case "calm": return mouthCalmPath(in: rect)
        default: return mouthGentlePath(in: rect)
        }
    }

    private func mouthSmilePath(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.3),
                 radius: min(rect.width, rect.height) * 0.6,
                 startAngle: .degrees(200), endAngle: .degrees(340),
                 clockwise: false)
        return p
    }

    private func mouthGrinPath(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect.insetBy(dx: rect.width * 0.1, dy: rect.height * 0.2))
        return p
    }

    private func mouthLinePath(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.2, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.width * 0.8, y: rect.midY))
        return p
    }

    private func mouthCalmPath(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.15, y: rect.midY + rect.height * 0.15))
        p.addQuadCurve(to: CGPoint(x: rect.width * 0.85, y: rect.midY + rect.height * 0.15),
                      control: CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.2))
        return p
    }

    private func mouthGentlePath(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.2),
                 radius: min(rect.width, rect.height) * 0.4,
                 startAngle: .degrees(220), endAngle: .degrees(320),
                 clockwise: false)
        return p
    }
}

// MARK: - Soul Vessel（灵器）

private struct FlyingSpot: Identifiable {
    let id = UUID()
    let startTime: CFTimeInterval
    let startX: CGFloat
    let startY: CGFloat
}

// MARK: - Soul Vessel 满溢阶段（100% 时：裂纹 → 炸裂 → 光芒融入）

/// Soul Vessel 满溢动画阶段；与 EvolutionManager 只进不退一致，序列仅播放一次。
enum VesselOverflowPhase: String, CaseIterable {
    case cracks   // 瓶身裂纹
    case burst    // 炸裂
    case merge    // 光芒融入身体
    case done     // 结束，展示胸口印记
}

/// 满溢后的胸口印记（Vessel 消失或变胸口印记）。设计见 SoulVessel设计规范 §2.2 100%。
struct SoulVesselChestMarkView: View {
    var soulColor: Color
    private let size: CGFloat = 16

    var body: some View {
        Circle()
            .fill(soulColor.opacity(0.6))
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(soulColor.opacity(0.9), lineWidth: 2)
            }
            .shadow(color: soulColor.opacity(0.5), radius: 4)
    }
}

/// 胸前挂坠：皮绳 + 半透明玻璃瓶 + 熔岩灯内容物。设计见 docs/SoulVessel设计规范.md。
struct SoulVesselView: View {
    var fillProgress: Double  // 0–1，由画像 slotProgress 驱动
    var soulColor: Color
    var shapeType: String = "circle"  // circle | diamond | heart | star
    var breathPhase: Double = 0  // 呼吸相位，液面起伏
    var isAgitated: Bool = false  // 经验获得时液面激荡
    /// 满溢动画阶段；非 nil 时优先展示裂纹/炸裂/融入，.done 时由调用方改为展示胸口印记。
    var overflowPhase: VesselOverflowPhase? = nil

    private let bottleSize: CGFloat = 24
    private let flyDuration: CFTimeInterval = 0.7
    private static let startOffsets: [(CGFloat, CGFloat)] = [
        (-50, -25), (55, -25), (0, -35), (-40, 45), (45, 50)
    ]

    @State private var flyingSpots: [FlyingSpot] = []
    @State private var overflowStartTime: CFTimeInterval = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            if let phase = overflowPhase {
                overflowContent(t: t, phase: phase)
            } else {
                vesselContent(t: t)
            }
        }
        .frame(width: bottleSize * 1.8, height: bottleSize * 2.2)
        .onChange(of: isAgitated) { _, newValue in
            if newValue {
                let now = CFAbsoluteTimeGetCurrent()
                flyingSpots = Self.startOffsets.prefix(4).map { x, y in
                    FlyingSpot(startTime: now, startX: x, startY: y)
                }
            } else {
                flyingSpots = []
            }
        }
        .onChange(of: overflowPhase) { _, newValue in
            if newValue != nil { overflowStartTime = CFAbsoluteTimeGetCurrent() }
        }
    }

    @ViewBuilder
    private func overflowContent(t: Double, phase: VesselOverflowPhase) -> some View {
        let centerX = bottleSize * 0.9
        let centerY = bottleSize * 0.95
        let elapsed = t - overflowStartTime
        switch phase {
        case .cracks:
            ZStack(alignment: .top) {
                cordView
                bottleView(t: t, liquidLevel: 1.0)
                crackOverlay
            }
        case .burst:
            burstParticlesView(elapsed: elapsed, centerX: centerX, centerY: centerY)
        case .merge:
            mergeParticlesView(elapsed: elapsed, centerX: centerX, centerY: centerY)
        case .done:
            EmptyView()
        }
    }

    private var crackOverlay: some View {
        SoulVesselBottleShape(shapeType: shapeType)
            .stroke(Color(white: 0.2), lineWidth: 1.5)
            .frame(width: bottleSize, height: bottleSize * 1.2)
            .offset(y: bottleSize * 0.35)
            .overlay {
                CrackLinesShape()
                    .stroke(Color(white: 0.15), lineWidth: 1.2)
                    .frame(width: bottleSize, height: bottleSize * 1.2)
                    .offset(y: bottleSize * 0.35)
            }
    }

    private func burstParticlesView(elapsed: Double, centerX: CGFloat, centerY: CGFloat) -> some View {
        let count = 12
        let duration: Double = 0.5
        let progress = min(1.0, elapsed / duration)
        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * .pi * 2
                let r = 30 * progress
                let x = centerX + CGFloat(cos(angle)) * CGFloat(r)
                let y = centerY + CGFloat(sin(angle)) * CGFloat(r)
                Circle()
                    .fill(soulColor.opacity(0.9 * (1 - progress)))
                    .frame(width: 6, height: 6)
                    .position(x: x, y: y)
            }
        }
    }

    private func mergeParticlesView(elapsed: Double, centerX: CGFloat, centerY: CGFloat) -> some View {
        let count = 8
        let duration: Double = 0.7
        let progress = min(1.0, elapsed / duration)
        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * .pi * 2
                let r = 30 * (1 - progress)
                let x = centerX + CGFloat(cos(angle)) * CGFloat(r)
                let y = centerY + CGFloat(sin(angle)) * CGFloat(r)
                Circle()
                    .fill(soulColor.opacity(0.8 * (1 - progress * 0.8)))
                    .frame(width: 8, height: 8)
                    .position(x: x, y: y)
            }
        }
    }

    @ViewBuilder
    private func vesselContent(t: Double) -> some View {
        let liquidLevel = liquidLevelAt(t: t)
        let centerX = bottleSize * 0.9
        let centerY = bottleSize * 0.95
        ZStack(alignment: .top) {
            // 皮绳（脖子两侧垂下）
            cordView
            // 玻璃瓶
            bottleView(t: t, liquidLevel: liquidLevel)
            // 光点飞入动效
            ForEach(flyingSpots.filter { spot in
                let elapsed = t - spot.startTime
                return elapsed < flyDuration
            }) { spot in
                flyingSpotView(spot: spot, t: t, centerX: centerX, centerY: centerY)
            }
        }
    }

    @ViewBuilder
    private func flyingSpotView(spot: FlyingSpot, t: Double, centerX: CGFloat, centerY: CGFloat) -> some View {
        let elapsed = t - spot.startTime
        let progress = min(1.0, elapsed / flyDuration)
        let eased = 1 - pow(1 - progress, 2)
        let x = spot.startX + (centerX - spot.startX) * CGFloat(eased)
        let y = spot.startY + (centerY - spot.startY) * CGFloat(eased)
        let opacity = progress < 0.9 ? 0.9 : 0.9 * (1 - (progress - 0.9) / 0.1)
        Circle()
            .fill(soulColor.opacity(opacity))
            .frame(width: 8, height: 8)
            .position(x: x, y: y)
    }

    private var cordView: some View {
        let brown = Color(red: 0.4, green: 0.28, blue: 0.2)
        return ZStack {
            Path { p in
                let cx = bottleSize * 0.9
                let top = bottleSize * 0.1
                p.move(to: CGPoint(x: cx - 12, y: top))
                p.addQuadCurve(to: CGPoint(x: cx - 4, y: bottleSize * 0.8), control: CGPoint(x: cx - 14, y: bottleSize * 0.5))
                p.move(to: CGPoint(x: cx + 12, y: top))
                p.addQuadCurve(to: CGPoint(x: cx + 4, y: bottleSize * 0.8), control: CGPoint(x: cx + 14, y: bottleSize * 0.5))
            }
            .stroke(brown, lineWidth: 3)
        }
    }

    private var vesselShapePath: SoulVesselBottleShape {
        SoulVesselBottleShape(shapeType: shapeType)
    }

    private func bottleView(t: Double, liquidLevel: Double) -> some View {
        let shapePath = vesselShapePath
        return ZStack(alignment: .bottom) {
            // 瓶身（半透明 + 极弱顶部高光 + soulColor 描边）
            shapePath
                .fill(
                    LinearGradient(
                        colors: [soulColor.opacity(0.15), soulColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    shapePath
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.05), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            shapePath
                .stroke(soulColor.opacity(0.5), lineWidth: 2)
            // 内容物（熔岩灯液体）
            liquidLayer(t: t, liquidLevel: liquidLevel)
        }
        .frame(width: bottleSize, height: bottleSize * 1.2)
        .offset(y: bottleSize * 0.35)
    }

    private func liquidLevelAt(t: Double) -> Double {
        let breath = 0.02 * sin(t * 1.2 + breathPhase)
        let base = min(1.0, max(0.05, fillProgress + breath))
        return isAgitated ? base + 0.1 * sin(t * 8) : base
    }

    @ViewBuilder
    private func liquidLayer(t: Double, liquidLevel: Double) -> some View {
        let bottleShape = SoulVesselBottleShape(shapeType: shapeType)
        GeometryReader { g in
            let h = g.size.height
            let fillH = h * liquidLevel
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [soulColor.opacity(0.7), soulColor.opacity(0.5)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: fillH)
                // 熔岩灯光点
                ForEach(0..<3, id: \.self) { i in
                    let phase = Double(i) * 2.1 + t * 0.5
                    let x = 0.5 + 0.25 * sin(phase)
                    let y = 0.3 + 0.4 * (1 - liquidLevel) + 0.2 * cos(phase * 0.7)
                    Circle()
                        .fill(soulColor.opacity(0.8))
                        .frame(width: 6, height: 6)
                        .position(x: g.size.width * x, y: g.size.height * (1 - y))
                }
            }
            .mask(bottleShape)
        }
        .frame(width: bottleSize, height: bottleSize * 1.2)
    }
}

/// 瓶身裂纹（满溢阶段 cracks）
private struct CrackLinesShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        p.move(to: CGPoint(x: cx, y: rect.minY + rect.height * 0.1))
        p.addLine(to: CGPoint(x: cx + rect.width * 0.2, y: cy))
        p.move(to: CGPoint(x: cx - rect.width * 0.15, y: rect.minY + rect.height * 0.3))
        p.addLine(to: CGPoint(x: cx, y: rect.maxY - rect.height * 0.15))
        p.move(to: CGPoint(x: cx + rect.width * 0.1, y: rect.maxY - rect.height * 0.2))
        p.addLine(to: CGPoint(x: cx - rect.width * 0.2, y: cy + rect.height * 0.1))
        return p
    }
}

private struct SoulVesselBottleShape: Shape {
    var shapeType: String

    func path(in rect: CGRect) -> Path {
        switch shapeType.lowercased() {
        case "diamond": return diamondPath(in: rect)
        case "heart": return heartPath(in: rect)
        case "star": return starPath(in: rect)
        default: return Path(ellipseIn: rect)
        }
    }

    private func diamondPath(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.1))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.1))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.midY))
        p.closeSubpath()
        return p
    }

    private func heartPath(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.85))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.25), control1: CGPoint(x: w * 0.5, y: h * 0.65), control2: CGPoint(x: 0, y: h * 0.45))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.85), control1: CGPoint(x: 0, y: 0), control2: CGPoint(x: w * 0.2, y: h * 0.5))
        p.addCurve(to: CGPoint(x: w, y: h * 0.25), control1: CGPoint(x: w * 0.8, y: h * 0.5), control2: CGPoint(x: w, y: 0))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.85), control1: CGPoint(x: w, y: h * 0.45), control2: CGPoint(x: w * 0.5, y: h * 0.65))
        p.closeSubpath()
        return p
    }

    private func starPath(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2 * 0.9
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let r2 = i % 2 == 0 ? r : r * 0.5
            let pt = CGPoint(x: c.x + CGFloat(cos(angle)) * r2, y: c.y + CGFloat(sin(angle)) * r2)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// 长按 Soul Vessel 时展示的弹层：Soul Sync Rate
struct SoulSyncSheetView: View {
    var syncRate: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("\(Int(min(100, max(0, syncRate * 100))))%")
                    .font(.system(size: 64, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Soul Sync Rate")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("灵魂同步")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

/// 从 DNA materialId 推导 Soul Vessel 形状
func soulVesselShapeFromMaterial(_ materialId: String) -> String {
    switch materialId.lowercased() {
    case "matte_clay": return "diamond"
    case "fuzzy_felt": return "heart"
    case "gummy_jelly", "smooth_plastic": return "star"
    default: return "circle"
    }
}
