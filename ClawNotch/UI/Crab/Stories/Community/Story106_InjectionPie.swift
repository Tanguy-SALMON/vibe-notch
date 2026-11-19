//
//  Story106_InjectionPie.swift
//  ClawNotch
//
//  #106 Prompt Injection Pie: the crab reads a suspicious note; a pie flies out and hits it in
//  the face; it wobbles, spins, keels over and raises a tiny flag.
//

import SwiftUI

extension CrabStory {
    static let injectionPie = CrabStory(
        id: "injectionPie", number: 106, title: "Prompt Injection Pie",
        moods: [.alert], category: .community
    ) { await $0.injectionPie() }
}

private extension CrabStage {
    func injectionPie() async -> Bool {
        let note = Prop(.paper, -9, 51, v: 1)
        func splat(_ drip: Int, lean: Double = 0) -> Prop {
            Prop(.splat, 33 + CGFloat(lean) * 0.6 * motion, 17, v: drip)
        }

        // A suspicious note slides in; the crab leans over to read it
        eyes = .droopy
        guard await play(3, { progress, _ in [Prop(.paper, mix(-26, -9, progress), 51, v: 1)] }) else { return false }
        pose(0.2) { tilt = -7 }
        guard await frame([note], 0.35) else { return false }

        // A pie flies out of it
        eyes = .wide
        let thrown = await play(4, every: 0.07) { progress, _ in
            let (x, y) = arc(-9, 38, 33, 17, height: 10, progress)
            return [note, Prop(.pie, x, y, angle: Double(progress) * 200)]
        }
        guard thrown else { return false }

        // Right in the face
        eyes = .closed
        pose(0.08) { tilt = 9; sway = 1.5 }
        guard await frame([note, splat(0, lean: 9), Prop(.spark, 36, -2)], 0.15) else { return false }

        // Wobbles...
        for (index, angle) in [-9.0, 8, -5].enumerated() {
            pose(0.12) { tilt = angle; sway = 0 }
            guard await frame([splat(index, lean: angle)], 0.13) else { return false }
        }

        // ...spins...
        pose(0.08) { tilt = 0 }
        for flip in [CGFloat(-1), 1] {
            withAnimation(.easeInOut(duration: 0.16)) { scaleX = flip }
            guard await frame([splat(2)], 0.17) else { return false }
        }

        // ...and keels over, eyes crossed out
        let flat: CGFloat = 0.42
        let wide: CGFloat = 1.18
        pose(0.12) { scaleY = flat; scaleX = wide }
        let crumbs = [
            slab(-9, 50, w: 5, h: 4, tone: Tone.cream),
            slab(75, 50, w: 4, h: 3, tone: Tone.cream),
            slab(22, squashedY(0, flat) - 3, w: 4, h: 3, tone: Tone.cream),
        ]
        guard await frame(crumbs, 0.12) else { return false }
        let eyeY = squashedY(16, flat)
        let knockedOut = crumbs + [
            Prop(.xEye, squashedX(15, wide), eyeY, size: 0.9),
            Prop(.xEye, squashedX(51, wide), eyeY, size: 0.9),
        ]
        guard await frame(knockedOut, 0.3) else { return false }

        // A tiny flag pops out: "I have been instructed"
        let top = squashedY(0, flat)
        let raised = await play(3) { progress, _ in
            knockedOut + [Prop(.flag, 36, top, size: mix(0.3, 1, progress))]
        }
        guard raised else { return false }
        guard await frame(knockedOut + [Prop(.flag, 36, top)], 0.6) else { return false }

        eyes = .droopy
        springBack()
        return await frame([], 0.4)
    }
}
