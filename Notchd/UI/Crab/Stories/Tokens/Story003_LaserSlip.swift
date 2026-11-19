//
//  Story003_LaserSlip.swift
//  Notchd
//
//  #3 Laser slip: a laser beam sweeps along the floor and the crab slips on it.
//

import SwiftUI

extension CrabStory {
    static let laserSlip = CrabStory(
        id: "laserSlip", number: 3, title: "Laser slip",
        moods: [.alert], category: .tokens
    ) { await $0.laserSlip() }
}

private extension CrabStage {
    func laserSlip() async -> Bool {
        let beamTint = Bool.random() ? 1 : 0
        let span = 66 + AnticsOverlay.padX * 2
        let left = -AnticsOverlay.padX

        // The beam sweeps in along the floor
        let swept = await play(6) { progress, _ in
            [Prop(.laser, left, 50, tint: beamTint, length: mix(6, span, progress))]
        }
        guard swept else { return false }

        // Feet shoot out from under the crab
        let beam = Prop(.laser, left, 50, tint: beamTint, length: span)
        eyes = .wide
        legsMoving = true
        for (step, angle) in [-16.0, 14, -20].enumerated() {
            legPhase = step % 2 == 0 ? 0 : 2
            pose(0.09) { tilt = angle; sway = CGFloat(angle) / 8; lift = -1.5 }
            guard await frame([beam], 0.11) else { return false }
        }

        // Lands flat
        eyes = .closed
        setArms(true)
        pose(0.1) { tilt = 0; sway = 0; lift = 0; scaleX = 1.18; scaleY = 0.7 }
        guard await frame([beam, Prop(.spark, 2, 30, size: 0.8), Prop(.spark, 64, 30, size: 0.8)], 0.15) else { return false }
        guard await frame([beam], 0.4) else { return false }

        // The beam leaves; the crab pops back up, unamused
        legsMoving = false
        let gone = await play(5) { progress, _ in
            [Prop(.laser, mix(left, left + span, progress), 50, tint: beamTint, length: span * (1 - progress))]
        }
        guard gone else { return false }
        setArms(false)
        eyes = .droopy
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { scaleX = 1; scaleY = 1 }
        return await frame([], 0.5)
    }
}
