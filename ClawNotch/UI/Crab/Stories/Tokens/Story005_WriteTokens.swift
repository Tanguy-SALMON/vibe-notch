//
//  Story005_WriteTokens.swift
//  ClawNotch
//
//  #5 Write tokens: the crab scribbles little token glyphs.
//

import SwiftUI

extension CrabStory {
    static let writeTokens = CrabStory(
        id: "writeTokens", number: 5, title: "Write tokens",
        moods: [.processing], category: .tokens
    ) { await $0.writeTokens() }
}

private extension CrabStage {
    func writeTokens() async -> Bool {
        let columns: [CGFloat] = [4, 23, 42, 61]
        var written: [Prop] = []
        guard await pause(0.2) else { return false }

        for (index, x) in columns.enumerated() {
            for stroke in 0..<3 {
                rightArmUp = stroke % 2 == 0
                let growing = Prop(
                    .token, x, -14,
                    size: 0.4 + 0.3 * CGFloat(stroke),
                    tint: index, v: index,
                    alpha: 0.5 + 0.25 * Double(stroke)
                )
                let pencil = Prop(.pencil, x + (stroke % 2 == 0 ? 4 : -2), stroke % 2 == 0 ? -15 : -9)
                guard await frame(written + [growing, pencil], 0.1) else { return false }
            }
            written.append(Prop(.token, x, -14, tint: index, v: index))
        }

        // Proud of the paragraph
        rightArmUp = false
        eyes = .closed
        pose(0.15) { scaleY = 1.05 }
        guard await frame(written, 0.55) else { return false }
        return await play(4) { progress, _ in
            written.map { Prop(.token, $0.x, -14 - 9 * progress, tint: $0.tint, v: $0.v, alpha: Double(1 - progress)) }
        }
    }
}
