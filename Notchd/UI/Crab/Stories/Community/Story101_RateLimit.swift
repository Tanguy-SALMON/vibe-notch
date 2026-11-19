//
//  Story101_RateLimit.swift
//  Notchd
//
//  #101 Rate-Limit Roadrunner: the crab runs for a Send button; a "429" anvil (three red
//  blocks) appears overhead and squashes it.
//

import SwiftUI

extension CrabStory {
    static let rateLimit = CrabStory(
        id: "rateLimit", number: 101, title: "Rate-Limit Roadrunner",
        moods: [.alert], category: .community
    ) { await $0.rateLimit() }
}

private extension CrabStage {
    func rateLimit() async -> Bool {
        let button = Prop(.sendButton, 76, 45)
        let run: CGFloat = 2
        let anvilX = 33 + units(run)
        func anvil(_ y: CGFloat, alpha: Double = 1) -> Prop { Prop(.anvil, anvilX, y, alpha: alpha) }

        // Sprints for the Send button; something heavy appears overhead
        legsMoving = true
        pose(0.5) { sway = run; tilt = 6 }
        let ran = await play(5) { _, index in
            legPhase = index % 2 == 0 ? 0 : 2
            var sprites = [button]
            if index >= 3 { sprites.append(anvil(index == 3 ? -30 : -20)) }
            return sprites
        }
        guard ran else { return false }

        // Skids, looks up, holds up a tiny "one more?" sign
        legsMoving = false
        eyes = .wide
        rightArmUp = true
        pose(0.1) { tilt = 0 }
        let sign = Prop(.sign, anvilX + 30, 6)
        guard await frame([button, anvil(-17), sign], 0.55) else { return false }

        // Squash
        let flat: CGFloat = 0.28
        let landY = squashedY(0, flat) - 9
        eyes = .closed
        rightArmUp = false
        withAnimation(.easeIn(duration: 0.08)) { scaleY = flat; scaleX = 1.25 }
        guard await play(2, every: 0.05, { progress, _ in [button, anvil(mix(-8, landY, progress)), sign] }) else { return false }
        let impact = [
            button, anvil(landY),
            Prop(.spark, anvilX - 27, 47, size: 0.8), Prop(.spark, anvilX + 27, 47, size: 0.8),
            Prop(.sign, anvilX + 36, 0, angle: 50, alpha: 0.6),
        ]
        guard await frame(impact, 0.12) else { return false }

        // A white sparkle pops out and circles like a halo
        let haloed = await play(10) { _, index in
            let turn = Double(index) * 0.75
            let star = Prop(
                .star,
                anvilX + 13 * CGFloat(cos(turn)),
                landY - 17 + 3 * CGFloat(sin(turn)),
                size: 0.8,
                angle: Double(index) * 40
            )
            return [button, anvil(landY), star]
        }
        guard haloed else { return false }

        // The anvil fades; the crab springs back, grumpy
        let cleared = await play(3) { progress, _ in
            [
                Prop(.sendButton, 76, 45, alpha: Double(1 - progress)),
                anvil(landY - 6 * progress, alpha: Double(1 - progress)),
            ]
        }
        guard cleared else { return false }
        eyes = .droopy
        pose(0.25) { sway = 0 }
        springBack()
        return await frame([], 0.45)
    }
}
