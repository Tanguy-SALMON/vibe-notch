//
//  Story109_CtrlZ.swift
//  Notchd
//
//  #109 Ctrl+Z Undeath: the crab trips over an "API" cable, falls flat and flatlines; a giant
//  hand presses an Undo key; the crab un-flattens... and immediately trips again.
//

import SwiftUI

extension CrabStory {
    static let ctrlZ = CrabStory(
        id: "ctrlZ", number: 109, title: "Ctrl+Z Undeath",
        moods: [.waiting], category: .community
    ) { await $0.ctrlZ() }
}

private extension CrabStage {
    func ctrlZ() async -> Bool {
        let flat: CGFloat = 0.3
        func cable(_ snagged: Bool = false, alpha: Double = 1) -> Prop {
            Prop(.cable, -18, 51, v: snagged ? 1 : 0, alpha: alpha, length: 100)
        }
        /// Walks into the cable and goes down flat
        func trip() async -> Bool {
            legsMoving = true
            eyes = .open
            pose(0.3) { sway = 1.5 }
            let walked = await play(3) { _, index in
                legPhase = index % 2 == 0 ? 0 : 2
                return [cable()]
            }
            guard walked else { return false }
            eyes = .wide
            setArms(true)
            pose(0.1) { tilt = 24; lift = -1.5 }
            guard await frame([cable(true), Prop(.bang, 28, -14)], 0.2) else { return false }
            legsMoving = false
            eyes = .closed
            withAnimation(.easeIn(duration: 0.08)) { tilt = 0; lift = 0; scaleY = flat; scaleX = 1.2 }
            return await frame([cable(), Prop(.spark, 74, 44, size: 0.8)], 0.15)
        }

        guard await play(2, { progress, _ in [cable(alpha: Double(progress))] }) else { return false }
        guard await trip() else { return false }

        // Flatlines
        let lineY = squashedY(0, flat) - 8
        let keyY = lineY - 20
        func pulse(_ shape: Int, alpha: Double = 1) -> Prop { Prop(.pulse, 8, lineY, v: shape, alpha: alpha, length: 50) }
        func key(_ pressed: Bool, alpha: Double = 1) -> Prop { Prop(.key, 33, keyY, size: 1.2, v: pressed ? 1 : 0, alpha: alpha) }
        guard await frame([cable(), pulse(0)], 0.15) else { return false }
        guard await frame([cable(), pulse(2)], 0.15) else { return false }
        guard await frame([cable(), pulse(1)], 0.35) else { return false }

        // A giant hand comes down and presses Undo
        let reached = await play(4) { progress, _ in
            [cable(), pulse(1), key(false), Prop(.hand, 33, mix(keyY - 30, keyY - 9, progress))]
        }
        guard reached else { return false }
        let pressed = [cable(), pulse(1), key(true), Prop(.hand, 33, keyY - 6), Prop(.spark, 47, keyY - 5, size: 0.7)]
        guard await frame(pressed, 0.2) else { return false }

        // The crab un-flattens and blinks
        setArms(false)
        withAnimation(.easeInOut(duration: 0.35)) { scaleX = 1; scaleY = 1; sway = 0 }
        let rewound = await play(4) { progress, index in
            let fade = Double(1 - progress)
            return [
                cable(),
                pulse(index % 2 == 0 ? 0 : 2, alpha: fade),
                key(false, alpha: fade),
                Prop(.hand, 33, mix(keyY - 9, keyY - 30, progress), alpha: fade),
            ]
        }
        guard rewound else { return false }
        eyes = .open
        antics.sprites = [cable()]
        await blink()
        guard await frame([cable()], 0.2) else { return false }

        // ...and immediately trips again
        guard await trip() else { return false }
        return await frame([cable()], 0.3)
    }
}
