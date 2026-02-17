//
//  IncarnationViewModel.swift
//  Mobi
//
//  Cosmic Sneeze sequence: Void → Spark → Materialization → Sneeze → Connection.
//  Manages phase timing and derived animation values.
//

import Combine
import SwiftUI

enum IncarnationPhase: String, CaseIterable {
    case void      // t=0: 100% black
    case spark     // t=1.5s: Light reveal
    case shaking   // t=2.0s: Mobi appears, vibrates
    case sneezing  // t=3.0s: Squash, puff
    case alive     // t=4.5s: Settle, connection
}

@MainActor
final class IncarnationViewModel: ObservableObject {
    /// Snapshot from GenesisViewModel at sequence start
    let accentColor: Color
    let visualDNA: MobiVisualDNA?

    /// Elapsed time since sequence start (0...)
    @Published var elapsed: TimeInterval = 0
    @Published private(set) var hasCompleted = false

    var onSequenceComplete: (() -> Void)?

    init(accentColor: Color, visualDNA: MobiVisualDNA?) {
        self.accentColor = accentColor
        self.visualDNA = visualDNA
    }

    /// Called each frame from TimelineView. Updates elapsed and triggers completion.
    /// All @Published writes are deferred to avoid "Publishing changes from within view updates".
    func update(elapsed: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.elapsed = elapsed
            if elapsed >= 5.5 && !self.hasCompleted {
                self.hasCompleted = true
                self.onSequenceComplete?()
            }
        }
    }

    // MARK: - Phase

    var currentPhase: IncarnationPhase {
        switch elapsed {
        case ..<1.5: return .void
        case 1.5..<2.0: return .spark
        case 2.0..<3.0: return .shaking
        case 3.0..<4.5: return .sneezing
        default: return .alive
        }
    }

    // MARK: - Phase 1: Spark (1.5s–2.0s) – light mask expands 0→1

    var sparkMaskProgress: CGFloat {
        guard elapsed >= 1.5 else { return 0 }
        let t = min(1, (elapsed - 1.5) / 0.5)
        return CGFloat(t)
    }

    // MARK: - Phase 2: Materialization (2.0s–2.5s) – scale 0.1→1.1→1.0, shake -5°~5°

    var mobiScale: CGFloat {
        guard elapsed >= 2.0 else { return 0.1 }
        let t = elapsed - 2.0
        if t < 0.4 {
            let p = t / 0.4
            return 0.1 + (1.1 - 0.1) * p
        }
        if t < 0.7 {
            let p = (t - 0.4) / 0.3
            return 1.1 - 0.1 * p
        }
        return 1.0
    }

    var shakeAngle: Double {
        guard elapsed >= 2.0, elapsed < 2.5 else { return 0 }
        let t = elapsed - 2.0
        return 5 * sin(t * 40)
    }

    var goldDustActive: Bool {
        elapsed >= 2.0 && elapsed < 3.5
    }

    // MARK: - Phase 3: Sneeze (3.0s–3.5s) – squash y:0.8, expand y:1.2

    var sneezeScaleY: CGFloat {
        guard elapsed >= 3.0 else { return 1.0 }
        let t = elapsed - 3.0
        if t < 0.15 {
            let p = t / 0.15
            return 1.0 - 0.2 * CGFloat(p)
        }
        if t < 0.35 {
            let p = (t - 0.15) / 0.2
            return 0.8 + 0.4 * CGFloat(p)
        }
        if t < 0.5 {
            let p = (t - 0.35) / 0.15
            return 1.2 - 0.2 * CGFloat(p)
        }
        return 1.0
    }

    var sneezePuffActive: Bool {
        elapsed >= 3.15 && elapsed < 3.8
    }

    // MARK: - Phase 4: Connection (4.5s+) – head tilt, UI fade in

    var headTilt: Double {
        guard elapsed >= 4.5 else { return 0 }
        let t = min(1, (elapsed - 4.5) / 0.4)
        return 10 * t
    }

    var uiOpacity: Double {
        guard elapsed >= 4.5 else { return 0 }
        let t = min(1, (elapsed - 4.5) / 0.8)
        return Double(t)
    }
}
