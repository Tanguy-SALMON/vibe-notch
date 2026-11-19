//
//  ClaudeCrabIcon.swift
//  Notchd
//
//  The pixel crab: drawing, pose state and the single cancellable animation task.
//  Styles live in Styles/, the Antics stories in Stories/ (driven through CrabStage).
//

import Combine
import SwiftUI

struct ClaudeCrabIcon: View {
    let size: CGFloat
    let color: Color
    var animateLegs: Bool = false
    var mood: CrabMood
    /// Antics style only: play the stories back to back (Settings preview)
    var anticsDemo = false
    /// Animation Debug preview: forces the Antics style for this icon only and plays what is requested
    var debug: CrabStoryDebugRequest?

    @AppStorage("muteNotchAnimation") var muted = false
    @AppStorage(CrabAnimationStyle.defaultsKey) private var styleRaw = CrabAnimationStyle.fallback.rawValue

    // Pose state (internal so the style routines and CrabStage can drive it)
    @State var legPhase: Int = 0
    @State var legsMoving = false
    @State var eyes: CrabEyes = .open
    @State var leftArmUp = false
    @State var rightArmUp = false
    @State var lift: CGFloat = 0     // Vertical offset in points (negative = up)
    @State var sway: CGFloat = 0     // Horizontal offset in points
    @State var tilt: Double = 0      // Rotation in degrees
    @State var scaleX: CGFloat = 1   // Squash / stretch, anchored at the feet
    @State var scaleY: CGFloat = 1
    @State var hue: Double = 0       // Body hue rotation in degrees
    @State var luminance: Double = 1 // Opacity "brightness" (1 = full); dims toward the black notch
    @State var armRaise: CGFloat = 0 // 0...1 partial pincer lift for slow, soft raises
    @State var sheen: CGFloat = -1   // Glass highlight position: -1 = off left, 1 = off right
    @State var ghosted = false       // Fully hidden (stories that swap the crab for props); ignores Calm damping
    @State var antics = AnticsProps() // Antics props (empty except while a story plays)
    @State var anticsLast: CrabStory? // Last story played, so it never repeats back to back
    @State private var lastMood: CrabMood?

    var style: CrabAnimationStyle {
        debug != nil ? .antics : (CrabAnimationStyle(rawValue: styleRaw) ?? .fallback)
    }
    @AppStorage(CrabStoryScheduler.debugLoopKey) private var anticsLoop = false

    init(
        size: CGFloat = 16,
        color: Color = Color(red: 0.85, green: 0.47, blue: 0.34),
        animateLegs: Bool = false,
        mood: CrabMood? = nil,
        anticsDemo: Bool = false,
        debug: CrabStoryDebugRequest? = nil
    ) {
        self.size = size
        self.color = color
        self.animateLegs = animateLegs
        self.mood = mood ?? (animateLegs ? .processing : .idle)
        self.anticsDemo = anticsDemo
        self.debug = debug
    }

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 52.0  // Original viewBox height is 52
            let xOffset = (canvasSize.width - 66 * scale) / 2
            let transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: xOffset / scale, y: 0)

            func fill(_ rect: CGRect, _ fillColor: Color) {
                context.fill(Path(rect).applying(transform), with: .color(fillColor))
            }

            // Antennas / pincers (raised during the celebratory wave)
            let softLift = 8 * min(max(armRaise, 0), 1)
            fill(CGRect(x: 0, y: leftArmUp ? 5 : 13 - softLift, width: 6, height: 13), color)
            fill(CGRect(x: 60, y: rightArmUp ? 5 : 13 - softLift, width: 6, height: 13), color)

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

            let currentHeightOffsets = legsMoving ? legHeightOffsets[legPhase % 4].map { $0 * motion } : [CGFloat](repeating: 0, count: 4)

            for (index, xPos) in baseLegPositions.enumerated() {
                fill(CGRect(x: xPos, y: 39, width: 6, height: baseLegHeight + currentHeightOffsets[index]), color)
            }

            // Main body
            fill(CGRect(x: 6, y: 0, width: 54, height: 39), color)

            // Eyes (thin line while blinking, half-lidded when drowsy, tall when startled)
            let eyeY: CGFloat
            let eyeHeight: CGFloat
            switch eyes {
            case .open: eyeY = 13; eyeHeight = 6.5
            case .droopy: eyeY = 16; eyeHeight = 3.5
            case .closed: eyeY = 17; eyeHeight = 2
            case .wide: eyeY = 10; eyeHeight = 10
            }
            fill(CGRect(x: 12, y: eyeY, width: 6, height: eyeHeight), .black)
            fill(CGRect(x: 48, y: eyeY, width: 6, height: eyeHeight), .black)
        }
        .frame(width: size * (66.0 / 52.0), height: size)
        .overlay {
            // Glass only: a soft highlight band, painted just where the crab has pixels
            if style == .glass {
                let width = size * (66.0 / 52.0)
                LinearGradient(
                    colors: [.white.opacity(0), .white.opacity(0.45), .white.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: width * 0.6)
                .offset(x: sheen * width * 0.85)
                .blendMode(.sourceAtop)
                .allowsHitTesting(false)
            }
        }
        .compositingGroup()
        .opacity(ghosted ? 0 : 1 - (1 - luminance) * motion)
        .hueRotation(.degrees(hue * motion))
        .scaleEffect(x: 1 + (scaleX - 1) * motion, y: 1 + (scaleY - 1) * motion, anchor: .bottom)
        // sway / lift are tuned in points for the 14pt notch crab; other sizes move proportionally
        .offset(x: sway * motion * size / 14, y: lift * motion * size / 14)
        .rotationEffect(.degrees(tilt * motion), anchor: .bottom)
        .overlay(alignment: .topLeading) {
            // Antics only: story props, drawn un-transformed over the crab; absent at rest
            if style == .antics, !antics.sprites.isEmpty {
                AnticsOverlay(props: antics, size: size)
                    .opacity(muted ? 0.85 : 1)
            }
        }
        // "Mute" = calm mode: every animation runs at a fraction of its speed
        .transaction { transaction in
            if timeStretch != 1 { transaction.animation = transaction.animation?.speed(1 / timeStretch) }
        }
        // One low-rate loop per mood/style; cancelled automatically when the icon disappears or the key changes
        .task(id: AnimationKey(mood: mood, muted: muted, style: style, anticsLoop: anticsLoop, debug: debug)) {
            await runAnimation()
        }
    }

    // MARK: - Animation

    /// Calm mode: animations take this many times longer...
    static let calmSlowdown = 2.5
    /// ...and move this fraction of their normal amplitude
    var motion: CGFloat { muted ? 0.4 : 1 }
    /// How much longer every pause / animation takes (Calm mode, debug half speed)
    private var timeStretch: Double { (muted ? Self.calmSlowdown : 1) * (debug?.halfSpeed == true ? 2 : 1) }

    private struct AnimationKey: Equatable {
        let mood: CrabMood
        let muted: Bool
        let style: CrabAnimationStyle
        let anticsLoop: Bool
        let debug: CrabStoryDebugRequest?
    }

    private func runAnimation() async {
        let previousMood = lastMood
        lastMood = mood
        resetPose()
        if let debug {
            await runStoryDebug(debug)
            return
        }
        let finished = mood == .waiting && (previousMood == .processing || previousMood == .alert)

        switch style {
        case .breathe: await runBreathe(finished: finished)
        case .whisper: await runWhisper(finished: finished)
        case .glass: await runGlass(finished: finished)
        case .classic: await runClassic(finished: finished)
        case .dance: await runDance(finished: finished)
        case .bounce: await runBounce(finished: finished)
        case .sleepy: await runSleepy(finished: finished)
        case .disco: await runDisco(finished: finished)
        case .antics: await runAntics(finished: finished)
        }
    }

    private func runClassic(finished: Bool) async {
        switch mood {
        case .processing:
            // ~6.7 Hz: legs + tiny side-step, blink roughly every 4.5s
            legsMoving = true
            var tick = 0
            while await pause(0.15) {
                tick += 1
                legPhase = (legPhase + 1) % 4
                sway = [0, 0.5, 0, -0.5][legPhase]
                eyes = tick % 30 == 0 ? .closed : .open
            }
        case .alert:
            while !Task.isCancelled {
                await wiggle()
                guard await pause(2.4) else { return }
            }
        case .waiting, .idle:
            if finished { await celebrate() }
            while await pause(Double.random(in: 3.5...6)) {
                await blink()
            }
        }
    }

    private func resetPose() {
        legPhase = 0
        legsMoving = false
        eyes = .open
        leftArmUp = false
        rightArmUp = false
        lift = 0
        sway = 0
        tilt = 0
        scaleX = 1
        scaleY = 1
        hue = 0
        luminance = 1
        armRaise = 0
        sheen = -1
        ghosted = false
        antics = AnticsProps()
    }

    /// Sleeps for the given duration; returns false if the task was cancelled
    func pause(_ seconds: Double) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(seconds * timeStretch))
            return true
        } catch {
            return false
        }
    }

    func setArms(_ up: Bool) {
        leftArmUp = up
        rightArmUp = up
    }

    func blink() async {
        let before = eyes
        eyes = .closed
        _ = await pause(0.12)
        eyes = before
    }

    /// Small hop with a pincer wave when a session finishes
    func celebrate() async {
        withAnimation(.easeOut(duration: 0.14)) {
            lift = -3
            setArms(true)
        }
        guard await pause(0.14) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            lift = 0
        }
        guard await pause(0.3) else { return }
        setArms(false)
        guard await pause(0.18) else { return }
        setArms(true)
        guard await pause(0.18) else { return }
        setArms(false)
    }

    /// Gentle side-to-side wiggle to draw attention to a pending permission
    func wiggle() async {
        for angle in [-7.0, 6, -4, 2, 0] {
            withAnimation(.easeInOut(duration: 0.07)) {
                tilt = angle
            }
            guard await pause(0.07) else { return }
        }
    }
}

