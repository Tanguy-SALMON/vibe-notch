//
//  Story001_CatBite.swift
//  Notchd
//
//  #1 Cat bite: a pixel cat nips the crab, who flinches.
//

import SwiftUI

extension CrabStory {
    static let catBite = CrabStory(
        id: "catBite", number: 1, title: "Cat bite",
        moods: [.alert], category: .tokens
    ) { await $0.catBite() }
}

private extension CrabStage {
    func catBite() async -> Bool {
        // The cat peeks in from the left
        guard await play(5, { progress, _ in [Prop(.cat, mix(-34, -10, progress), 22)] }) else { return false }
        eyes = .droopy
        guard await pause(0.35) else { return false }

        // Lunge and nip the left pincer
        guard await frame([Prop(.cat, -6, 21, v: 1)], 0.1) else { return false }
        eyes = .wide
        setArms(true)
        pose(0.08) { lift = -3; sway = 2.5; tilt = 10 }
        guard await frame([Prop(.cat, -5, 21, v: 1), Prop(.bang, 33, -13)], 0.3) else { return false }
        pose(0.15) { lift = 0 }

        // The crab trembles while the cat slinks away
        let slunk = await play(6) { progress, index in
            sway = index % 2 == 0 ? 2.5 : 1.5
            return [
                Prop(.cat, mix(-8, -36, progress), 22),
                Prop(.bang, 33, -13, alpha: Double(1 - progress)),
            ]
        }
        guard slunk else { return false }

        // Glares after it
        setArms(false)
        eyes = .droopy
        pose(0.25) { sway = 0; tilt = -4 }
        return await frame([], 0.5)
    }
}
