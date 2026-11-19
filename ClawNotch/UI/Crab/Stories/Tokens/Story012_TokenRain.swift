//
//  Story012_TokenRain.swift
//  ClawNotch
//
//  #12 Rain tokens: tokens fall, the crab holds up its pincers.
//

import SwiftUI

extension CrabStory {
    static let tokenRain = CrabStory(
        id: "tokenRain", number: 12, title: "Rain tokens",
        moods: [.idle], category: .tokens
    ) { await $0.tokenRain() }
}

private extension CrabStage {
    func tokenRain() async -> Bool {
        eyes = .wide
        setArms(true)
        guard await pause(0.3) else { return false }
        eyes = .closed

        let columns: [CGFloat] = [-12, 14, 40, 76, 2, 52, 26, 82, -6, 62]
        let rained = await play(28) { _, index in
            // Flinches a little under the downpour
            if index % 6 == 0 { scaleY = 0.95 } else if index % 6 == 3 { scaleY = 1 }
            var sprites: [Prop] = []
            for (drop, x) in columns.enumerated() {
                let age = index - drop * 2
                guard age >= 0 else { continue }
                let y = -30 + CGFloat(age) * 10
                // Drops over the crab bounce off its shell; the others reach the floor
                let ground: CGFloat = (x > 0 && x < 66) ? -6 : 47
                if y <= ground {
                    sprites.append(Prop(.token, x, y, size: 0.6, tint: drop, v: drop))
                } else if y <= ground + 20 {
                    let splash = (y - ground) / 20
                    let hop = ground - 16 * splash * (1 - splash)
                    sprites.append(Prop(.bit, x - 2 - 7 * splash, hop, size: 0.7, tint: drop, alpha: Double(1 - splash)))
                    sprites.append(Prop(.bit, x + 2 + 7 * splash, hop, size: 0.7, tint: drop, alpha: Double(1 - splash)))
                }
            }
            return sprites
        }
        guard rained else { return false }

        // Peeks out once it stops
        scaleY = 1
        eyes = .open
        guard await frame([], 0.25) else { return false }
        setArms(false)
        return await pause(0.3)
    }
}
