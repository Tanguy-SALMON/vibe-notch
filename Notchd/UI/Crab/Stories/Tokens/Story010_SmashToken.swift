//
//  Story010_SmashToken.swift
//  Notchd
//
//  #10 Smash token: the crab body-slams a token, which cracks into pieces.
//

import SwiftUI

extension CrabStory {
    static let smashToken = CrabStory(
        id: "smashToken", number: 10, title: "Smash token",
        moods: [.waiting], category: .tokens
    ) { await $0.smashToken() }
}

private extension CrabStage {
    func smashToken() async -> Bool {
        let side: CGFloat = Bool.random() ? 1 : -1
        let tokenX: CGFloat = side > 0 ? 75 : -9

        guard await play(3, { progress, _ in [Prop(.token, tokenX, mix(-30, 45, progress * progress), tint: 3)] }) else { return false }
        eyes = .wide
        guard await pause(0.3) else { return false }

        // Leaps...
        setArms(true)
        pose(0.15) { lift = -6; scaleY = 1.1; scaleX = 0.94 }
        guard await pause(0.18) else { return false }

        // ...and body-slams it
        setArms(false)
        withAnimation(.easeIn(duration: 0.08)) {
            lift = 0
            sway = 3 * side
            tilt = Double(14 * side)
            scaleY = 0.85
            scaleX = 1.1
        }
        guard await pause(0.08) else { return false }
        let cracked = [Prop(.token, tokenX, 45, tint: 3), Prop(.crack, tokenX, 45), Prop(.spark, tokenX - 6 * side, 36)]
        guard await frame(cracked, 0.15) else { return false }

        // Shards everywhere
        pose(0.2) { sway = 0; tilt = 0; scaleX = 1; scaleY = 1 }
        eyes = .closed
        let directions: [(CGFloat, CGFloat)] = [(-14, -26), (-6, -38), (4, -30), (12, -20), (-18, -8), (9, -42)]
        let shattered = await play(6) { progress, _ in
            directions.enumerated().map { index, direction in
                Prop(
                    .bit,
                    tokenX + direction.0 * progress,
                    45 + direction.1 * progress + 22 * progress * progress,
                    size: index % 2 == 0 ? 1 : 0.7,
                    tint: 3,
                    angle: Double(progress) * 200 + Double(index) * 40,
                    alpha: Double(1 - progress * progress)
                )
            }
        }
        guard shattered else { return false }
        return await frame([], 0.4)
    }
}
