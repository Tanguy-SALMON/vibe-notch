//
//  NotchHeaderView.swift
//  ClawNotch
//
//  Header bar for the dynamic island
//

import Combine
import SwiftUI

/// Animation state of the crab icon, derived from session activity
enum CrabMood: Equatable {
    case idle        // Nothing happening: occasional blink
    case processing  // Working: scuttling legs with a tiny side-step
    case waiting     // Finished, waiting for input: small hop + pincer wave on entry, then idle blinks
    case alert       // Permission pending: gentle wiggle every few seconds
}

struct ClaudeCrabIcon: View {
    let size: CGFloat
    let color: Color
    var animateLegs: Bool = false
    var mood: CrabMood

    @AppStorage("muteNotchAnimation") private var muted = false

    @State private var legPhase: Int = 0
    @State private var eyesClosed = false
    @State private var armsUp = false
    @State private var lift: CGFloat = 0   // Vertical offset in points (negative = up)
    @State private var tilt: Double = 0    // Rotation in degrees
    @State private var lastMood: CrabMood?

    init(
        size: CGFloat = 16,
        color: Color = Color(red: 0.85, green: 0.47, blue: 0.34),
        animateLegs: Bool = false,
        mood: CrabMood? = nil
    ) {
        self.size = size
        self.color = color
        self.animateLegs = animateLegs
        self.mood = mood ?? (animateLegs ? .processing : .idle)
    }

    private var isScuttling: Bool { mood == .processing && !muted }

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 52.0  // Original viewBox height is 52
            let xOffset = (canvasSize.width - 66 * scale) / 2
            let transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0)

            func fill(_ rect: CGRect, _ fillColor: Color) {
                context.fill(Path(rect).applying(transform), with: .color(fillColor))
            }

            // Antennas / pincers (raised during the celebratory wave)
            let antennaY: CGFloat = armsUp ? 5 : 13
            fill(CGRect(x: 0, y: antennaY, width: 6, height: 13), color)
            fill(CGRect(x: 60, y: antennaY, width: 6, height: 13), color)

            // Animated legs - alternating up/down pattern for walking effect
            // Legs stay attached to body (y=39), only height changes
            let baseLegPositions: [CGFloat] = [6, 18, 42, 54]
            let baseLegHeight: CGFloat = 13

            // Height offsets: positive = longer leg (down), negative = shorter leg (up)
            let legHeightOffsets: [[CGFloat]] = [
                [3, -3, 3, -3],   // Phase 0: alternating
                [0, 0, 0, 0],     // Phase 1: neutral
                [-3, 3, -3, 3],   // Phase 2: alternating (opposite)
                [0, 0, 0, 0],     // Phase 3: neutral
            ]

            let currentHeightOffsets = isScuttling ? legHeightOffsets[legPhase % 4] : [CGFloat](repeating: 0, count: 4)

            for (index, xPos) in baseLegPositions.enumerated() {
                fill(CGRect(x: xPos, y: 39, width: 6, height: baseLegHeight + currentHeightOffsets[index]), color)
            }

            // Main body
            fill(CGRect(x: 6, y: 0, width: 54, height: 39), color)

            // Eyes (squashed to a thin line while blinking)
            let eyeY: CGFloat = eyesClosed ? 17 : 13
            let eyeHeight: CGFloat = eyesClosed ? 2 : 6.5
            fill(CGRect(x: 12, y: eyeY, width: 6, height: eyeHeight), .black)
            fill(CGRect(x: 48, y: eyeY, width: 6, height: eyeHeight), .black)
        }
        .frame(width: size * (66.0 / 52.0), height: size)
        // Tiny side-step in sync with the legs while processing
        .offset(x: isScuttling ? [0, 0.5, 0, -0.5][legPhase % 4] : 0, y: lift)
        .rotationEffect(.degrees(tilt), anchor: .bottom)
        // One low-rate loop per mood; cancelled automatically when the icon disappears or the mood changes
        .task(id: AnimationKey(mood: mood, muted: muted)) {
            await runAnimation()
        }
    }

    // MARK: - Animation

    private struct AnimationKey: Equatable {
        let mood: CrabMood
        let muted: Bool
    }

    private func runAnimation() async {
        let previousMood = lastMood
        lastMood = mood
        resetPose()
        guard !muted else { return }

        switch mood {
        case .processing:
            // ~6.7 Hz: legs + side-step, blink roughly every 4.5s
            var tick = 0
            while await pause(0.15) {
                tick += 1
                legPhase = (legPhase + 1) % 4
                eyesClosed = tick % 30 == 0
            }
        case .alert:
            while !Task.isCancelled {
                await wiggle()
                guard await pause(2.4) else { return }
            }
        case .waiting, .idle:
            if mood == .waiting, previousMood == .processing || previousMood == .alert {
                await celebrate()
            }
            while await pause(Double.random(in: 3.5...6)) {
                await blink()
            }
        }
    }

    private func resetPose() {
        legPhase = 0
        eyesClosed = false
        armsUp = false
        lift = 0
        tilt = 0
    }

    /// Sleeps for the given duration; returns false if the task was cancelled
    private func pause(_ seconds: Double) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(seconds))
            return true
        } catch {
            return false
        }
    }

    private func blink() async {
        eyesClosed = true
        _ = await pause(0.12)
        eyesClosed = false
    }

    /// Small hop with a pincer wave when a session finishes
    private func celebrate() async {
        withAnimation(.easeOut(duration: 0.14)) {
            lift = -3
            armsUp = true
        }
        guard await pause(0.14) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            lift = 0
        }
        guard await pause(0.3) else { return }
        armsUp = false
        guard await pause(0.18) else { return }
        armsUp = true
        guard await pause(0.18) else { return }
        armsUp = false
    }

    /// Gentle side-to-side wiggle to draw attention to a pending permission
    private func wiggle() async {
        for angle in [-7.0, 6, -4, 2, 0] {
            withAnimation(.easeInOut(duration: 0.07)) {
                tilt = angle
            }
            guard await pause(0.07) else { return }
        }
    }
}

// Pixel art permission indicator icon
struct PermissionIndicatorIcon: View {
    let size: CGFloat
    let color: Color

    init(size: CGFloat = 14, color: Color = Color(red: 0.11, green: 0.12, blue: 0.13)) {
        self.size = size
        self.color = color
    }

    // Visible pixel positions from the SVG (at 30x30 scale)
    private let pixels: [(CGFloat, CGFloat)] = [
        (7, 7), (7, 11),           // Left column
        (11, 3),                    // Top left
        (15, 3), (15, 19), (15, 27), // Center column
        (19, 3), (19, 15),          // Right of center
        (23, 7), (23, 11)           // Right column
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 30.0
            let pixelSize: CGFloat = 4 * scale

            for (x, y) in pixels {
                let rect = CGRect(
                    x: x * scale - pixelSize / 2,
                    y: y * scale - pixelSize / 2,
                    width: pixelSize,
                    height: pixelSize
                )
                context.fill(Path(rect), with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

// Pixel art "ready for input" indicator icon (checkmark/done shape)
struct ReadyForInputIndicatorIcon: View {
    let size: CGFloat
    let color: Color

    init(size: CGFloat = 14, color: Color = TerminalColors.green) {
        self.size = size
        self.color = color
    }

    // Checkmark shape pixel positions (at 30x30 scale)
    private let pixels: [(CGFloat, CGFloat)] = [
        (5, 15),                    // Start of checkmark
        (9, 19),                    // Down stroke
        (13, 23),                   // Bottom of checkmark
        (17, 19),                   // Up stroke begins
        (21, 15),                   // Up stroke
        (25, 11),                   // Up stroke
        (29, 7)                     // End of checkmark
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 30.0
            let pixelSize: CGFloat = 4 * scale

            for (x, y) in pixels {
                let rect = CGRect(
                    x: x * scale - pixelSize / 2,
                    y: y * scale - pixelSize / 2,
                    width: pixelSize,
                    height: pixelSize
                )
                context.fill(Path(rect), with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

