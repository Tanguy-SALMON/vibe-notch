# Crab

The pixel crab in the notch: its drawing, its animation styles and the "Antics" mini-stories.

```
Core/     ClaudeCrabIcon (view + pose @State + the single .task), CrabMood,
          CrabStage (what a story may touch), CrabStory, CrabStoryCatalog, CrabStoryScheduler
Styles/   CrabAnimationStyles (Breathe, Whisper, Glass, Dance, ...)
Props/    Prop (sprite model, PropArt, Tone, slab), PropsOverlay (canvas + shared art),
          CommunityPropArt (more shared art)
Debug/    CrabStoryDebugController, AnimationDebugRow (menu > Animation Debug)
Stories/  <Category>/StoryNNN_Name.swift - one file per story
```

## Adding a story

1. Create `Stories/<Category>/StoryNNN_Name.swift` from the template below
   (`NNN` = number in `ANIMATIONS.md`, zero-padded; `<Category>` = its section there).
2. Add one line to `CrabStoryCatalog.all` (keep it sorted by number).
3. Mark it ✅ in `ANIMATIONS.md`, then review it in the notch menu under **Animation Debug**.

`scripts/check-crab-stories.sh` checks that every story file is listed in the catalogue.
Nothing else needs editing: the scheduler, the debug panel and "Play all" read the catalogue.

```swift
//
//  Story110_Balloon.swift
//  ClawNotch
//
//  #110 Balloon: a balloon drifts up past the crab, who waves.
//

import SwiftUI

extension CrabStory {
    static let balloon = CrabStory(
        id: "balloon", number: 110, title: "Balloon",
        moods: [.idle], category: .community
    ) { await $0.balloon() }
}

/// Art only this story uses (optional; shared kinds like `.token`, `.spark`, `.star` need none)
private let balloonArt = PropArt(id: "story110.balloon") { sprite, layer in
    layer.fill(
        Path(ellipseIn: CGRect(x: -5, y: -7, width: 10, height: 13)),
        with: .color(AnticsOverlay.tone(sprite.tint))
    )
    layer.fill(AnticsOverlay.rect(-0.5, 6, 1, 8), with: .color(.white))
}

private extension CrabStage {
    func balloon() async -> Bool {
        eyes = .wide
        let rose = await play(12) { progress, index in
            rightArmUp = index % 4 < 2
            return [Prop(.art(balloonArt), 78, mix(50, -30, progress), tint: Tone.red)]
        }
        guard rose else { return false }
        rightArmUp = false
        return await frame([], 0.3)
    }
}
```

## Rules

- **Guard every await**: `guard await ... else { return false }` (or `return await ...` last).
  `false` means the task was cancelled; stop immediately and touch nothing else.
- **Time only through the stage**: `pause`, `frame`, `play`, `pose`. They are already stretched
  for Calm mode and the debug 0.5x. Never call `Task.sleep` and never read `muted`; use
  `motion` / `applied` / `squashedX` / `squashedY` / `units` when a prop has to line up with the
  (possibly damped) crab.
- **One task**: no `Task {}`, no `Task.detached`, no timers. A story is a straight-line async
  function running inside the icon's single cancellable `.task`.
- **<= 12 Hz**: step props with `frame` / `play` (10 Hz by default); interpolated moves
  (`pose`, `withAnimation`) only on the crab's transform / opacity, in short bursts.
- **No cleanup**: never reset the pose at the end. The runner (`performStory` in
  `CrabStoryScheduler.swift`) clears the props and eases the crab back to rest after every
  story, finished or cancelled.
- **2-4 s long**, props within a few points of the crab (the overlay canvas clips beyond
  `AnticsOverlay.padX` / `padTop` / `padBottom`), generic shapes only (no trademarked art).
- **Never store a `CrabStage`**: it is built by the runner inside the task and passed in.
- `moods` must not be empty; a story tagged `.alert` is the only kind played on alert.
- Unique `id`, unique `number` (asserted in DEBUG at first catalogue access).

## Coordinates

Props live in the crab's 66 x 52 viewBox: (0, 0) is the crab's top-left, the feet are at
y = 52, the body centre at x = 33. `Prop(kind, x, y, size:tint:v:angle:alpha:length:)`;
what `tint` / `v` / `length` mean depends on the kind (see `Prop.swift`).
