//
//  Story105_TokenGuillotine.swift
//  ClawNotch
//
//  #105 Token Limit Guillotine: the crab turns out to be made of token blocks; a counter fills
//  to "max tokens" and the blocks pop off and tumble like Jenga.
//

import SwiftUI

extension CrabStory {
    static let tokenGuillotine = CrabStory(
        id: "tokenGuillotine", number: 105, title: "Token Limit Guillotine",
        moods: [.processing], category: .community
    ) { await $0.tokenGuillotine() }
}

private extension CrabStage {
    func tokenGuillotine() async -> Bool {
        struct Piece {
            let x: CGFloat
            let y: CGFloat
            let w: CGFloat
            let h: Int
            let eye: Bool
            let launch: Int
            let vx: CGFloat
            let vy: CGFloat
            let spin: Double
        }
        // The crab as blocks: 3x2 body, pincers, legs. `launch` = frame at which a piece lets go.
        let pieces: [Piece] = [
            Piece(x: 33, y: 9.5, w: 17, h: 18, eye: false, launch: 0, vx: 1.5, vy: -11, spin: 40),
            Piece(x: 15, y: 9.5, w: 17, h: 18, eye: true, launch: 3, vx: -3.5, vy: -9, spin: -35),
            Piece(x: 51, y: 9.5, w: 17, h: 18, eye: true, launch: 6, vx: 3.5, vy: -9, spin: 35),
            Piece(x: 15, y: 29.5, w: 17, h: 18, eye: false, launch: 10, vx: -3, vy: -3, spin: -25),
            Piece(x: 33, y: 29.5, w: 17, h: 18, eye: false, launch: 9, vx: 0.6, vy: -4, spin: 15),
            Piece(x: 51, y: 29.5, w: 17, h: 18, eye: false, launch: 10, vx: 3, vy: -3, spin: 25),
            Piece(x: 3, y: 19.5, w: 6, h: 13, eye: false, launch: 9, vx: -2.5, vy: -2, spin: -45),
            Piece(x: 63, y: 19.5, w: 6, h: 13, eye: false, launch: 9, vx: 2.5, vy: -2, spin: 45),
            Piece(x: 9, y: 45.5, w: 6, h: 13, eye: false, launch: 11, vx: -2, vy: -3, spin: -60),
            Piece(x: 21, y: 45.5, w: 6, h: 13, eye: false, launch: 11, vx: -0.7, vy: -4, spin: 50),
            Piece(x: 45, y: 45.5, w: 6, h: 13, eye: false, launch: 11, vx: 0.7, vy: -4, spin: -50),
            Piece(x: 57, y: 45.5, w: 6, h: 13, eye: false, launch: 11, vx: 2, vy: -3, spin: 60),
        ]

        func scene(_ step: Int, alpha: Double = 1) -> [Prop] {
            var sprites: [Prop] = []
            for piece in pieces {
                var x = piece.x
                var y = piece.y
                var angle = 0.0
                let age = step - piece.launch
                if age > 0 {
                    // Ballistic flight until the piece reaches the floor, where it stays put
                    for tick in 1...age {
                        let time = CGFloat(tick)
                        let nextY = piece.y + piece.vy * time + 1.6 * time * time
                        if nextY >= 46 {
                            y = 46
                            break
                        }
                        x = piece.x + piece.vx * time
                        y = nextY
                        angle = piece.spin * Double(tick)
                    }
                }
                sprites.append(slab(x, y, w: piece.w, h: piece.h, tone: Tone.orange, angle: angle, alpha: alpha))
                if piece.eye {
                    let radians = angle * .pi / 180
                    let eyeX = x - 6.75 * CGFloat(sin(radians))
                    let eyeY = y + 6.75 * CGFloat(cos(radians))
                    sprites.append(slab(eyeX, eyeY, w: 6, h: 6, tone: Tone.black, angle: angle, alpha: alpha))
                }
            }
            return sprites
        }
        func meter(_ fill: CGFloat) -> [Prop] {
            [
                slab(33, -15, w: 46, h: 8, tone: Tone.steel),
                slab(12 + 21 * fill, -15, w: 42 * fill, h: 4, tone: fill >= 1 ? Tone.red : Tone.amber),
            ]
        }
        let seams = [
            slab(24, 19.5, w: 2, h: 39, tone: Tone.seam),
            slab(42, 19.5, w: 2, h: 39, tone: Tone.seam),
            slab(33, 19.5, w: 54, h: 2, tone: Tone.seam),
        ]

        // The crab turns out to be built of token blocks while a counter fills up
        guard await play(6, { progress, _ in seams + meter(progress) }) else { return false }
        eyes = .wide
        guard await frame(seams + meter(1) + [Prop(.bang, 66, -14, size: 0.9)], 0.25) else { return false }

        // Max tokens: the top blocks pop off one by one, then the rest comes down like Jenga
        ghosted = true
        guard await play(18, { _, index in scene(index) + meter(1) }) else { return false }

        // A white sparkle rolls away like a dropped coin
        let rolled = await play(7) { progress, _ in
            scene(18, alpha: Double(1 - progress))
                + [Prop(.star, mix(33, 92, progress), 45, size: 0.8, angle: Double(progress) * 540)]
        }
        guard rolled else { return false }

        // Reassembled
        scaleY = 0.35
        eyes = .open
        guard await frame([], 0.05) else { return false }
        springBack(0.35)
        return await frame([], 0.45)
    }
}
