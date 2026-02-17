//
//  RoomDecorView.swift
//  Mobi
//
//  房间布置：家具选择 + 放置；与 FurniturePlacementService 对接。设计见 newborn 学说话上瘾计划 §6。
//

import SwiftUI

struct RoomDecorView: View {
    @Environment(\.dismiss) private var dismiss
    let themeColor: Color
    var onPlacement: ((FurnitureType, Double, Double) -> Void)? = nil

    @State private var placements: [PlacedFurniture] = []
    @State private var selectedType: FurnitureType? = nil

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height

                ZStack(alignment: .bottom) {
                    // 房间背景
                    Rectangle()
                        .fill(Color(white: 0.95))
                        .overlay(
                            Rectangle()
                                .fill(themeColor.opacity(0.08))
                                .blendMode(.multiply)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // 已放置的家具
                    ForEach(placements) { p in
                        furnitureShape(for: p)
                            .frame(width: 40, height: 40)
                            .position(x: p.x * w, y: p.y * h)
                    }

                    // 布置入口：点击区域放置
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            placeAt(location: location, in: proxy.size)
                        }

                    // 家具选择栏
                    VStack(spacing: 12) {
                        if let t = selectedType {
                            Text("点击房间放置「\(t.label)」")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(FurnitureType.allCases) { type in
                                    Button {
                                        selectedType = selectedType == type ? nil : type
                                    } label: {
                                        VStack(spacing: 4) {
                                            furnitureShape(for: PlacedFurniture(id: "preview", type: type.rawValue, x: 0, y: 0))
                                                .frame(width: 44, height: 44)
                                            Text(type.label)
                                                .font(.caption2)
                                        }
                                        .padding(8)
                                        .background(selectedType == type ? Color.accentColor.opacity(0.3) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("布置房间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                placements = FurniturePlacementService.loadPlacements()
            }
        }
    }

    private func furnitureShape(for p: PlacedFurniture) -> some View {
        let type = p.furnitureType ?? .cup
        return Group {
            switch type {
            case .cup:
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brown.opacity(0.8))
                    .frame(width: 20, height: 28)
            case .pillow:
                Ellipse()
                    .fill(Color.pink.opacity(0.7))
                    .frame(width: 36, height: 28)
            case .frame:
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.brown, lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.5)))
                    .frame(width: 32, height: 36)
            case .rug:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.5))
                    .frame(width: 60, height: 24)
            case .lamp:
                Circle()
                    .fill(Color.yellow.opacity(0.9))
                    .frame(width: 24, height: 24)
            }
        }
    }

    private func placeAt(location: CGPoint, in size: CGSize) {
        guard let type = selectedType else { return }
        let (nx, ny) = FurniturePlacementService.clampToValidRegion(
            x: location.x / size.width,
            y: location.y / size.height
        )
        FurniturePlacementService.addPlacement(type: type, x: nx, y: ny)
        placements = FurniturePlacementService.loadPlacements()
        onPlacement?(type, nx, ny)
        selectedType = nil
    }
}
