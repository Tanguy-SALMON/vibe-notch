//
//  Story013_TokenWind.swift
//  ClawNotch
//
//  #13 Wind tokens: tokens stream sideways, the crab leans into the gust.
//

import SwiftUI

extension CrabStory {
    static let tokenWind = CrabStory(
        id: "tokenWind", number: 13, title: "Wind tokens",
        moods: [.idle], category: .tokens
    ) { await $0.tokenWind() }
}

private extension CrabStage {
    func tokenWind() async -> Bool {
        let heading: CGFloat = Bool.random() ? 1 : -1
        let span = 66 + AnticsOverlay.padX * 2

        // Leans with the gust, squinting
        eyes = .droopy
        pose(0.3) { tilt = Double(10 * heading); sway = 2 * heading }

        let rows: [CGFloat] = [-18, 44, -8, 20, -20, 47, 4]
        let streaks: [CGFloat] = [-12, 32, 49]
        let blown = await play(26) { _, index in
            leftArmUp = index % 4 < 2
            rightArmUp = index % 4 >= 2
            var sprites: [Prop] = []
            for (token, y) in rows.enumerated() {
                let age = CGFloat(index) - CGFloat(token) * 2.5
                guard age >= 0 else { continue }
                let travelled = age * 15
                guard travelled < span + 20 else { continue }
                let x = heading > 0 ? -30 + travelled : 96 - travelled
                let bob = token % 2 == 0 ? CGFloat(index % 2) * 2 : 0
                sprites.append(Prop(.token, x, y + bob, size: 0.7, tint: token, v: token, angle: Double(age) * 40 * Double(heading)))
            }
            for (line, y) in streaks.enumerated() {
                let travelled = CGFloat((index * 26 + line * 45) % 130)
                let x = heading > 0 ? -24 + travelled : 90 - travelled
                sprites.append(Prop(.streak, x, y, alpha: 0.45, length: 14))
            }
            return sprites
        }
        guard blown else { return false }

        // Springs back upright
        setArms(false)
        eyes = .open
        withAnimation(.spring(response: 0.35, dampingFraction: 0.4)) { tilt = 0; sway = 0 }
        return await frame([], 0.5)
    }
}
