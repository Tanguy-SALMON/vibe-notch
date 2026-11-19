//
//  Story100_ContextShutdown.swift
//  Notchd
//
//  #100 Context Window Shutdown: the crab types happily; a "context window" pane comes down
//  like a guillotine and squashes it into an orange pancake.
//

import SwiftUI

extension CrabStory {
    static let contextShutdown = CrabStory(
        id: "contextShutdown", number: 100, title: "Context Window Shutdown",
        moods: [.alert], category: .community
    ) { await $0.contextShutdown() }
}

private extension CrabStage {
    func contextShutdown() async -> Bool {
        func pane(_ bottom: CGFloat, alpha: Double = 1) -> Prop {
            Prop(.pane, 33, bottom, v: 44, alpha: alpha, length: 78)
        }
        func text(_ count: Int) -> [Prop] {
            (0..<count).map { slab(8 + CGFloat($0) * 10, -9, w: 7, h: 3, tone: Tone.white, alpha: 0.85) }
        }

        // Types away happily: pincers drum, a line of text grows overhead
        let typed = await play(6) { _, index in
            leftArmUp = index % 2 == 0
            rightArmUp = index % 2 == 1
            return text(index + 1)
        }
        guard typed else { return false }

        // The context window looms in from above
        setArms(false)
        eyes = .wide
        guard await play(3, { progress, _ in text(6) + [pane(mix(-24, -15, progress))] }) else { return false }
        guard await pause(0.25) else { return false }

        // ...and comes down like a guillotine: orange pancake
        let flat: CGFloat = 0.2
        let rest = squashedY(0, flat)
        eyes = .closed
        withAnimation(.easeIn(duration: 0.1)) { scaleY = flat; scaleX = 1.3 }
        guard await play(2, every: 0.05, { progress, _ in [pane(mix(-4, rest, progress))] }) else { return false }
        guard await frame([pane(rest), Prop(.spark, -8, 47, size: 0.8), Prop(.spark, 74, 47, size: 0.8)], 0.15) else { return false }

        // Powered down
        pose(0.5) { luminance = 0.4 }
        guard await frame([pane(rest)], 0.65) else { return false }

        // The pane lifts away; the crab pops back, unimpressed
        let lifted = await play(4) { progress, _ in [pane(mix(rest, -8, progress), alpha: Double(1 - progress))] }
        guard lifted else { return false }
        eyes = .droopy
        pose(0.2) { luminance = 1 }
        springBack()
        return await frame([], 0.5)
    }
}
