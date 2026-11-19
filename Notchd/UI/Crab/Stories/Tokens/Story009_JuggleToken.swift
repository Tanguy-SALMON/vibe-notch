//
//  Story009_JuggleToken.swift
//  Notchd
//
//  #9 Play with token: the crab bounces and juggles one token.
//

import SwiftUI

extension CrabStory {
    static let juggleToken = CrabStory(
        id: "juggleToken", number: 9, title: "Play with token",
        moods: [.idle], category: .tokens
    ) { await $0.juggleToken() }
}

private extension CrabStage {
    func juggleToken() async -> Bool {
        // Tossed from pincer to pincer
        for toss in 0..<4 {
            let leftToRight = toss % 2 == 0
            leftArmUp = leftToRight
            rightArmUp = !leftToRight
            let fromX: CGFloat = leftToRight ? 3 : 63
            let tossed = await play(5) { progress, _ in
                let (x, y) = arc(fromX, -4, 66 - fromX, -4, height: 13, progress)
                return [Prop(.token, x, y, tint: 1, v: 2, angle: Double(progress) * 180)]
            }
            guard tossed else { return false }
        }

        // Header: bounces it off its head and lets it fly
        setArms(true)
        eyes = .closed
        let lobbed = await play(4) { progress, _ in
            let (x, y) = arc(3, -4, 33, -8, height: 10, progress)
            return [Prop(.token, x, y, tint: 1, v: 2, angle: Double(progress) * 90)]
        }
        guard lobbed else { return false }
        pose(0.06) { scaleY = 0.9; scaleX = 1.05 }
        guard await frame([Prop(.token, 33, -6, tint: 1, v: 2)], 0.1) else { return false }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { scaleY = 1; scaleX = 1 }
        return await play(5) { progress, _ in
            [Prop(.token, 33, mix(-8, -30, progress), tint: 1, v: 2, alpha: Double(1 - progress * 0.8))]
        }
    }
}
