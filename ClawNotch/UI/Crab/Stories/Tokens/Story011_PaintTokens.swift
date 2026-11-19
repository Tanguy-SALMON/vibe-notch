//
//  Story011_PaintTokens.swift
//  ClawNotch
//
//  #11 Paint tokens: a brush recolours token squares.
//

import SwiftUI

extension CrabStory {
    static let paintTokens = CrabStory(
        id: "paintTokens", number: 11, title: "Paint tokens",
        moods: [.processing], category: .tokens
    ) { await $0.paintTokens() }
}

private extension CrabStage {
    func paintTokens() async -> Bool {
        let columns: [CGFloat] = [10, 33, 56]
        let paints = [0, 2, 4]
        var tints = [5, 5, 5]

        func row(alpha: Double = 1, raise: CGFloat = 0) -> [Prop] {
            columns.enumerated().map { index, x in
                Prop(.token, x, -13 - raise, tint: tints[index], v: index, alpha: alpha)
            }
        }

        // Three blank tokens appear
        guard await play(3, { progress, _ in row(alpha: Double(0.3 + 0.7 * progress)) }) else { return false }

        for (index, x) in columns.enumerated() {
            for stroke in 0..<4 {
                rightArmUp = stroke % 2 == 0
                if stroke == 2 { tints[index] = paints[index] }
                let brush = Prop(.brush, x - 8 + 5 * CGFloat(stroke), stroke % 2 == 0 ? -15 : -10, tint: paints[index])
                guard await frame(row() + [brush], 0.1) else { return false }
            }
        }

        // Admires the work
        setArms(true)
        eyes = .closed
        guard await frame(row(), 0.55) else { return false }
        return await play(4) { progress, _ in row(alpha: Double(1 - progress), raise: 8 * progress) }
    }
}
