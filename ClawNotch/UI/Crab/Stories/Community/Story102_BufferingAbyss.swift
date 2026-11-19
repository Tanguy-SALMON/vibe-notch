//
//  Story102_BufferingAbyss.swift
//  ClawNotch
//
//  #102 Buffering Abyss: the crab trots on a loading bar that is really a treadmill running
//  backwards, and slides into a spinning "loading" ring.
//

import SwiftUI

extension CrabStory {
    static let bufferingAbyss = CrabStory(
        id: "bufferingAbyss", number: 102, title: "Buffering Abyss",
        moods: [.processing], category: .community
    ) { await $0.bufferingAbyss() }
}

private extension CrabStage {
    func bufferingAbyss() async -> Bool {
        let small: CGFloat = 0.3
        let slide: CGFloat = -11
        let ringX = 33 + units(slide)
        let ringY = 52 - 26 * applied(small)
        let diameter = 66 * applied(small) + 12

        func bar(_ step: Int, alpha: Double = 1) -> [Prop] {
            var sprites = [slab(33, 58, w: 78, h: 7, tone: Tone.steel, alpha: alpha)]
            for segment in 0..<4 {
                // The filled chunks travel the wrong way
                let x = 68 - CGFloat((step * 6 + segment * 19) % 72)
                sprites.append(slab(x, 58, w: 8, h: 4, tone: Tone.blue, alpha: alpha))
            }
            return sprites
        }
        func ring(_ step: Int, alpha: Double = 1) -> Prop {
            Prop(.ring, ringX, ringY, tint: Tone.pale, angle: Double(step) * 45, alpha: alpha, length: diameter)
        }

        // Trots along a loading bar...
        legsMoving = true
        let trotted = await play(7) { _, index in
            legPhase = index % 2 == 0 ? 0 : 2
            return bar(index)
        }
        guard trotted else { return false }

        // ...which is a treadmill running backwards, straight into a spinning void
        eyes = .wide
        withAnimation(.easeIn(duration: 0.9)) { sway = slide; scaleX = small; scaleY = small }
        let dragged = await play(9) { progress, index in
            legPhase = index % 2 == 0 ? 0 : 2
            return bar(7 + index) + [ring(index, alpha: Double(min(progress * 2, 1)))]
        }
        guard dragged else { return false }

        // Final frame: a tiny crab waving from inside the buffering ring
        legsMoving = false
        eyes = .open
        let waved = await play(8) { progress, index in
            setArms(index % 4 < 2)
            return bar(16, alpha: Double(1 - progress)) + [ring(9 + index)]
        }
        guard waved else { return false }

        setArms(false)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { sway = 0; scaleX = 1; scaleY = 1 }
        guard await play(4, { progress, index in [ring(17 + index, alpha: Double(1 - progress))] }) else { return false }
        return await frame([], 0.25)
    }
}
