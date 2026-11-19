//
//  Story004_LogoKick.swift
//  Notchd
//
//  #4 AI-badge kick: the crab kicks a generic green knot badge away.
//

import SwiftUI

extension CrabStory {
    static let logoKick = CrabStory(
        id: "logoKick", number: 4, title: "AI-badge kick",
        moods: [.idle], category: .tokens
    ) { await $0.logoKick() }
}

private extension CrabStage {
    func logoKick() async -> Bool {
        let side: CGFloat = Bool.random() ? 1 : -1
        let startX: CGFloat = side > 0 ? 98 : -32
        let restX: CGFloat = side > 0 ? 76 : -10

        // The badge rolls up next to the crab
        let rolled = await play(5) { progress, _ in
            [Prop(.logo, mix(startX, restX, progress), 43, angle: Double(1 - progress) * 240 * Double(side))]
        }
        guard rolled else { return false }
        eyes = .droopy
        guard await pause(0.45) else { return false }

        // Wind-up, then the kick
        pose(0.15) { tilt = Double(-8 * side); sway = -1.5 * side }
        guard await pause(0.22) else { return false }
        eyes = .open
        legsMoving = true
        legPhase = side > 0 ? 2 : 0
        pose(0.07) { tilt = Double(12 * side); sway = 2.5 * side }
        guard await frame([Prop(.logo, restX, 43), Prop(.spark, restX - 9 * side, 45)], 0.08) else { return false }

        // It sails off, spinning and shrinking
        let flown = await play(6) { progress, _ in
            let (x, y) = arc(restX, 43, restX + 36 * side, -6, height: 18, progress)
            return [Prop(.logo, x, y, size: mix(1, 0.6, progress), angle: Double(progress) * 420 * Double(side))]
        }
        guard flown else { return false }

        // Smug
        legsMoving = false
        setArms(true)
        eyes = .closed
        pose(0.2) { tilt = 0; sway = 0 }
        return await frame([], 0.55)
    }
}
