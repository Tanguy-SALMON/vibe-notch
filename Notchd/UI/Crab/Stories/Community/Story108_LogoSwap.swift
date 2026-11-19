//
//  Story108_LogoSwap.swift
//  Notchd
//
//  #108 Logo Swap Ambush: the crab walks past a mirror; the reflection is a generic grey
//  chat-bot bubble; they wave; the reflection yanks the crab in; a tiny ghost floats out.
//

import SwiftUI

extension CrabStory {
    static let logoSwap = CrabStory(
        id: "logoSwap", number: 108, title: "Logo Swap Ambush",
        moods: [.idle], category: .community
    ) { await $0.logoSwap() }
}

private extension CrabStage {
    func logoSwap() async -> Bool {
        let mirrorX: CGFloat = 76
        func mirror(_ alpha: Double = 1, shake: CGFloat = 0) -> Prop {
            Prop(.mirror, mirrorX + shake, 53, v: 46, alpha: alpha, length: 22)
        }
        func bot(_ pose: Int, reach: CGFloat = 0, alpha: Double = 1) -> Prop {
            Prop(.bot, mirrorX, 30, size: 0.75, v: pose, alpha: alpha, length: reach)
        }

        // Strolls past a mirror; the reflection is a grey chat-bot bubble
        legsMoving = true
        pose(0.4) { sway = 1 }
        let strolled = await play(4) { progress, index in
            legPhase = index % 2 == 0 ? 0 : 2
            return [mirror(Double(progress)), bot(0, alpha: Double(progress))]
        }
        guard strolled else { return false }

        // Double take
        legsMoving = false
        eyes = .wide
        guard await frame([mirror(), bot(0)], 0.4) else { return false }

        // They wave at each other
        eyes = .open
        for beat in 0..<4 {
            rightArmUp = beat % 2 == 0
            guard await frame([mirror(), bot(beat % 2 == 0 ? 1 : 0)], 0.15) else { return false }
        }

        // The reflection grabs the crab and yanks it into the mirror
        eyes = .wide
        guard await play(2, every: 0.08, { progress, _ in [mirror(), bot(2, reach: mix(8, 18, progress))] }) else { return false }
        withAnimation(.easeIn(duration: 0.25)) {
            sway = 10
            lift = -3
            scaleX = 0.3
            scaleY = 0.3
            ghosted = true
        }
        guard await frame([mirror(), bot(2, reach: 18)], 0.1) else { return false }
        guard await frame([mirror(), bot(2, reach: 8)], 0.15) else { return false }
        for shake in [CGFloat(2), -2, 1] {
            guard await frame([mirror(shake: shake), Prop(.spark, mirrorX, 28, size: 0.8)], 0.08) else { return false }
        }

        // Out floats a tiny orange ghost with a sparkle halo
        rightArmUp = false
        let haunted = await play(9) { progress, index in
            let (x, y) = arc(mirrorX, 28, 33, 22, height: 14, progress)
            let bob: CGFloat = index % 2 == 0 ? 0 : 1.5
            let size = mix(0.6, 1, progress)
            return [
                mirror(), bot(0),
                Prop(.ghost, x, y + bob, size: size, alpha: 0.9),
                Prop(.star, x, y + bob - 17 * size, size: 0.55, angle: Double(index) * 30),
            ]
        }
        guard haunted else { return false }

        // The ghost settles back into a crab
        sway = 0
        lift = 0
        scaleX = 0.6
        scaleY = 0.6
        eyes = .open
        guard await frame([mirror(), bot(0), Prop(.ghost, 33, 22, alpha: 0.9), Prop(.star, 33, 5, size: 0.55)], 0.05) else { return false }
        springBack(0.35)
        let faded = await play(3) { progress, _ in
            let fade = Double(1 - progress)
            return [mirror(fade), bot(0, alpha: fade), Prop(.ghost, 33, 22, alpha: fade * 0.9), Prop(.star, 33, 5 - 8 * progress, size: 0.55, alpha: fade)]
        }
        guard faded else { return false }
        return await frame([], 0.3)
    }
}
