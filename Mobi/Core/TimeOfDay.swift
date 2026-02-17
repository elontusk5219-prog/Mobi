//
//  TimeOfDay.swift
//  Mobi
//
//  日常节律时段划分：按系统时间判断 morning/day/evening；22–6 为 sleeping。设计见 docs/故事与日常节律-设计与施工表.md §4.1。
//

import Foundation

enum TimeOfDay: String, CaseIterable {
    case morning   // 6:00–12:00
    case day       // 12:00–22:00
    case evening   // 22:00–6:00

    /// 当前时段（按系统时间）。
    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<22: return .day
        default: return .evening  // 22–24, 0–6
        }
    }

    /// 当前是否处于「睡觉时段」（22:00–6:00）。
    static var isSleepingHours: Bool {
        current == .evening
    }
}
