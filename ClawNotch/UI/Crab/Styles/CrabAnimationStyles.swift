//
//  CrabAnimationStyles.swift
//  ClawNotch
//
//  Selectable animation styles for the pixel crab (Settings > Crab Style).
//
//  CPU rules: every loop is a cancellable `.task` child that sleeps between poses (<= 5 Hz for
//  continuous loops), continuous loops use stepped pixel-art poses (no interpolation), and
//  interpolated `withAnimation` moves are only used in short bursts separated by long rests.
//

import SwiftUI

enum CrabAnimationStyle: String, CaseIterable, Identifiable {
    // Picker order: calm styles first
    case breathe, whisper, glass, classic, sleepy, dance, bounce, disco, antics

    static let defaultsKey = "crabAnimationStyle"

    /// Used when the setting has never been chosen (or holds an unknown value)
    static let fallback: CrabAnimationStyle = .breathe

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breathe: return "Breathe (calm)"
        case .whisper: return "Whisper (minimal)"
        case .glass: return "Glass (soft sheen)"
        case .classic: return "Classic"
        case .dance: return "Dance"
        case .bounce: return "Bounce"
        case .sleepy: return "Sleepy"
        case .disco: return "Disco"
        case .antics: return "Antics (stories)"
        }
    }

    var next: CrabAnimationStyle {
        let all = Self.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}

enum CrabEyes {
    case open, droopy, closed, wide
}

// MARK: - Calm styles
//
// Micro-motion only: sub-point scale changes, opacity "breathing", soft blinks. Each loop wakes
// about once per second or less and hands the interpolation to a single long `withAnimation`
// (opacity / transform only, so the Canvas itself is not redrawn per frame). No legs, no hue,
// no hops.

extension ClaudeCrabIcon {

    // MARK: Shared calm helpers

    /// Eyelids close and reopen through the half-lidded pose (~0.3s, rare)
    func softBlink() async {
        for pose in [CrabEyes.droopy, .closed, .droopy] {
            eyes = pose
            guard await pause(0.07) else { return }
        }
        eyes = .open
    }

    /// Animates brightness and breathing scale together, then sleeps for the same duration
    private func ease(to level: Double, scale: CGFloat = 1, over seconds: Double) async -> Bool {
        withAnimation(.easeInOut(duration: seconds)) {
            luminance = level
            scaleX = 1 + (scale - 1) * 0.5
            scaleY = scale
        }
        return await pause(seconds)
    }

    /// Pincers glide up or down in a few small steps instead of snapping
    private func glidePincers(up: Bool) async -> Bool {
        let steps: [CGFloat] = up ? [0.3, 0.6, 0.85, 1] : [0.7, 0.4, 0.15, 0]
        for step in steps {
            armRaise = step
            guard await pause(0.08) else { return false }
        }
        return true
    }

    /// Rare soft blinks, nothing else
    private func restWithBlinks(every range: ClosedRange<Double>) async {
        while await pause(Double.random(in: range)) {
            await softBlink()
        }
    }

    // MARK: - Breathe: slow scale + brightness breathing, rare soft blink

    func runBreathe(finished: Bool) async {
        switch mood {
        case .processing:
            // Steady ~4.4s breath: dims slightly and swells by a fraction of a point
            var breath = 0
            while !Task.isCancelled {
                guard await ease(to: 0.72, scale: 1.035, over: 2.2) else { return }
                guard await ease(to: 1, over: 2.2) else { return }
                breath += 1
                if breath % 3 == 0 { await softBlink() }
            }
        case .waiting:
            if finished {
                // One deep, satisfied breath that settles on a heavily damped spring
                guard await glidePincers(up: true) else { return }
                withAnimation(.easeOut(duration: 0.6)) { scaleX = 1.03; scaleY = 1.06 }
                guard await pause(0.8) else { return }
                withAnimation(.interpolatingSpring(stiffness: 60, damping: 16)) { scaleX = 1; scaleY = 1 }
                guard await glidePincers(up: false) else { return }
                guard await pause(1) else { return }
            }
            await breatheAtRest()
        case .alert:
            // Two slow, deeper breaths with wide eyes and pincers held up, then a rest
            eyes = .wide
            guard await glidePincers(up: true) else { return }
            while !Task.isCancelled {
                for _ in 0..<2 {
                    guard await ease(to: 0.5, scale: 1.07, over: 0.7) else { return }
                    guard await ease(to: 1, over: 0.7) else { return }
                }
                guard await pause(2.4) else { return }
            }
        case .idle:
            await breatheAtRest()
        }
    }

    /// One slow breath (~5.4s), then stillness; the rest keeps the display link idle most of the time
    private func breatheAtRest() async {
        while await pause(Double.random(in: 5...8)) {
            guard await ease(to: 0.86, scale: 1.03, over: 2.5) else { return }
            guard await ease(to: 1, over: 2.9) else { return }
            if Bool.random() {
                guard await pause(0.8) else { return }
                await softBlink()
            }
        }
    }

    // MARK: - Whisper: almost static

    func runWhisper(finished: Bool) async {
        switch mood {
        case .processing:
            // Faint brightness pulse only (~5s cycle); geometry never moves
            while !Task.isCancelled {
                guard await ease(to: 0.8, over: 2.5) else { return }
                guard await ease(to: 1, over: 2.5) else { return }
            }
        case .waiting:
            if finished {
                // A single slow pincer lift, held briefly
                guard await glidePincers(up: true) else { return }
                guard await pause(1.1) else { return }
                guard await glidePincers(up: false) else { return }
            }
            await restWithBlinks(every: 8...14)
        case .alert:
            // Pincers stay raised; one slow dim-and-return every few seconds
            guard await glidePincers(up: true) else { return }
            while !Task.isCancelled {
                guard await ease(to: 0.5, over: 0.9) else { return }
                guard await ease(to: 1, over: 0.9) else { return }
                guard await pause(2.6) else { return }
            }
        case .idle:
            await restWithBlinks(every: 8...14)
        }
    }

    // MARK: - Glass: a soft highlight that glides across the shell

    func runGlass(finished: Bool) async {
        switch mood {
        case .processing:
            // One slow sheen pass, then a rest (wakes every ~3.4s)
            while !Task.isCancelled {
                guard await sweepSheen(over: 1.8) else { return }
                guard await pause(1.6) else { return }
            }
        case .waiting:
            if finished {
                // A slower pass with a barely-there swell that settles on a damped spring
                withAnimation(.easeOut(duration: 0.5)) { scaleX = 1.02; scaleY = 1.04 }
                guard await sweepSheen(over: 2.2) else { return }
                withAnimation(.interpolatingSpring(stiffness: 60, damping: 16)) { scaleX = 1; scaleY = 1 }
                guard await pause(1.2) else { return }
            }
            await restWithBlinks(every: 7...12)
        case .alert:
            // Two slow, gentle luminous pulses, then a rest; no wiggle
            eyes = .wide
            while !Task.isCancelled {
                for _ in 0..<2 {
                    guard await ease(to: 0.45, over: 0.6) else { return }
                    guard await ease(to: 1, over: 0.6) else { return }
                }
                guard await pause(2.6) else { return }
            }
        case .idle:
            await restWithBlinks(every: 7...12)
        }
    }

    /// Glides the highlight band from off the left edge to off the right edge
    private func sweepSheen(over seconds: Double) async -> Bool {
        sheen = -1
        withAnimation(.easeInOut(duration: seconds)) { sheen = 1 }
        return await pause(seconds + 0.05)
    }
}

extension ClaudeCrabIcon {

    // MARK: - Dance: side-to-side sway, alternating pincers, leg taps

    func runDance(finished: Bool) async {
        switch mood {
        case .processing:
            // 4 Hz beat, stepped poses
            legsMoving = true
            var beat = 0
            while await pause(0.25) {
                beat += 1
                dancePose(left: beat % 2 == 0, lean: 5, slide: 1)
                eyes = beat % 16 == 0 ? .closed : .open
            }
        case .waiting:
            if finished { await celebrate() }
            // A short happy groove, then a rest
            while !Task.isCancelled {
                for beat in 0..<6 {
                    dancePose(left: beat % 2 == 0, lean: 3, slide: 0.5)
                    guard await pause(0.4) else { return }
                }
                danceRest()
                guard await pause(Double.random(in: 3...5)) else { return }
                await blink()
            }
        case .alert:
            // Both pincers up + fast shimmy, then a rest
            while !Task.isCancelled {
                setArms(true)
                eyes = .wide
                for step in 0..<8 {
                    sway = step % 2 == 0 ? -1.5 : 1.5
                    guard await pause(0.1) else { return }
                }
                danceRest()
                guard await pause(2.2) else { return }
            }
        case .idle:
            // One lazy sway now and then
            while await pause(Double.random(in: 4...7)) {
                for angle in [-4.0, 4, 0] {
                    withAnimation(.easeInOut(duration: 0.3)) { tilt = angle }
                    guard await pause(0.32) else { return }
                }
                guard await pause(1.5) else { return }
                await blink()
            }
        }
    }

    private func dancePose(left: Bool, lean: Double, slide: CGFloat) {
        leftArmUp = left
        rightArmUp = !left
        legPhase = left ? 0 : 2
        tilt = left ? -lean : lean
        sway = left ? -slide : slide
    }

    private func danceRest() {
        setArms(false)
        eyes = .open
        tilt = 0
        sway = 0
    }

    // MARK: - Bounce: squash-and-stretch jumping

    func runBounce(finished: Bool) async {
        switch mood {
        case .processing:
            // Stepped pogo: 4 poses at 5 Hz
            legsMoving = true
            var tick = 0
            while await pause(0.2) {
                tick += 1
                switch tick % 4 {
                case 0: squash(1.12, 0.84); lift = 0; legPhase = 0       // crouch
                case 1: squash(0.92, 1.12); lift = -2; legPhase = 2      // launch
                case 2: squash(1, 1); lift = -3                          // apex
                default: squash(0.96, 1.06); lift = -1.5; legPhase = 0   // fall
                }
            }
        case .waiting:
            if finished { guard await jump(height: 3.5, arms: true) else { return } }
            while await pause(Double.random(in: 3...5.5)) {
                guard await jump(height: 2.5, arms: Bool.random()) else { return }
            }
        case .alert:
            // Two urgent jumps with pincers up, then a rest
            while !Task.isCancelled {
                eyes = .wide
                guard await jump(height: 3.5, arms: true) else { return }
                guard await jump(height: 3.5, arms: true) else { return }
                eyes = .open
                guard await pause(2) else { return }
            }
        case .idle:
            // Tiny settle-bob (stepped) and a blink
            while await pause(Double.random(in: 4...7)) {
                squash(1.04, 0.94)
                guard await pause(0.25) else { return }
                squash(1, 1)
                guard await pause(1.2) else { return }
                await blink()
            }
        }
    }

    private func squash(_ x: CGFloat, _ y: CGFloat) {
        scaleX = x
        scaleY = y
    }

    /// One smooth squash-and-stretch jump (~0.75s); returns false if cancelled
    private func jump(height: CGFloat, arms: Bool) async -> Bool {
        withAnimation(.easeIn(duration: 0.08)) { squash(1.12, 0.82) }
        guard await pause(0.09) else { return false }
        setArms(arms)
        withAnimation(.easeOut(duration: 0.16)) { squash(0.92, 1.12); lift = -height }
        guard await pause(0.17) else { return false }
        withAnimation(.easeIn(duration: 0.14)) { squash(1.08, 0.88); lift = 0 }
        guard await pause(0.14) else { return false }
        setArms(false)
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { squash(1, 1) }
        return await pause(0.35)
    }

    // MARK: - Sleepy: slow breathing, heavy eyelids

    func runSleepy(finished: Bool) async {
        switch mood {
        case .processing:
            // Drowsy shuffle at 2.5 Hz, nodding off and jerking awake
            legsMoving = true
            eyes = .droopy
            var tick = 0
            while await pause(0.4) {
                tick += 1
                legPhase = (legPhase + 1) % 4
                switch tick % 20 {
                case 14, 15: eyes = .closed; tilt = 4      // nodding off
                case 16: eyes = .wide; tilt = 0            // jerks awake
                case 17: eyes = .open
                default: eyes = .droopy
                }
            }
        case .waiting:
            if finished {
                // Wakes up with a happy stretch
                eyes = .open
                setArms(true)
                squash(0.96, 1.08)
                guard await pause(0.7) else { return }
                setArms(false)
                squash(1, 1)
                guard await pause(1.5) else { return }
            }
            await breathe(eyes: .droopy, period: 1.4)
        case .alert:
            // Startled awake, looks around, dozes off again
            while !Task.isCancelled {
                eyes = .wide
                setArms(true)
                withAnimation(.easeOut(duration: 0.1)) { lift = -3 }
                guard await pause(0.12) else { return }
                withAnimation(.easeIn(duration: 0.1)) { lift = 0 }
                for angle in [-6.0, 6, -6, 6, 0] {
                    tilt = angle
                    guard await pause(0.12) else { return }
                }
                setArms(false)
                eyes = .open
                guard await pause(1.2) else { return }
                eyes = .droopy
                guard await pause(1.2) else { return }
            }
        case .idle:
            await breathe(eyes: .closed, period: 1.8)
        }
    }

    /// Stepped breathing (two poses per breath); eyes peek open briefly every so often
    private func breathe(eyes resting: CrabEyes, period: Double) async {
        eyes = resting
        var breath = 0
        while await pause(period) {
            breath += 1
            let inhale = breath % 2 == 1
            squash(inhale ? 1.03 : 1, inhale ? 1.06 : 1)
            eyes = breath % 10 == 9 ? .droopy : resting
        }
    }

    // MARK: - Disco: dance moves with a colour-cycling shell

    func runDisco(finished: Bool) async {
        switch mood {
        case .processing:
            // 5 Hz: hue steps round the wheel while dancing
            legsMoving = true
            var beat = 0
            while await pause(0.2) {
                beat += 1
                hue = Double((beat * 45) % 360)
                leftArmUp = beat % 2 == 0
                rightArmUp = beat % 2 == 1
                legPhase = beat % 2 == 0 ? 0 : 2
                sway = [-1, 0, 1, 0][beat % 4]
                lift = beat % 2 == 0 ? -1 : 0
            }
        case .waiting:
            if finished { await celebrate() }
            // Slow colour drift with a pincer wave
            var beat = 0
            while await pause(0.8) {
                beat += 1
                hue = Double((beat * 30) % 360)
                leftArmUp = beat % 4 == 0
                rightArmUp = beat % 4 == 2
                tilt = [-3, 0, 3, 0][beat % 4]
            }
        case .alert:
            // Strobe between two colours with pincers up, then a rest
            while !Task.isCancelled {
                setArms(true)
                eyes = .wide
                for flash in 0..<8 {
                    hue = flash % 2 == 0 ? 180 : 0
                    sway = flash % 2 == 0 ? -1 : 1
                    guard await pause(0.12) else { return }
                }
                setArms(false)
                eyes = .open
                sway = 0
                hue = 0
                guard await pause(2) else { return }
            }
        case .idle:
            // Mood-lamp: a new colour every few seconds, plus a blink
            while await pause(3) {
                hue = (hue + 40).truncatingRemainder(dividingBy: 360)
                await blink()
            }
        }
    }
}
