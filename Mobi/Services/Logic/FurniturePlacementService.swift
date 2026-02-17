//
//  FurniturePlacementService.swift
//  Mobi
//
//  房间布置：家具列表、位置持久化、有效区域校验。设计见 newborn 学说话上瘾计划 §6。
//

import Foundation
import SwiftUI

/// 可放置的家具类型（MVP：3–5 件）
enum FurnitureType: String, CaseIterable, Identifiable {
    case cup
    case pillow
    case frame
    case rug
    case lamp

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cup: return "水杯"
        case .pillow: return "抱枕"
        case .frame: return "画框"
        case .rug: return "地毯"
        case .lamp: return "灯"
        }
    }

    /// 用于「教这个词」的契机；如放水杯可教「水」
    var teachableWord: String? {
        switch self {
        case .cup: return "水"
        case .pillow: return "抱枕"
        case .frame: return "画"
        case .rug: return "地毯"
        case .lamp: return "灯"
        }
    }
}

struct PlacedFurniture: Identifiable, Codable {
    let id: String
    let type: FurnitureType.RawValue
    let x: Double  // 0–1 归一化
    let y: Double  // 0–1 归一化

    var furnitureType: FurnitureType? { FurnitureType(rawValue: type) }
}

enum FurniturePlacementService {
    private static let keyPrefix = "Mobi.furniturePlacements."
    private static let maxPlacements = 20

    private static func storageKey(userId: String) -> String {
        keyPrefix + userId
    }

    static func loadPlacements() -> [PlacedFurniture] {
        let userId = UserIdentityService.currentUserId
        guard !userId.isEmpty else { return [] }
        guard let data = UserDefaults.standard.data(forKey: storageKey(userId: userId)),
              let list = try? JSONDecoder().decode([PlacedFurniture].self, from: data) else { return [] }
        return list
    }

    static func savePlacements(_ list: [PlacedFurniture]) {
        let userId = UserIdentityService.currentUserId
        guard !userId.isEmpty else { return }
        var trimmed = Array(list.prefix(maxPlacements))
        guard let data = try? JSONEncoder().encode(trimmed) else { return }
        UserDefaults.standard.set(data, forKey: storageKey(userId: userId))
    }

    static func addPlacement(type: FurnitureType, x: Double, y: Double) {
        var list = loadPlacements()
        let id = "\(type.rawValue)_\(UUID().uuidString.prefix(8))"
        list.append(PlacedFurniture(id: id, type: type.rawValue, x: x, y: y))
        savePlacements(list)
    }

    static func removePlacement(id: String) {
        var list = loadPlacements()
        list.removeAll { $0.id == id }
        savePlacements(list)
    }

    /// 有效放置区域：x 0.1–0.9，y 0.2–0.9（避开 Mobi 中央）
    static func clampToValidRegion(x: Double, y: Double) -> (x: Double, y: Double) {
        (min(max(x, 0.1), 0.9), min(max(y, 0.2), 0.9))
    }
}
