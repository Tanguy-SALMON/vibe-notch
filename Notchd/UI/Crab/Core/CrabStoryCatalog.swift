//
//  CrabStoryCatalog.swift
//  Notchd
//
//  The one list of Antics stories. The scheduler, the debug controller and the menu's
//  "Animation Debug" row read only this. Static data: nothing here ticks.
//
//  Adding a story = a new file `Stories/<Category>/StoryNNN_Name.swift` + one line below
//  (keep the list sorted by number).
//

import Foundation

enum CrabStoryCatalog {
    static let all: [CrabStory] = {
        let stories: [CrabStory] = [
            // 1. Token stories (1-14)
            .catBite,
            .voidDrop,
            .laserSlip,
            .logoKick,
            .writeTokens,
            .eatTokens,
            .vomitTokens,
            .kickTokens,
            .juggleToken,
            .smashToken,
            .paintTokens,
            .tokenRain,
            .tokenWind,
            .snapToken,
            // 9. Community ideas (100-109)
            .contextShutdown,
            .rateLimit,
            .bufferingAbyss,
            .serverMeltdown,
            .hallucinationTrapdoor,
            .tokenGuillotine,
            .injectionPie,
            .thermalSauna,
            .logoSwap,
            .ctrlZ,
        ]
        #if DEBUG
        assert(!stories.isEmpty, "CrabStoryCatalog: no stories")
        assert(Set(stories.map(\.id)).count == stories.count, "CrabStoryCatalog: duplicate story id")
        assert(Set(stories.map(\.number)).count == stories.count, "CrabStoryCatalog: duplicate story number")
        assert(stories.allSatisfy { !$0.moods.isEmpty }, "CrabStoryCatalog: story without a mood")
        assert(stories.map(\.number) == stories.map(\.number).sorted(), "CrabStoryCatalog: not sorted by number")
        #endif
        return stories
    }()
}
