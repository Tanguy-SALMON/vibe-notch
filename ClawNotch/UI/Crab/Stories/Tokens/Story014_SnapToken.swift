//
//  Story014_SnapToken.swift
//  ClawNotch
//
//  #14 Break token: the crab snaps a token in two.
//

import SwiftUI

extension CrabStory {
    static let snapToken = CrabStory(
        id: "snapToken", number: 14, title: "Break token",
        moods: [.waiting], category: .tokens
    ) { await $0.snapToken() }
}

private extension CrabStage {
    func snapToken() async -> Bool {
        // Catches a token overhead
        setArms(true)
        guard await play(3, { progress, _ in [Prop(.token, 33, mix(-30, -10, progress), size: 1.15, tint: 2, v: 1)] }) else { return false }
        guard await pause(0.3) else { return false }

        // Strains...
        eyes = .closed
        for step in 0..<5 {
            sway = step % 2 == 0 ? 0.6 : -0.6
            var sprites = [Prop(.token, 33, -10, size: 1.15, tint: 2, v: 1)]
            if step >= 3 { sprites.append(Prop(.crack, 33, -10, size: 1.15)) }
            guard await frame(sprites, 0.1) else { return false }
        }

        // ...snap!
        sway = 0
        eyes = .wide
        let snapped = [
            Prop(.halfLeft, 29, -10, size: 1.15, tint: 2),
            Prop(.halfRight, 37, -10, size: 1.15, tint: 2),
            Prop(.spark, 33, -10),
        ]
        guard await frame(snapped, 0.12) else { return false }

        // The halves tumble down either side
        let fell = await play(7) { progress, _ in
            let (leftX, leftY) = arc(29, -10, -9, 46, height: 10, progress)
            let (rightX, rightY) = arc(37, -10, 75, 46, height: 10, progress)
            let fade = progress > 0.7 ? Double((1 - progress) / 0.3) * 0.7 + 0.3 : 1
            return [
                Prop(.halfLeft, leftX, leftY, size: 1.15, tint: 2, angle: Double(progress) * -140, alpha: fade),
                Prop(.halfRight, rightX, rightY, size: 1.15, tint: 2, angle: Double(progress) * 140, alpha: fade),
            ]
        }
        guard fell else { return false }

        // Shrug
        setArms(false)
        eyes = .droopy
        return await frame([], 0.45)
    }
}
