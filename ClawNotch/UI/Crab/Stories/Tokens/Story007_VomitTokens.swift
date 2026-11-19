//
//  Story007_VomitTokens.swift
//  ClawNotch
//
//  #7 Vomit tokens: a cartoon spurt of small squares.
//

import SwiftUI

extension CrabStory {
    static let vomitTokens = CrabStory(
        id: "vomitTokens", number: 7, title: "Vomit tokens",
        moods: [.idle], category: .tokens
    ) { await $0.vomitTokens() }
}

private extension CrabStage {
    func vomitTokens() async -> Bool {
        // Turns green and wobbles
        eyes = .droopy
        withAnimation(.easeInOut(duration: 0.5)) { hue = 70 }
        for angle in [-5.0, 5, -5] {
            pose(0.15) { tilt = angle }
            guard await pause(0.16) else { return false }
        }

        // Cheeks bulge...
        eyes = .closed
        pose(0.1) { tilt = 0; scaleX = 1.1 }
        guard await pause(0.3) else { return false }

        // ...and out they come
        eyes = .wide
        pose(0.06) { scaleX = 0.95; lift = -1 }
        let reach: [CGFloat] = [-30, 24, -16, 34, -38, 12, -24]
        let spurted = await play(11) { _, index in
            var sprites = [Prop(.mouth, 33, 28)]
            for (bit, distance) in reach.enumerated() {
                let age = CGFloat(index) - CGFloat(bit) * 0.7
                guard age >= 0, age <= 6 else { continue }
                let flight = age / 6
                let x = 33 + distance * flight
                let y = 28 + 20 * flight - 60 * flight * (1 - flight)
                let fade = flight > 0.75 ? Double((1 - flight) * 4) : 1
                sprites.append(Prop(.bit, x, y, tint: bit, angle: Double(age) * 30, alpha: fade))
            }
            return sprites
        }
        guard spurted else { return false }

        // Relief
        eyes = .closed
        withAnimation(.easeInOut(duration: 0.4)) { hue = 0; scaleX = 1; lift = 0 }
        return await frame([Prop(.mouth, 33, 29, v: 1)], 0.5)
    }
}
