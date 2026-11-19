//
//  CrabStoryScheduler.swift
//  Notchd
//
//  "Antics" crab style: a calm Breathe-like base, interrupted now and then by a short pixel-art
//  mini-story (a cat bite, a laser slip, token juggling, ...) picked from CrabStoryCatalog.
//
//  CPU rules: one cancellable `.task` loop (the icon's own). Between stories the loop sleeps in
//  long single `Task.sleep`s (idle) or slow breaths (processing). Props are stepped at <= 10 Hz and
//  only exist while a story plays: at rest the overlay Canvas is not even in the view tree.
//

import SwiftUI

/// Which story plays next
enum CrabStoryScheduler {
    /// When this UserDefaults bool is true, stories play back to back (in order) for review.
    /// Toggled by "Play all" in the menu's Animation Debug panel.
    static let debugLoopKey = "crabAnticsDebugLoop"

    /// Random next story: two times out of three one that fits the mood, otherwise anything.
    /// Alert only ever plays alert-tagged stories. Never the one that just played.
    static func pick(for mood: CrabMood, excluding last: CrabStory?) -> CrabStory {
        let pool = CrabStoryCatalog.all.filter { $0 != last }
        let fitting = pool.filter { $0.moods.contains(mood) }
        if mood == .alert || Int.random(in: 0..<3) > 0, let choice = fitting.randomElement() {
            return choice
        }
        return pool.randomElement() ?? CrabStoryCatalog.all[0]
    }

    /// The story `offset` places away in catalogue order (wraps around)
    static func neighbour(of story: CrabStory, offset: Int) -> CrabStory {
        let all = CrabStoryCatalog.all
        let index = (all.firstIndex(of: story) ?? 0) + offset
        return all[((index % all.count) + all.count) % all.count]
    }
}

// MARK: - Runner (inside the icon's single task)

extension ClaudeCrabIcon {

    func runAntics(finished: Bool) async {
        if mood == .alert {
            // One loud story, then calm pulses with the pincers held up
            let loud = CrabStoryScheduler.pick(for: .alert, excluding: anticsLast)
            anticsLast = loud
            guard await performStory(loud) else { return }
            eyes = .wide
            withAnimation(.easeOut(duration: 0.35)) { armRaise = 1 }
            while !Task.isCancelled {
                for _ in 0..<2 {
                    guard await anticsEase(to: 0.5, scale: 1.07, over: 0.7) else { return }
                    guard await anticsEase(to: 1, over: 0.7) else { return }
                }
                guard await pause(2.4) else { return }
            }
            return
        }

        if finished {
            // One satisfied breath with a soft pincer lift
            withAnimation(.easeOut(duration: 0.5)) { armRaise = 1; scaleX = 1.03; scaleY = 1.06 }
            guard await pause(0.9) else { return }
            withAnimation(.easeInOut(duration: 0.5)) { armRaise = 0; scaleX = 1; scaleY = 1 }
            guard await pause(0.6) else { return }
        }

        var reviewIndex = 0
        while !Task.isCancelled {
            let debugLoop = UserDefaults.standard.bool(forKey: CrabStoryScheduler.debugLoopKey)
            let next: CrabStory
            if debugLoop {
                // Review mode: every story in order, 1s apart
                guard (try? await Task.sleep(for: .seconds(1))) != nil else { return }
                next = CrabStoryCatalog.all[reviewIndex % CrabStoryCatalog.all.count]
                reviewIndex += 1
            } else {
                if anticsDemo {
                    guard await pause(1.5) else { return }
                } else {
                    guard await anticsRest() else { return }
                }
                next = CrabStoryScheduler.pick(for: mood, excluding: anticsLast)
            }
            anticsLast = next
            guard await performStory(next) else { return }
        }
    }

    /// Animation Debug preview: plays the requested story once (or on repeat), or every story in
    /// order from the selected one. Returns - and so costs nothing - when there is nothing to play.
    @MainActor
    func runStoryDebug(_ request: CrabStoryDebugRequest) async {
        let controller = CrabStoryDebugController.shared
        if request.playAll {
            var story = request.story
            while !Task.isCancelled {
                controller.nowPlaying = story
                guard await performStory(story) else { return }
                guard await pause(0.7) else { return }
                story = CrabStoryScheduler.neighbour(of: story, offset: 1)
            }
            return
        }

        guard request.token > 0 else { return }
        repeat {
            controller.nowPlaying = request.story
            guard await performStory(request.story) else { return }
            controller.nowPlaying = nil
            guard request.looping, await pause(0.6) else { return }
        } while !Task.isCancelled
    }

    /// The long quiet stretch between stories. Processing: slow breathing (~4.4s per breath) for
    /// 20-40s. Idle/waiting: 45-120s made of single long sleeps with one slow breath in between.
    private func anticsRest() async -> Bool {
        let slowdown = muted ? Self.calmSlowdown : 1
        if mood == .processing {
            var remaining = Double.random(in: 20...40) / slowdown
            var breath = 0
            while remaining > 0 {
                guard await anticsEase(to: 0.72, scale: 1.035, over: 2.2) else { return false }
                guard await anticsEase(to: 1, over: 2.2) else { return false }
                remaining -= 4.4
                breath += 1
                if breath % 3 == 0 { await softBlink() }
            }
        } else {
            var remaining = Double.random(in: 45...120) / slowdown
            while remaining > 0 {
                let nap = min(remaining, Double.random(in: 10...16))
                guard await pause(nap) else { return false }
                remaining -= nap
                guard remaining > 6 else { break }
                guard await anticsEase(to: 0.86, scale: 1.03, over: 2.5) else { return false }
                guard await anticsEase(to: 1, over: 2.9) else { return false }
                remaining -= 5.4
                if Bool.random() { await softBlink() }
            }
        }
        return !Task.isCancelled
    }

    /// The Breathe base: stepped, never one long interpolation after another (see `ease`)
    private func anticsEase(to level: Double, scale: CGFloat = 1, over seconds: Double) async -> Bool {
        await ease(to: level, scale: scale, over: seconds)
    }

    /// Plays one story, then clears the props and eases the crab back to its rest pose.
    /// The only place a CrabStage is built, and the only place a story's pose is cleaned up.
    private func performStory(_ story: CrabStory) async -> Bool {
        // Start every story from a neutral pose (the breathing base may be mid-breath)
        withAnimation(.easeOut(duration: 0.2)) {
            luminance = 1
            scaleX = 1
            scaleY = 1
        }
        guard await pause(0.2) else { return false }

        let completed = await story.run(CrabStage(icon: self))

        antics = AnticsProps()
        legsMoving = false
        legPhase = 0
        setArms(false)
        eyes = .open
        withAnimation(.easeOut(duration: 0.25)) {
            lift = 0
            sway = 0
            tilt = 0
            scaleX = 1
            scaleY = 1
            hue = 0
            luminance = 1
            armRaise = 0
            ghosted = false
        }
        guard completed else { return false }
        return await pause(0.3)
    }
}
