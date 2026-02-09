//
//  SpinComponent.swift
//  Mobi
//
//  Created by Apple on 2026/2/9.
//

import RealityKit

/// A component that spins the entity around a given axis.
struct SpinComponent: Component {
    let spinAxis: SIMD3<Float> = [0, 1, 0]
}
