//
//  MobiTextureModifier.swift
//  Mobi
//
//  Polymorphic material system: vinyl (glossy), fuzzy (flocked), rough (matte).
//  Pure SwiftUI modifiers only — no 3D engine. Performance-critical; use .drawingGroup() where needed.
//

import SwiftUI

// MARK: - Skin Type

enum MobiSkinType: CaseIterable, Sendable {
    case vinyl  // Glossy / Porcelain — "wet" look
    case fuzzy  // Flocked / Velvet — "soft" look
    case rough  // Matte / Concrete — "solid" look
}

// MARK: - Shape + Skin API (Shape Agnostic)

extension Shape {
    /// Applies one of three material textures. Works on any shape (Circle, Capsule, custom Path).
    /// Use with explicit frame for consistent highlight/shadow placement.
    @ViewBuilder
    func skin(_ type: MobiSkinType, color: Color) -> some View {
        MobiSkinnedShape(shape: self, type: type, color: color)
    }
}

// MARK: - Skinned Shape Implementation

private struct MobiSkinnedShape<S: Shape>: View {
    let shape: S
    let type: MobiSkinType
    let color: Color

    private var shadowColor: Color { color.opacity(0.45) }
    private var fuzzyBaseColor: Color { color.opacity(0.92) }

    var body: some View {
        switch type {
        case .vinyl: vinylBody
        case .fuzzy: fuzzyBody
        case .rough: roughBody
        }
    }

    // MARK: A. Vinyl — Glossy / Porcelain ("Wet")

    private var vinylBody: some View {
        shape
            .fill(color)                                    // 1. Base
            .overlay(vinylSpecularOverlay)                  // 2. Specular highlight (white gradient top-left)
            .overlay(vinylRimLight)                         // 3. Rim light (faint white at top edge)
            .shadow(color: shadowColor, radius: 10, x: 0, y: 6)  // 4. Depth
    }

    /// Distinct white gradient at top-left to simulate light source (opacity 0.7).
    private var vinylSpecularOverlay: some View {
        shape.fill(
            LinearGradient(
                colors: [.white.opacity(0.7), .white.opacity(0.2), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .allowsHitTesting(false)
    }

    /// Faint, sharp white inner shadow at top edge (simulated with thin stroke + gradient).
    private var vinylRimLight: some View {
        shape
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.6), .white.opacity(0.15), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
            .allowsHitTesting(false)
    }

    // MARK: B. Fuzzy — Flocked / Velvet ("Soft")

    private var fuzzyBody: some View {
        shape
            .fill(fuzzyBaseColor)                           // 1. Base (slightly desaturated)
            .overlay(fuzzyStrokeBlur)                       // 2. "Fuzz" — stroke same color, blur 4
            .overlay(fuzzyRimGlow)                          // 3. Rim glow (white soft inner shadow)
            .shadow(color: shadowColor.opacity(0.35), radius: 8, x: 0, y: 4)
            .drawingGroup()                                 // GPU off-screen; blurs are expensive
    }

    /// Duplicate of shape with stroke of same color, blurred — "fur sticking out".
    private var fuzzyStrokeBlur: some View {
        shape
            .stroke(color, lineWidth: 4)
            .blur(radius: 4)
            .allowsHitTesting(false)
    }

    /// Soft white around edges (back-scattering). No sharp specular.
    private var fuzzyRimGlow: some View {
        shape
            .stroke(Color.white.opacity(0.5), lineWidth: 8)
            .blur(radius: 4)
            .allowsHitTesting(false)
    }

    // MARK: C. Rough — Matte / Concrete ("Solid")

    private var roughBody: some View {
        shape
            .fill(color)                                    // 1. Base
            .overlay(roughNoiseOverlay)                     // 2. Noise texture (overlay blend)
            .shadow(color: shadowColor.opacity(0.5), radius: 1, x: 0, y: 2)  // 3. Hard, short shadow
        // 4. Flatness — no gradients
    }

    private var roughNoiseOverlay: some View {
        NoiseGenerator.generateNoiseImage(width: 512, height: 512, intensity: 0.2)
            .resizable(resizingMode: .tile)
            .blendMode(.overlay)
            .mask(shape.fill(Color.primary))
            .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview("Mobi Material System") {
    let size: CGFloat = 100
    HStack(spacing: 24) {
        VStack {
            Circle().skin(.vinyl, color: .cyan).frame(width: size, height: size)
            Text("Vinyl").font(.caption)
        }
        VStack {
            Circle().skin(.fuzzy, color: .orange).frame(width: size, height: size)
            Text("Fuzzy").font(.caption)
        }
        VStack {
            Circle().skin(.rough, color: .gray).frame(width: size, height: size)
            Text("Rough").font(.caption)
        }
    }
    .padding(40)
    .background(Color(white: 0.9))
}
