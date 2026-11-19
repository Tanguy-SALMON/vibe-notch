//
//  Story107_ThermalSauna.swift
//  ClawNotch
//
//  #107 Thermal Throttle Sauna: the crab sits in a tiny wooden sauna with a rising thermometer,
//  fans itself, deflates and whistles away, leaving a sweating sparkle.
//

import SwiftUI

extension CrabStory {
    static let thermalSauna = CrabStory(
        id: "thermalSauna", number: 107, title: "Thermal Throttle Sauna",
        moods: [.processing], category: .community
    ) { await $0.thermalSauna() }
}

private extension CrabStage {
    func thermalSauna() async -> Bool {
        /// Wooden cabin + thermometer; `heat` 0...1 fills the red column
        func sauna(_ heat: CGFloat, alpha: Double = 1) -> [Prop] {
            let column = Int(4 + 16 * heat)
            return [
                slab(33, 58, w: 94, h: 6, tone: Tone.wood, alpha: alpha),
                slab(-13, 18, w: 4, h: 76, tone: Tone.wood, alpha: alpha),
                slab(79, 18, w: 4, h: 76, tone: Tone.wood, alpha: alpha),
                slab(33, -21, w: 96, h: 4, tone: Tone.wood, alpha: alpha),
                slab(71, 3, w: 5, h: 24, tone: Tone.white, alpha: alpha * 0.9),
                slab(71, 14 - CGFloat(column) / 2, w: 3, h: column, tone: Tone.red, alpha: alpha),
            ]
        }
        let star = Prop(.star, 33, 24, size: 0.9)

        // Settles onto the bench of a tiny sauna
        eyes = .droopy
        pose(0.3) { scaleY = 0.92; scaleX = 1.04; hue = -14 }
        guard await play(3, { progress, _ in sauna(0, alpha: Double(progress)) }) else { return false }

        // The temperature climbs; it fans itself with a cooling-fan sticker
        let fanned = await play(9) { progress, index in
            leftArmUp = index % 2 == 0
            var sprites = sauna(progress)
            sprites.append(Prop(.fanSticker, 3, index % 2 == 0 ? -4 : 6, size: 0.8, v: index, angle: index % 2 == 0 ? -20 : 15))
            let rise = CGFloat(index % 5) / 5
            sprites.append(Prop(.steam, 52, -2 - 16 * rise, alpha: Double(1 - rise)))
            sprites.append(Prop(.steam, 20, -6 - 12 * rise, alpha: Double(1 - rise) * 0.7))
            sprites.append(Prop(.drop, 57, 4 + CGFloat(index % 4) * 6))
            return sprites
        }
        guard fanned else { return false }

        // Deflates like a balloon...
        leftArmUp = false
        eyes = .closed
        pose(0.35) { scaleX = 0.4; scaleY = 0.35; hue = 0 }
        guard await frame(sauna(1), 0.35) else { return false }

        // ...and whistles away, leaving a white sparkle behind
        withAnimation(.easeIn(duration: 0.8)) { lift = -9 }
        let floated = await play(8) { _, index in
            tilt = index % 2 == 0 ? 18 : -18
            sway = index % 2 == 0 ? 1.5 : -1.5
            if index == 5 { withAnimation(.easeIn(duration: 0.3)) { ghosted = true } }
            return sauna(1) + [star]
        }
        guard floated else { return false }

        // The sparkle stays, sweating
        let sweated = await play(6) { progress, index in
            sauna(1, alpha: Double(1 - progress * 0.6)) + [
                star,
                Prop(.drop, 42, 22 + CGFloat(index % 3) * 5),
                Prop(.drop, 24, 25 + CGFloat((index + 1) % 3) * 5),
            ]
        }
        guard sweated else { return false }

        // Re-inflates where it sat
        lift = 0
        tilt = 0
        sway = 0
        eyes = .open
        guard await frame(sauna(1, alpha: 0.4) + [star], 0.05) else { return false }
        springBack(0.4)
        let cooled = await play(3) { progress, _ in
            sauna(1, alpha: 0.4 * Double(1 - progress)) + [Prop(.star, 33, 24, size: 0.9, alpha: Double(1 - progress))]
        }
        guard cooled else { return false }
        return await frame([], 0.3)
    }
}
