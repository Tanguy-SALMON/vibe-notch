//
//  UsageBorder.swift
//  ClaudeIsland
//
//  Muted progress stroke that traces the notch's bottom edge to show 5-hour usage.
//

import SwiftUI

struct UsageBorder: View {
    let fraction: Double
    let shape: NotchShape

    var body: some View {
        ZStack {
            shape.stroke(Color.white.opacity(0.14), lineWidth: 1.5)
            shape.trim(from: 0, to: 1)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
                .mask(progressMask)
        }
        .animation(.spring(response: 1.2, dampingFraction: 1.0), value: fraction)
        .animation(.easeInOut(duration: 1.0), value: color)
        .allowsHitTesting(false)
    }

    /// Reveal the stroke left-to-right across the width, so it fills along the bottom edge.
    private var progressMask: some View {
        GeometryReader { geo in
            Rectangle()
                .frame(width: geo.size.width * fraction)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Claude orange, matching the processing spinner
    private var color: Color { Color(red: 0.85, green: 0.47, blue: 0.34) }
}
