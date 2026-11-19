//
//  Story006_EatTokens.swift
//  Notchd
//
//  #6 Eat tokens: the crab munches tokens flying in.
//

import SwiftUI

extension CrabStory {
    static let eatTokens = CrabStory(
        id: "eatTokens", number: 6, title: "Eat tokens",
        moods: [.idle], category: .tokens
    ) { await $0.eatTokens() }
}

private extension CrabStage {
    func eatTokens() async -> Bool {
        for bite in 0..<3 {
            let fromX: CGFloat = bite % 2 == 0 ? -28 : 94
            let flew = await play(4) { progress, _ in
                let (x, y) = arc(fromX, 18, 33, 27, height: 16, progress)
                return [
                    Prop(.mouth, 33, 28),
                    Prop(.token, x, y, size: mix(1, 0.55, progress), tint: bite + 1, v: bite),
                ]
            }
            guard flew else { return false }

            // Chomp
            pose(0.06) { scaleY = 0.9; scaleX = 1.06 }
            guard await frame([Prop(.mouth, 33, 29, v: 1)], 0.12) else { return false }
            pose(0.06) { scaleY = 1; scaleX = 1 + 0.03 * CGFloat(bite + 1) }
            guard await frame([Prop(.mouth, 33, 28, v: 1)], 0.1) else { return false }
        }

        // Full belly, tiny burp
        eyes = .closed
        pose(0.2) { scaleX = 1.12; scaleY = 1.04 }
        guard await frame([], 0.45) else { return false }
        return await play(4) { progress, _ in
            [Prop(.bit, 33 + 8 * progress, mix(14, -12, progress), size: 0.8, tint: 1, alpha: Double(1 - progress))]
        }
    }
}
