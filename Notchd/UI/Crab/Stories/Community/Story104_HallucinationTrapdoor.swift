//
//  Story104_HallucinationTrapdoor.swift
//  Notchd
//
//  #104 Hallucination Trapdoor: the crab confidently steps onto a green "fact" tile; it flips
//  open (red underside) and the crab drops, pops back in a fake mustache, drops again.
//

import SwiftUI

extension CrabStory {
    static let hallucinationTrapdoor = CrabStory(
        id: "hallucinationTrapdoor", number: 104, title: "Hallucination Trapdoor",
        moods: [.idle], category: .community
    ) { await $0.hallucinationTrapdoor() }
}

private extension CrabStage {
    func hallucinationTrapdoor() async -> Bool {
        /// The "fact" tile; `open` 0...1 flips the lid up to show its red underside and the hole
        func tile(_ open: CGFloat, alpha: Double = 1) -> [Prop] {
            var sprites: [Prop] = []
            if open > 0 { sprites.append(Prop(.hole, 33, 56, length: 62 * min(open * 1.5, 1))) }
            let lid = Prop(
                .door, 4, 55,
                tint: open > 0.5 ? Tone.red : Tone.green,
                angle: Double(open) * -104,
                alpha: alpha,
                length: 58
            )
            sprites.append(lid)
            return sprites
        }
        func fall() {
            withAnimation(.easeIn(duration: 0.25)) { scaleY = 0.05; scaleX = 0.5; ghosted = true }
        }

        // Steps onto a solid green "fact" tile, very sure of itself
        eyes = .closed
        setArms(true)
        pose(0.15) { lift = -1.5 }
        guard await play(3, { progress, _ in tile(0, alpha: Double(progress)) }) else { return false }
        pose(0.1) { lift = 0 }
        guard await frame(tile(0), 0.3) else { return false }

        // The tile flips open: red underside, nothing below
        eyes = .wide
        guard await play(3, every: 0.07, { _, index in tile(CGFloat(index + 1) / 3) }) else { return false }
        legsMoving = true
        for step in 0..<2 {
            legPhase = step % 2 == 0 ? 0 : 2
            guard await pause(0.1) else { return false }
        }
        fall()
        guard await frame(tile(1), 0.4) else { return false }

        // Pops back up in a fake mustache
        legsMoving = false
        eyes = .open
        springBack(0.3)
        guard await frame(tile(1), 0.3) else { return false }
        let mustache = Prop(.mustache, 33, 27)
        guard await frame(tile(1) + [mustache], 0.6) else { return false }

        // ...and drops again; the mustache hangs in the air for a beat
        eyes = .wide
        fall()
        guard await frame(tile(1) + [mustache], 0.3) else { return false }
        let fluttered = await play(3) { progress, _ in
            tile(1) + [Prop(.mustache, 33, mix(27, 52, progress * progress), angle: Double(progress) * 50, alpha: Double(1 - progress * 0.6))]
        }
        guard fluttered else { return false }

        // The lid snaps shut: lights out
        setArms(false)
        guard await play(3, every: 0.07, { progress, _ in tile(1 - progress) }) else { return false }
        guard await frame(tile(0), 0.35) else { return false }

        // Back as if nothing happened
        eyes = .open
        withAnimation(.easeOut(duration: 0.3)) { scaleX = 1; scaleY = 1; ghosted = false }
        guard await play(3, { progress, _ in tile(0, alpha: Double(1 - progress)) }) else { return false }
        return await frame([], 0.15)
    }
}
