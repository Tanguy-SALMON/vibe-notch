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
            shape.stroke(Color.white.opacity(0.14), lineWidth: 3.5)
            shape.trim(from: 0, to: 1)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .mask(progressMask)
        }
        .mask(belowTopEdge)
        .animation(.spring(response: 1.2, dampingFraction: 1.0), value: fraction)
        .animation(.easeInOut(duration: 1.0), value: color)
        .allowsHitTesting(false)
    }

    /// Hide only the flat top edge: the top corner curves, the sides and the bottom carry the border.
    private var belowTopEdge: some View {
        GeometryReader { geo in
            let cut: CGFloat = 4                              // the stroke is 3.5 pt wide, centred on the edge
            let corner = shape.topCornerRadius + 1            // the top curves keep their progress
            ZStack(alignment: .topLeading) {
                // everything below the top edge
                Rectangle()
                    .frame(width: geo.size.width, height: max(0, geo.size.height - cut))
                    .offset(y: cut)
                // the two top corner curves
                Rectangle()
                    .frame(width: corner, height: cut)
                Rectangle()
                    .frame(width: corner, height: cut)
                    .offset(x: geo.size.width - corner)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
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
