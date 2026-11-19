//
//  Story008_KickTokens.swift
//  ClawNotch
//
//  #8 Kick tokens: two tokens drop in and get kicked across the notch.
//

import SwiftUI

extension CrabStory {
    static let kickTokens = CrabStory(
        id: "kickTokens", number: 8, title: "Kick tokens",
        moods: [.waiting], category: .tokens
    ) { await $0.kickTokens() }
}

private extension CrabStage {
    func kickTokens() async -> Bool {
        // Two tokens drop in, one on each side
        let dropped = await play(4) { progress, _ in
            let y = mix(-32, 45, progress * progress)
            return [Prop(.token, -10, y, tint: 1), Prop(.token, 76, y, tint: 2, v: 1)]
        }
        guard dropped else { return false }
        eyes = .wide
        guard await pause(0.3) else { return false }
        eyes = .open
        legsMoving = true

        for side in [CGFloat(-1), 1] {
            let restX: CGFloat = side > 0 ? 76 : -10
            legPhase = side > 0 ? 2 : 0
            pose(0.07) { tilt = Double(12 * side); sway = 2.5 * side }
            let kicked = await play(5) { progress, _ in
                let (x, y) = arc(restX, 45, restX + 30 * side, 2, height: 16, progress)
                var sprites = [Prop(.token, x, y, tint: side > 0 ? 2 : 1, v: side > 0 ? 1 : 0, angle: Double(progress) * 300 * Double(side))]
                if side < 0 { sprites.append(Prop(.token, 76, 45, tint: 2, v: 1)) }
                if progress == 0 { sprites.append(Prop(.spark, restX - 8 * side, 46, size: 0.8)) }
                return sprites
            }
            guard kicked else { return false }
            pose(0.1) { tilt = 0; sway = 0 }
            guard await frame(side < 0 ? [Prop(.token, 76, 45, tint: 2, v: 1)] : [], 0.15) else { return false }
        }

        legsMoving = false
        setArms(true)
        return await frame([], 0.45)
    }
}
