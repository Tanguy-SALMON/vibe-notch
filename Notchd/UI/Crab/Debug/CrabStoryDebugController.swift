//
//  CrabStoryDebugController.swift
//  Notchd
//
//  State behind the menu's Animation Debug panel (see AnimationDebugRow.swift).
//

import Combine
import SwiftUI

/// What the Animation Debug preview crab should play. A new `token` (or any other change) restarts
/// the preview's single animation task.
struct CrabStoryDebugRequest: Equatable {
    var token: Int
    var story: CrabStory
    var looping: Bool
    var playAll: Bool
    var halfSpeed: Bool
}

/// Shared state of the menu's Animation Debug panel. Nothing here ticks: the preview crab only
/// runs while a request is playing.
@MainActor
final class CrabStoryDebugController: ObservableObject {
    static let shared = CrabStoryDebugController()

    @Published var selected: CrabStory = CrabStoryCatalog.all[0]
    @Published var looping = false
    @Published var halfSpeed = false
    /// Bumped by every play request; 0 = nothing requested yet
    @Published private(set) var token = 0
    /// Story currently on screen in the preview (nil when it is at rest)
    @Published var nowPlaying: CrabStory?

    func play(_ story: CrabStory) {
        selected = story
        token += 1
    }

    func replay() { token += 1 }
    func next() { play(CrabStoryScheduler.neighbour(of: selected, offset: 1)) }
    func previous() { play(CrabStoryScheduler.neighbour(of: selected, offset: -1)) }

    func stop() {
        token = 0
        nowPlaying = nil
    }

    func request(playAll: Bool) -> CrabStoryDebugRequest {
        CrabStoryDebugRequest(token: token, story: selected, looping: looping, playAll: playAll, halfSpeed: halfSpeed)
    }
}
