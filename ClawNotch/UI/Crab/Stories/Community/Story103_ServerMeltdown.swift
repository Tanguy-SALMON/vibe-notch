//
//  Story103_ServerMeltdown.swift
//  ClawNotch
//
//  #103 Overloaded Server Meltdown: racks blink red, the crab sweats, melts into an orange
//  puddle that gives a thumbs-up, then evaporates and re-forms.
//

import SwiftUI

extension CrabStory {
    static let serverMeltdown = CrabStory(
        id: "serverMeltdown", number: 103, title: "Server Meltdown",
        moods: [.alert], category: .community
    ) { await $0.serverMeltdown() }
}

private extension CrabStage {
    func serverMeltdown() async -> Bool {
        func racks(_ state: Int, alpha: Double = 1) -> [Prop] {
            [Prop(.rack, -11, 35, v: state, alpha: alpha), Prop(.rack, 77, 35, v: state, alpha: alpha)]
        }
        func puddle(_ width: CGFloat, alpha: Double = 1) -> Prop {
            Prop(.blob, 33, 49, tint: Tone.orange, v: 8, alpha: alpha, length: width)
        }
        func star(_ step: Int, alpha: Double = 1) -> Prop {
            Prop(.star, 33, step % 4 < 2 ? 17 : 19, alpha: alpha)
        }

        // Racks blink red; the crab sweats and fans itself with a sheet of paper
        eyes = .droopy
        pose(0.8) { hue = -14 }
        let sweated = await play(10) { _, index in
            rightArmUp = index % 2 == 0
            var sprites = racks(index % 2 == 0 ? 1 : 2)
            sprites.append(Prop(.paper, 63, 6, angle: index % 2 == 0 ? -28 : 24))
            let fall = CGFloat(index % 5) * 5
            sprites.append(Prop(.drop, 3, 4 + fall, alpha: Double(1 - fall / 28)))
            if index >= 2 {
                let second = CGFloat((index - 2) % 5) * 5
                sprites.append(Prop(.drop, 35, 3 + second, alpha: Double(1 - second / 28)))
            }
            return sprites
        }
        guard sweated else { return false }

        // Melts down into a puddle, leaving a white sparkle floating
        rightArmUp = false
        eyes = .closed
        withAnimation(.easeIn(duration: 0.35)) { scaleY = 0.18; scaleX = 1.25; hue = 0 }
        guard await frame(racks(1), 0.35) else { return false }
        withAnimation(.easeOut(duration: 0.12)) { ghosted = true }
        let melted = await play(4) { progress, index in
            racks(index % 2 == 0 ? 2 : 1) + [puddle(mix(50, 76, progress)), star(index)]
        }
        guard melted else { return false }

        // The puddle gives a thumbs-up
        let thumbed = await play(6) { progress, index in
            let rise = min(progress * 2.5, 1)
            var sprites = racks(0) + [puddle(76)]
            sprites.append(slab(40, 49 - 4 * rise, w: 5, h: 8, tone: Tone.orange))
            sprites.append(slab(40, 46 - 6 * rise, w: 9, h: 8, tone: Tone.orange))
            if rise >= 1 { sprites.append(slab(37, 33.5, w: 3, h: 6, tone: Tone.orange)) }
            sprites.append(star(index))
            return sprites
        }
        guard thumbed else { return false }

        // ...then evaporates
        let evaporated = await play(5) { progress, index in
            let fade = Double(1 - progress)
            return racks(0, alpha: fade) + [
                puddle(mix(76, 40, progress), alpha: fade),
                Prop(.steam, 18, 40 - 22 * progress, alpha: fade),
                Prop(.steam, 48, 44 - 24 * progress, alpha: fade),
                star(index),
            ]
        }
        guard evaporated else { return false }

        // The crab re-forms under its sparkle
        eyes = .open
        springBack(0.4)
        let reformed = await play(3) { progress, _ in
            [Prop(.star, 33, mix(17, -10, progress), alpha: Double(1 - progress))]
        }
        guard reformed else { return false }
        return await frame([], 0.3)
    }
}
