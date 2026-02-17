//
//  ResolvedMobiConfig.swift
//  Mobi
//
//  Config resolved during Genesis transition (API or Fallback). Used by Room for Mobi appearance.
//

import SwiftUI

struct ResolvedMobiConfig {
    var color: Color
    static var fallback: ResolvedMobiConfig { ResolvedMobiConfig(color: MobiColorPalette.fallback.swiftUIColor) }
}
