//
//  Story002_VoidDrop.swift
//  Notchd
//
//  #2 Void drop: the crab falls through a dark hole, shrinks, climbs back.
//

import SwiftUI

extension CrabStory {
    static let voidDrop = CrabStory(
        id: "voidDrop", number: 2, title: "Void drop",
        moods: [.idle], category: .tokens
    ) { await $0.voidDrop() }
}

private extension CrabStage {
    func voidDrop() async -> Bool {
        guard await play(5, { progress, _ in [Prop(.hole, 33, 51, length: mix(10, 74, progress))] }) else { return false }

        // Cartoon hang time: legs flail over nothing
        eyes = .wide
        setArms(true)
        legsMoving = true
        for step in 0..<3 {
            legPhase = step % 2 == 0 ? 0 : 2
            guard await pause(0.1) else { return false }
        }

        // Falls in: shrinks and fades
        withAnimation(.easeIn(duration: 0.45)) {
            scaleX = 0.1
            scaleY = 0.1
            luminance = 0
            lift = 3
        }
        guard await pause(0.5) else { return false }
        legsMoving = false
        guard await pause(0.5) else { return false }

        // Climbs back out, pincers first
        withAnimation(.easeOut(duration: 0.5)) {
            scaleX = 0.6
            scaleY = 0.45
            luminance = 1
            lift = 0
        }
        guard await pause(0.55) else { return false }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            scaleX = 1
            scaleY = 1
        }
        guard await pause(0.4) else { return false }
        setArms(false)
        eyes = .open
        return await play(4) { progress, _ in [Prop(.hole, 33, 51, length: mix(74, 6, progress))] }
    }
}
