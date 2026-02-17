//
//  MobiRoutineState.swift
//  Mobi
//
//  Mobi 作息状态：由 TimeOfDay 驱动 sleeping/waking/idle/parallelPlay/reflecting。设计见 docs/故事与日常节律-设计与施工表.md §4.3。
//

import Foundation

enum MobiRoutineState: String, CaseIterable {
    case sleeping      // 睡觉（22–6）
    case waking       // 唤醒中
    case idle         // 待机
    case parallelPlay // 平行陪伴（做自己的事）
    case reflecting   // 晚上反思/画画

    /// 当前时段对应的默认作息状态。
    static var current: MobiRoutineState {
        switch TimeOfDay.current {
        case .morning: return .sleeping
        case .day: return .idle
        case .evening: return .sleeping
        }
    }

    /// 是否处于睡觉时段（22–6）。
    static var isSleepingHours: Bool {
        TimeOfDay.isSleepingHours
    }
}
