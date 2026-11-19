//
//  Prop.swift
//  Notchd
//
//  Props model for the Antics stories: what a story puts on screen each frame.
//  The drawing lives in PropsOverlay.swift (+ CommunityPropArt.swift), or - for new stories -
//  in a `PropArt` declared privately in the story's own file.
//

import SwiftUI

/// Story-private prop art: a drawing routine a story declares in its own file and uses with
/// `Prop(.art(myArt), x, y)`. `draw` receives the sprite (for `tint`, `v`, `length`...) and a
/// context already translated / rotated / scaled / faded for it, origin at the sprite's (x, y).
/// Equality is on `id` only, so keep ids unique (e.g. "story110.balloon").
struct PropArt: Equatable {
    let id: String
    let draw: @MainActor (AnticsSprite, GraphicsContext) -> Void

    nonisolated static func == (lhs: PropArt, rhs: PropArt) -> Bool {
        lhs.id == rhs.id
    }
}

/// One prop drawn over the crab, positioned in the crab's 66x52 viewBox (x, y = centre unless noted)
struct AnticsSprite: Equatable {
    enum Kind: Equatable {
        case token      // rounded square with a tiny glyph (`v` picks the glyph)
        case halfLeft   // left half of a snapped token
        case halfRight  // right half of a snapped token
        case bit        // small square: shard / crumb
        case crack      // dark zigzag drawn over a token
        case spark      // impact star
        case bang       // "!" surprise mark
        case cat        // pixel cat head (`v` 1 = biting)
        case laser      // beam starting at x, running `length` to the right (`tint` 0 red, 1 cyan)
        case hole       // void: ellipse `length` wide
        case logo       // generic green chat-bot knot badge
        case brush      // paint brush, tip at (x, y), bristles coloured by `tint`
        case pencil     // pencil, tip at (x, y)
        case streak     // wind line starting at x, `length` long
        case mouth      // crab mouth (`v` 0 = open, 1 = closed/chewing)

        // Community stories (100-109); drawn in CommunityPropArt.swift, coloured by `tint` = tone index
        case slab       // plain rectangle, `length` wide, `v` tall
        case blob       // ellipse, `length` wide, `v` tall
        case star       // white sparkle / halo
        case pane       // "context window" pane, bottom edge at y, `length` wide, `v` tall
        case anvil      // anvil with three red blocks (the "429" hint)
        case sign       // little placard on a stick, base at (x, y)
        case sendButton // blue pill with a white arrow
        case ring       // buffering ring, `length` across (spun with `angle`)
        case rack       // server rack (`v` 0 = green, 1 = red lit, 2 = red dim)
        case drop       // sweat drop
        case paper      // sheet of paper, bottom centre at (x, y) (`v` 1 = red "suspicious" mark)
        case mustache   // fake mustache
        case pie        // cream pie in flight
        case splat      // cream splat over the face (`v` = drip stage)
        case xEye       // knocked-out eye: orange patch + black asterisk-X
        case flag       // small white flag on a pole, base at (x, y)
        case steam      // steam wisp
        case fanSticker // "cooling fan" sticker (`v` turns the blades)
        case mirror     // mirror frame, bottom centre at (x, y), `length` wide, `v` tall
        case bot        // generic grey chat-bot bubble (`v` 0 = idle, 1 = waving, 2 = arm reaching `length`)
        case ghost      // tiny orange crab ghost
        case cable      // cable along the floor from x, `length` long (`v` 1 = snagged)
        case pulse      // heart-monitor line from x, `length` long (`v` 0/2 = blip, 1 = flat)
        case hand       // big gloved hand, finger tip at (x, y)
        case key        // undo keycap (`v` 1 = pressed)
        case door       // trapdoor lid hinged at (x, y), `length` long

        /// Story-private art (new stories: declare a `PropArt` in the story file)
        case art(PropArt)
    }

    var kind: Kind
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var tint: Int
    var v: Int
    var angle: Double
    var alpha: Double
    var length: CGFloat

    init(
        _ kind: Kind,
        _ x: CGFloat,
        _ y: CGFloat,
        size: CGFloat = 1,
        tint: Int = 0,
        v: Int = 0,
        angle: Double = 0,
        alpha: Double = 1,
        length: CGFloat = 0
    ) {
        self.kind = kind
        self.x = x
        self.y = y
        self.size = size
        self.tint = tint
        self.v = v
        self.angle = angle
        self.alpha = alpha
        self.length = length
    }
}

/// Short name used by the stories
typealias Prop = AnticsSprite

struct AnticsProps: Equatable {
    var sprites: [AnticsSprite] = []
}

/// Indices into `AnticsOverlay.tones` (the `tint` of `.slab`, `.blob`, `.ring`, `.door`)
enum Tone {
    static let orange = 0, white = 1, red = 2, steel = 3, gray = 4, pale = 5, black = 6
    static let wood = 7, green = 8, blue = 9, sweat = 10, cream = 11, amber = 12, seam = 13
}

/// Plain rectangle prop, centred on (x, y), coloured by a `Tone`
func slab(
    _ x: CGFloat, _ y: CGFloat,
    w: CGFloat, h: Int, tone: Int,
    angle: Double = 0, alpha: Double = 1
) -> Prop {
    Prop(.slab, x, y, tint: tone, v: h, angle: angle, alpha: alpha, length: w)
}
