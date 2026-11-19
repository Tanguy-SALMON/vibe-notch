//
//  CrabStage.swift
//  ClawNotch
//
//  What a story is allowed to touch: a thin facade over the crab icon's pose state plus the frame
//  helpers. Built inside the icon's `.task` only (by the story runner) and never stored: it is
//  just a forwarder, so every write lands in the icon's own @State.
//
//  Story bodies are `private extension CrabStage` methods (see Stories/ and README.md).
//

import SwiftUI

struct CrabStage {
    let icon: ClaudeCrabIcon

    // MARK: - Pose (forwarded to the icon's @State)

    var eyes: CrabEyes {
        get { icon.eyes }
        nonmutating set { icon.eyes = newValue }
    }

    /// Vertical offset in points (negative = up)
    var lift: CGFloat {
        get { icon.lift }
        nonmutating set { icon.lift = newValue }
    }

    /// Horizontal offset in points
    var sway: CGFloat {
        get { icon.sway }
        nonmutating set { icon.sway = newValue }
    }

    /// Rotation in degrees
    var tilt: Double {
        get { icon.tilt }
        nonmutating set { icon.tilt = newValue }
    }

    var scaleX: CGFloat {
        get { icon.scaleX }
        nonmutating set { icon.scaleX = newValue }
    }

    var scaleY: CGFloat {
        get { icon.scaleY }
        nonmutating set { icon.scaleY = newValue }
    }

    /// Body hue rotation in degrees
    var hue: Double {
        get { icon.hue }
        nonmutating set { icon.hue = newValue }
    }

    var luminance: Double {
        get { icon.luminance }
        nonmutating set { icon.luminance = newValue }
    }

    /// 0...1 partial pincer lift
    var armRaise: CGFloat {
        get { icon.armRaise }
        nonmutating set { icon.armRaise = newValue }
    }

    /// Fully hidden (stories that swap the crab for props)
    var ghosted: Bool {
        get { icon.ghosted }
        nonmutating set { icon.ghosted = newValue }
    }

    var legPhase: Int {
        get { icon.legPhase }
        nonmutating set { icon.legPhase = newValue }
    }

    var legsMoving: Bool {
        get { icon.legsMoving }
        nonmutating set { icon.legsMoving = newValue }
    }

    var leftArmUp: Bool {
        get { icon.leftArmUp }
        nonmutating set { icon.leftArmUp = newValue }
    }

    var rightArmUp: Bool {
        get { icon.rightArmUp }
        nonmutating set { icon.rightArmUp = newValue }
    }

    /// The props currently on screen (prefer `frame` / `play`)
    var antics: AnticsProps {
        get { icon.antics }
        nonmutating set { icon.antics = newValue }
    }

    /// Amplitude factor actually applied to the crab's transforms (Calm mode damps it)
    var motion: CGFloat { icon.motion }

    func setArms(_ up: Bool) { icon.setArms(up) }

    func blink() async { await icon.blink() }

    // MARK: - Time

    /// Sleeps for the given duration (already stretched for Calm mode / debug 0.5x);
    /// returns false if the task was cancelled
    func pause(_ seconds: Double) async -> Bool {
        await icon.pause(seconds)
    }

    // MARK: - Frame helpers

    /// Shows one props frame and holds it
    func frame(_ sprites: [AnticsSprite], _ seconds: Double = 0.1) async -> Bool {
        antics.sprites = sprites
        return await pause(seconds)
    }

    /// Stepped tween: `make(progress 0...1, frame index)` builds each props frame (10 Hz by default)
    func play(_ count: Int, every seconds: Double = 0.1, _ make: (CGFloat, Int) -> [AnticsSprite]) async -> Bool {
        for index in 0..<count {
            let progress = count > 1 ? CGFloat(index) / CGFloat(count - 1) : 1
            guard await frame(make(progress, index), seconds) else { return false }
        }
        return true
    }

    /// Short interpolated crab move (transform/opacity only)
    func pose(_ seconds: Double, _ change: () -> Void) {
        withAnimation(.easeOut(duration: seconds)) { change() }
    }

    func mix(_ from: CGFloat, _ to: CGFloat, _ progress: CGFloat) -> CGFloat {
        from + (to - from) * progress
    }

    /// Point on a hop from one spot to another, peaking `height` above the straight line
    func arc(
        _ fromX: CGFloat, _ fromY: CGFloat,
        _ toX: CGFloat, _ toY: CGFloat,
        height: CGFloat, _ progress: CGFloat
    ) -> (CGFloat, CGFloat) {
        let x = mix(fromX, toX, progress)
        let y = mix(fromY, toY, progress) - height * 4 * progress * (1 - progress)
        return (x, y)
    }

    // MARK: - Geometry helpers

    /// A squash factor as it is actually applied (Calm mode damps it)
    func applied(_ scale: CGFloat) -> CGFloat { 1 + (scale - 1) * motion }

    /// Where a crab row at `y` ends up after a vertical squash (the crab is anchored at its feet)
    func squashedY(_ y: CGFloat, _ scale: CGFloat) -> CGFloat { 52 - (52 - y) * applied(scale) }

    /// Where a crab column at `x` ends up after a horizontal stretch
    func squashedX(_ x: CGFloat, _ scale: CGFloat) -> CGFloat { 33 + (x - 33) * applied(scale) }

    /// viewBox units covered by a `sway` / `lift` of that many points
    func units(_ points: CGFloat) -> CGFloat { points * motion * 52 / 14 }

    func springBack(_ response: Double = 0.32) {
        withAnimation(.spring(response: response, dampingFraction: 0.55)) {
            scaleX = 1
            scaleY = 1
            ghosted = false
        }
    }
}
