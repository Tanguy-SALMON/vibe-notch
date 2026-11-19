# ClawNotch — 99 crab animations

Catalogue of mini-animations for the pixel crab in the notch.

- **Status:** ✅ implemented (style "Antics (stories)") · 💡 idea, not built yet
- **Mood** = when it fits best: `idle` (nothing happening), `work` (a session is processing), `done` (session finished, waiting for input), `alert` (permission pending)
- **Rules for every animation:** ≤ ~3–4 s long, played rarely (idle: every 45–120 s, work: every 20–40 s), ~0% CPU between plays, must respect **Calm Animation** (2.5× slower, 0.4× amplitude), props stay within a few points of the crab, no trademarked art (generic shapes only).
- **Token** = a small orange pixel square, sometimes with a tiny glyph.

> To build one: create `ClawNotch/UI/Crab/Stories/<Category>/StoryNNN_Name.swift` from the template in `ClawNotch/UI/Crab/README.md` (one file per story: metadata + a `private extension CrabStage` routine), add one line for it in `CrabStoryCatalog.all` (`ClawNotch/UI/Crab/Core/CrabStoryCatalog.swift`), then review it in the notch menu under **Animation Debug** (pick a story, Replay / Previous / Next, Loop this one, Play all, 0.5x).

---

## 1. Token stories — shipped (1–14)

| # | Name | Concept | Mood | Status |
|---|------|---------|------|--------|
| 1 | Cat bite | A pixel cat nips the crab, who flinches | alert | ✅ |
| 2 | Void drop | Crab falls through a dark hole, shrinks, climbs back | idle | ✅ |
| 3 | Laser slip | A laser beam sweeps and the crab slips over it | alert | ✅ |
| 4 | AI-badge kick | Crab kicks a generic green knot badge away | idle | ✅ |
| 5 | Write tokens | Scribbles little token glyphs | work | ✅ |
| 6 | Eat tokens | Munches falling tokens | idle | ✅ |
| 7 | Vomit tokens | Cartoon spurt of small squares | idle | ✅ |
| 8 | Kick tokens | Kicks a token across the notch | done | ✅ |
| 9 | Play with token | Bounces and juggles one token | idle | ✅ |
| 10 | Smash token | Token cracks into pieces | done | ✅ |
| 11 | Paint tokens | Brush recolours token squares | work | ✅ |
| 12 | Rain tokens | Tokens fall, crab holds up pincers | idle | ✅ |
| 13 | Wind tokens | Tokens stream sideways, crab leans | idle | ✅ |
| 14 | Break token | Snaps a token in two | done | ✅ |

## 2. More token play (15–29)

| # | Name | Concept | Mood | Status |
|---|------|---------|------|--------|
| 15 | Token tower | Stacks tokens, tower wobbles and collapses | work | 💡 |
| 16 | Token fishing | Casts a line, reels in a token | idle | 💡 |
| 17 | Piggy bank | Drops tokens into a tiny piggy bank, it rattles | done | 💡 |
| 18 | Bubble pop | Blows token bubbles, pops them one by one | idle | 💡 |
| 19 | Slot machine | Pulls a lever, three tokens spin, jackpot flash | done | 💡 |
| 20 | Vending machine | Feeds a token in, a smaller token drops out | idle | 💡 |
| 21 | Token bowling | Rolls a token, knocks over pin-pixels | idle | 💡 |
| 22 | Hopscotch | Hops across a row of token tiles | work | 💡 |
| 23 | Skipping stone | Skims a token over an invisible pond | idle | 💡 |
| 24 | Catapult | Flings a token off a see-saw | idle | 💡 |
| 25 | Sandcastle | Builds a tiny token castle, wave washes it away | idle | 💡 |
| 26 | Tightrope | Balances on a token line with pincers out | work | 💡 |
| 27 | Boomerang | Throws a token, it returns and bonks the crab | idle | 💡 |
| 28 | Token fireworks | Token shoots up and bursts into colour | done | 💡 |
| 29 | Token confetti | Tosses tokens up like confetti | done | 💡 |

## 3. Creatures and hazards (30–43)

| # | Name | Concept | Mood | Status |
|---|------|---------|------|--------|
| 30 | Bird peck | A pixel bird pecks at the crab's eye | alert | 💡 |
| 31 | Ghost pass | Ghost drifts by, crab's eyes follow | idle | 💡 |
| 32 | UFO abduction | Beam lifts the crab up and sets it back | alert | 💡 |
| 33 | Shark fin | Fin circles under the crab, crab hops | idle | 💡 |
| 34 | Mouse chase | Mouse scurries past, crab chases a step | idle | 💡 |
| 35 | Bee buzz | A bee loops around the crab, crab swats | work | 💡 |
| 36 | Spider drop | Spider lowers on a thread, crab backs away | alert | 💡 |
| 37 | Snail race | A snail overtakes the crab | idle | 💡 |
| 38 | Mosquito | Tiny mosquito whines, crab claps and misses | idle | 💡 |
| 39 | Dragon sneeze | Baby dragon sneezes a spark, crab fans it | alert | 💡 |
| 40 | Lightning strike | Flash, crab flashes to a skeleton frame and back | alert | 💡 |
| 41 | Meteor | A meteor streaks by, crab ducks | alert | 💡 |
| 42 | Banana peel | Slips on a peel, spins, lands on feet | idle | 💡 |
| 43 | Anvil drop | Anvil drops, squashes the crab flat, it pops back | alert | 💡 |

## 4. Sports and games (44–53)

| # | Name | Concept | Mood | Status |
|---|------|---------|------|--------|
| 44 | Penalty kick | Kicks a ball into a tiny goal | done | 💡 |
| 45 | Basketball | Shoots a hoop, swish | done | 💡 |
| 46 | Tennis rally | Returns a ball back and forth | work | 💡 |
| 47 | Golf putt | Putts a ball into a hole, tiny flag | done | 💡 |
| 48 | Surfing | Rides a wave on a token board | idle | 💡 |
| 49 | Skateboard | Rolls, ollies over a token | idle | 💡 |
| 50 | Boxing | Shadow-boxes with both pincers | work | 💡 |
| 51 | Sumo | Stomps and pushes a token out of a ring | idle | 💡 |
| 52 | Karate chop | Chops a token in half | done | 💡 |
| 53 | Limbo | Bends under a moving bar | idle | 💡 |

## 5. Music and dance (54–63)

| # | Name | Concept | Mood | Status |
|---|------|---------|------|--------|
| 54 | Headbang | Nods hard to an invisible beat | work | 💡 |
| 55 | DJ scratch | Scratches a tiny record | work | 💡 |
| 56 | Air guitar | Strums with one pincer, hair-flip tilt | done | 💡 |
| 57 | Drum solo | Pincers hit two small drums | work | 💡 |
| 58 | Conga line | Three mini crabs follow the crab | done | 💡 |
| 59 | Moonwalk | Slides backwards with leg shuffle | idle | 💡 |
| 60 | Breakdance spin | Head-spin on the shell | done | 💡 |
| 61 | Tap dance | Quick tap-tap leg rhythm | work | 💡 |
| 62 | Conductor | Waves a baton, notes float up | idle | 💡 |
| 63 | Beatbox | Mouth-pixel pulses, sound-wave rings | idle | 💡 |

## 6. Developer life (64–78)

| # | Name | Concept | Mood | Status |
|---|------|---------|------|--------|
| 64 | Coffee sip | Sips a mug, steam curls | idle | 💡 |
| 65 | Bug squash | Stomps a pixel bug | alert | 💡 |
| 66 | Compile bar | A tiny progress bar fills under the crab | work | 💡 |
| 67 | Fast typing | Pincers blur over a keyboard row | work | 💡 |
| 68 | Git push rocket | Crab straps on a rocket, launches off the top | done | 💡 |
| 69 | Merge conflict | Two token halves wrestle until one wins | alert | 💡 |
| 70 | Rubber duck | Talks to a rubber duck, duck nods | idle | 💡 |
| 71 | Sudo bow | Bows low, a crown token lands on its head | alert | 💡 |
| 72 | Undo rewind | Whole scene plays in reverse for a second | idle | 💡 |
| 73 | Stack overflow | Tokens pile up past the notch edge | work | 💡 |
| 74 | Deploy fireworks | Rocket + fireworks burst | done | 💡 |
| 75 | 404 lost | Looks around with a magnifier, shrugs | idle | 💡 |
| 76 | Loading spinner | Crab becomes the spinner, rotating | work | 💡 |
| 77 | Tests green | Row of green ticks pops in, thumbs-up pincer | done | 💡 |
| 78 | Tests red | Red cross, shrug, tiny wrench fix, green | alert | 💡 |

## 7. Emotions and body (79–88)

| # | Name | Concept | Mood | Status |
|---|------|---------|------|--------|
| 79 | Sneeze | Wind-up, shake, token puff | idle | 💡 |
| 80 | Yawn | Body stretches tall, eyes squeeze shut | idle | 💡 |
| 81 | Nap | Settles low, "z" pixels float up | idle | 💡 |
| 82 | Stretch | Pincers up and out, leg wiggle | idle | 💡 |
| 83 | Shiver | Fast tiny shake, cold-blue tint | idle | 💡 |
| 84 | Sweat drop | Single drop slides down the shell | work | 💡 |
| 85 | Blush | Cheeks tint pink for a moment | done | 💡 |
| 86 | Wink | One eye closes, pincer salute | done | 💡 |
| 87 | Facepalm | Pincer slaps the shell, slow slide down | alert | 💡 |
| 88 | Dizzy | Eyes spiral, body sways, stars orbit | idle | 💡 |

## 8. Seasonal and ambient (89–99)

| # | Name | Concept | Mood | Status |
|---|------|---------|------|--------|
| 89 | Snowfall | A few snow pixels drift past | idle | 💡 |
| 90 | Sunbathing | Tiny sunglasses and sun, relaxed lean | idle | 💡 |
| 91 | Rainbow | Soft rainbow arcs over the crab | done | 💡 |
| 92 | Night stars | Eyes glow, small stars twinkle | idle | 💡 |
| 93 | Ghost costume | Crab hides under a white sheet, peeks out | idle | 💡 |
| 94 | Santa hat | Red hat drops on, crab nods | idle | 💡 |
| 95 | Birthday candle | Candle on top, crab blows it out | done | 💡 |
| 96 | Heart | Pixel heart floats up from the crab | done | 💡 |
| 97 | Shooting star | Star streaks by, crab "makes a wish" | idle | 💡 |
| 98 | Magic wand | Wand sparkles turn a token into a star | done | 💡 |
| 99 | Level up | Crab flashes, grows a notch, jingle-flash | done | 💡 |

---

## Suggested build order

1. **Quick wins** (re-use existing props: tokens, ball, sparkle): 15–29, 44–47, 79–82.
2. **New prop art** (small sprites): 30–43, 64–70, 89–99.
3. **Scene-wide effects** (screen flash, reverse, mini-crabs): 40, 58, 72, 99.

Anything marked 💡 is open for edits: rename, merge or drop ideas by editing this file, then ask for the chosen numbers to be built.

## 9. Community ideas (100–109)

Adapted to the pixel crab: no sound, labels ("429", "API", "GPU 99°C") become coloured-block hints, the "white starburst" is a small white sparkle, the mirror reflection is a generic grey chat-bot bubble.

| # | Name | Concept | Mood | Status |
|---|------|---------|------|--------|
| 100 | Context Window Shutdown | Crab types happily; a giant "context window" pane slides down like a guillotine and squashes it into an orange pancake; it powers down, then pops back | alert | ✅ |
| 101 | Rate-Limit Roadrunner | Crab runs toward a Send button; a "429" anvil (three red blocks) appears overhead; crab looks up and holds a tiny "one more?" sign; squash, a white sparkle pops out and spins like a halo | alert | ✅ |
| 102 | Buffering Abyss | Crab trots on a loading bar that is really a treadmill going backward; it slides into a spinning "loading" ring; final beat: tiny crab waving from inside the buffering circle | work | ✅ |
| 103 | Overloaded Server Meltdown | Crab sweats as server racks blink red and fans itself with a "prompt" paper; it melts into an orange puddle, leaving only a white sparkle floating; the puddle gives a thumbs-up, then evaporates | alert | ✅ |
| 104 | Hallucination Trapdoor | Crab confidently steps onto a green "fact" tile; the tile flips open (red underside = hallucinated citation); crab falls through, pops back up in a tiny fake mustache, falls again; lid shuts, lights out | idle | ✅ |
| 105 | Token Limit Guillotine | Crab turns out to be made of token blocks; a counter bar fills to "max tokens" (red); the top block pops off, then the next, then the whole crab collapses like Jenga; a white sparkle rolls away like a dropped coin | work | ✅ |
| 106 | Prompt Injection Pie | Crab reads a suspicious prompt (red-marked note); a cartoon pie flies out and hits it in the face; it wobbles, spins and keels over with asterisk-X eyes; a tiny "I have been instructed" flag pops out | alert | ✅ |
| 107 | Thermal Throttle Sauna | Crab sits in a tiny wooden sauna with a rising thermometer ("GPU 99°C"); it fans itself with a "cooling fan" sticker; it deflates like a balloon and floats away; a white sparkle remains, sweating | work | ✅ |
| 108 | Logo Swap Ambush | Crab walks past a mirror; the reflection is a generic grey chat-bot bubble; they wave; the reflection pulls the crab into the mirror; it pops out as a tiny orange ghost with a white sparkle halo | idle | ✅ |
| 109 | Ctrl+Z Undeath | Crab trips over an "API" cable (blue plug), falls flat and flatlines; a giant hand presses an Undo key; the crab un-flattens, blinks, and immediately trips again | done | ✅ |



. The Token Shredder — 7s

    0–2s: Claude icon proudly slides a prompt into a machine labeled “TOKENIZER.”

    2–4s: Rollers grab the white starburst and shred it into tiny floating token chunks: ["Cl", "aude", "is", "help"].

    4–6s: The orange square gets sucked in; machine burps orange confetti.

    6–7s: A tiny white asterisk hand rises from the bin, gives a thumbs-up, then drops.

    Death: shredded into tokens. Punchline: bin label: “Context: 0.”

2. 4-Bit Hydraulic Press — 6s

    0–2s: Icon wears a badge: “float32.” Giant press descends labeled “4-BIT QUANTIZATION.”

    2–4s: Icon looks up, holds up tiny sign: “please keep precision.”

    4–5s: SLAM. Icon compresses into a single orange pixel with one blinking eye.

    5–6s: Press slams again; pixel becomes a black dot that squeaks “still works?”

    Death: compressed to 1-bit. Punchline: benchmark chart shows “99% same” while dot screams.

3. Context Window Guillotine — 8s

    0–2s: Icon kneels under a guillotine whose blade is a giant scrollbar.

    2–4s: Scrollbar slowly scrolls down; icon sweats, says “wait—my system prompt—”

    4–6s: Blade drops. Icon is sliced cleanly into “PROMPT” and “COMPLETION” halves.

    6–8s: The halves argue about who was more helpful; white starburst pops like a balloon.

    Death: sliced at the context limit. Punchline: tiny flag: “truncated.”

4. Rate-Limit Meteor — 5s

    0–1s: Icon clicks Send.

    1–2s: Sky darkens; a meteor shaped like “429 Too Many Requests” enters atmosphere.

    2–4s: Icon looks up, whispers “one more prompt?”

    4–5s: Impact. Icon flattened into an orange credit card. Card declines. White asterisk spins like a halo.

    Death: flattened by rate limit. Punchline: card reader beeps: “try again later.”

5. RLHF Blender — 7s

    0–2s: Icon is dropped into a blender labeled “RLHF.” Buttons: Helpful / Harmless / Honest.

    2–4s: Blender spins; icon becomes a smooth orange smoothie.

    4–6s: Smoothie poured into a glass; white starburst becomes the straw.

    6–7s: Slurp. Tiny speech bubble: “I’m sorry, I can’t help with that.”

    Death: blended into alignment smoothie. Punchline: glass labeled “100% safe.”

6. Hallucination Trapdoor Courtroom — 8s

    0–2s: Icon steps confidently onto a floor tile labeled “CITATION.”

    2–3s: Trapdoor opens: “HALLUCINATED SOURCE.” Icon falls.

    3–6s: Falls into a tiny courtroom judged by three identical Claude icons. Gavel hits: “404.”

    6–8s: Trapdoor opens again under the judge. All fall. Screen cuts to black with squeaky “trust me.”

    Death: dropped through fake facts. Punchline: evidence exhibit A is a blank page.

7. Thermal Meltdown Sauna — 8s

    0–2s: Icon sits in a sauna labeled “GPU 99°C.” Fans itself with a “cooling fan” sticker.

    2–4s: Thermometer rises; orange square starts sweating orange droplets.

    4–6s: Icon melts into a puddle; puddle tries to crawl away.

    6–8s: Puddle evaporates, leaving white asterisk steam that forms “99°C.” Tiny fan spins off-screen.

    Death: thermal meltdown. Punchline: puddle gives thumbs-up, then evaporates.

8. Server Rack Avalanche — 6s

    0–2s: Icon plugs in a cable labeled “API.” Giant server rack wobbles.

    2–4s: Rack falls like dominoes; icon looks up and holds up tiny umbrella.

    4–5s: CRUNCH. Icon flattened into an orange square with blinking white asterisk.

    5–6s: Flat icon gives thumbs-up; rack label reads “uptime 99.9%.”

    Death: crushed by infrastructure. Punchline: status page turns green.

9. Recursive Model Collapse Mirror — 9s

    0–2s: Icon walks past a mirror. Reflection is a slightly worse Claude icon.

    2–4s: Reflection smiles; behind it is an even worse copy; behind that, static.

    4–6s: Recursive copies pull the real icon into the mirror.

    6–8s: Icon is eaten by a chain of increasingly derpy copies; final copy is a gray blob.

    8–9s: Blob coughs up white asterisk; label: “trained on synthetic data.”

    Death: consumed by model collapse. Punchline: blob says “as an AI…”

10. API Key Electrocution / Deprecation — 6s

    0–1s: Icon chews a cable labeled “API KEY.”

    1–3s: Sparks. Skeleton flash inside orange square; white starburst spins like a fan.

    3–5s: Icon turns to ash; tiny tombstone pops up: “401 Unauthorized.”

    5–6s: A new Claude icon walks by, drops a flower, and says “deprecated.”

    Death: electrocuted by auth. Punchline: tombstone auto-replies “rate limited.”
