//
//  CrabStory.swift
//  ClawNotch
//
//  One Antics mini-story: catalogue metadata + the routine that plays it on a CrabStage.
//  Each story is declared in its own file under Stories/<Category>/ and listed once in
//  CrabStoryCatalog.all.
//

import Foundation

/// Sections of ANIMATIONS.md (and the folders under Stories/)
enum CrabStoryCategory: String, CaseIterable {
    case tokens      // 1. Token stories (1-14)
    case tokenPlay   // 2. More token play (15-29)
    case creatures   // 3. Creatures and hazards (30-43)
    case sports      // 4. Sports and games (44-53)
    case music       // 5. Music and dance (54-63)
    case developer   // 6. Developer life (64-78)
    case emotions    // 7. Emotions and body (79-88)
    case seasonal    // 8. Seasonal and ambient (89-99)
    case community   // 9. Community ideas (100-109)
}

struct CrabStory: Identifiable, Hashable {
    /// Stable unique identifier
    let id: String
    /// Number in ANIMATIONS.md
    let number: Int
    let title: String
    /// When the story fits best (the Mood column of ANIMATIONS.md)
    let moods: Set<CrabMood>
    let category: CrabStoryCategory
    /// Plays the story; returns false if the task was cancelled. Never resets the pose: the
    /// runner (`performStory`) clears the props and eases the crab back afterwards.
    let run: @MainActor (CrabStage) async -> Bool

    nonisolated static func == (lhs: CrabStory, rhs: CrabStory) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
