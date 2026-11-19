//
//  CommunityPropArt.swift
//  ClawNotch
//
//  Shared prop art first drawn for the community stories (100-109), coloured by `Tone`.
//  Labels from the original ideas ("429", "API", "GPU 99°C"...) are far too small to read at
//  14pt, so they are hinted with coloured blocks instead.
//

import SwiftUI

extension AnticsOverlay {

    static let tones: [Color] = [
        Color(red: 0.85, green: 0.47, blue: 0.34), // 0 crab orange
        .white,                                    // 1
        Color(red: 0.95, green: 0.26, blue: 0.24), // 2 red
        Color(red: 0.26, green: 0.27, blue: 0.32), // 3 steel
        Color(red: 0.56, green: 0.57, blue: 0.62), // 4 grey
        Color(red: 0.80, green: 0.81, blue: 0.85), // 5 pale grey
        .black,                                    // 6
        Color(red: 0.62, green: 0.44, blue: 0.27), // 7 wood
        Color(red: 0.36, green: 0.78, blue: 0.48), // 8 green
        Color(red: 0.33, green: 0.58, blue: 0.95), // 9 blue
        Color(red: 0.58, green: 0.84, blue: 1.00), // 10 sweat blue
        Color(red: 0.97, green: 0.93, blue: 0.82), // 11 cream
        Color(red: 1.00, green: 0.78, blue: 0.30), // 12 amber
        Color(red: 0.55, green: 0.27, blue: 0.18), // 13 dark orange (seams)
    ]

    /// Colour for a `Tone` index (clamped)
    static func tone(_ index: Int) -> Color {
        tones[min(max(index, 0), tones.count - 1)]
    }

    private static let anvilRows = [
        "HHHHHHHHHHHH",
        "XRXRXRXXXXX.",
        ".XXXXXXXXX..",
        "...XXXXX....",
        "...XXXXX....",
        ".XXXXXXXXX..",
        ".XXXXXXXXX..",
    ]

    private static let anvilColors: [Character: Color] = [
        "X": Color(red: 0.42, green: 0.44, blue: 0.50),
        "H": Color(red: 0.62, green: 0.64, blue: 0.70),
        "R": Color(red: 0.95, green: 0.26, blue: 0.24),
    ]

    private static let mustacheRows = [
        "X.......X",
        "XXXXXXXXX",
        ".XXX.XXX.",
    ]

    private static let handRows = [
        "..CCCC..",
        "..WWWW..",
        ".WWWWWW.",
        ".WWWWWW.",
        ".WWWWWW.",
        ".WWWWWW.",
        "...WW...",
        "...WW...",
        "...WW...",
    ]

    static func drawCommunity(_ sprite: AnticsSprite, in layer: GraphicsContext) {
        let tint = tone(sprite.tint)
        let length = max(sprite.length, 0)
        let height = CGFloat(max(sprite.v, 0))
        let orange = tone(Tone.orange)
        let steel = tone(Tone.steel)
        let pale = tone(Tone.pale)

        switch sprite.kind {
        case .slab:
            layer.fill(rect(-length / 2, -height / 2, length, height), with: .color(tint))

        case .blob:
            layer.fill(Path(ellipseIn: CGRect(x: -length / 2, y: -height / 2, width: length, height: height)), with: .color(tint))

        case .star:
            // White sparkle: a plus with four corner pixels
            layer.fill(rect(-1.3, -6.5, 2.6, 13), with: .color(.white))
            layer.fill(rect(-6.5, -1.3, 13, 2.6), with: .color(.white))
            for (x, y) in [(-4.2, -4.2), (2.2, -4.2), (-4.2, 2.2), (2.2, 2.2)] as [(CGFloat, CGFloat)] {
                layer.fill(rect(x, y, 2, 2), with: .color(.white.opacity(0.85)))
            }

        case .pane:
            // Window pane hanging from above; the bright bottom edge is the "blade"
            layer.fill(rect(-length / 2, -height, length, height), with: .color(Color(red: 0.70, green: 0.80, blue: 0.93).opacity(0.93)))
            layer.fill(rect(-length / 2, -height, length, 6), with: .color(Color(red: 0.33, green: 0.38, blue: 0.52)))
            for (index, dot) in [tone(Tone.red), tone(Tone.amber), tone(Tone.green)].enumerated() {
                layer.fill(rect(-length / 2 + 3 + CGFloat(index) * 4.5, -height + 1.5, 3, 3), with: .color(dot))
            }
            for row in 0..<3 {
                let width = length * (row == 1 ? 0.45 : 0.7)
                layer.fill(rect(-length / 2 + 6, -height + 12 + CGFloat(row) * 8, width, 2.5), with: .color(steel.opacity(0.45)))
            }
            layer.fill(rect(-length / 2, -3, length, 3), with: .color(.white))

        case .anvil:
            pixels(anvilRows, px: 2.6, colors: anvilColors, in: layer)

        case .sign:
            layer.fill(rect(-0.9, -10, 1.8, 10), with: .color(tone(Tone.wood)))
            layer.fill(rect(-7, -21, 14, 11), with: .color(.white))
            // "?"
            layer.fill(rect(-2, -19.5, 4, 1.6), with: .color(steel))
            layer.fill(rect(0.6, -19.5, 1.6, 4), with: .color(steel))
            layer.fill(rect(-0.8, -16.6, 1.6, 2), with: .color(steel))
            layer.fill(rect(-0.8, -13.4, 1.6, 1.6), with: .color(steel))

        case .sendButton:
            layer.fill(Path(roundedRect: CGRect(x: -10, y: -6, width: 20, height: 12), cornerRadius: 4), with: .color(tone(Tone.blue)))
            layer.fill(polygon([(-4, -3.5), (5.5, 0), (-4, 3.5), (-1.5, 0)]), with: .color(.white))

        case .ring:
            let radius = length / 2
            layer.stroke(
                Path(ellipseIn: CGRect(x: -radius, y: -radius, width: length, height: length)),
                with: .color(tint.opacity(0.22)),
                lineWidth: 3.2
            )
            var sweep = Path()
            sweep.addArc(center: .zero, radius: radius, startAngle: .degrees(0), endAngle: .degrees(240), clockwise: false)
            layer.stroke(sweep, with: .color(tint), lineWidth: 3.2)

        case .rack:
            layer.fill(Path(roundedRect: CGRect(x: -7, y: -16, width: 14, height: 32), cornerRadius: 1.5), with: .color(steel))
            for row in 0..<3 {
                let y = -13 + CGFloat(row) * 10
                layer.fill(rect(-5.5, y, 11, 7), with: .color(.black.opacity(0.45)))
                let led: Color
                switch sprite.v {
                case 1: led = tone(Tone.red)
                case 2: led = tone(Tone.red).opacity(row == 1 ? 1 : 0.35)
                default: led = tone(Tone.green)
                }
                layer.fill(rect(-4.5, y + 1.8, 3.4, 3.4), with: .color(led))
                layer.fill(rect(0.4, y + 2.7, 4, 1.6), with: .color(tone(Tone.gray)))
            }

        case .drop:
            let sweat = tone(Tone.sweat)
            layer.fill(rect(-0.8, -3.2, 1.6, 2.2), with: .color(sweat))
            layer.fill(rect(-1.7, -1.2, 3.4, 4), with: .color(sweat))

        case .paper:
            layer.fill(rect(-5, -14, 10, 14), with: .color(.white))
            for row in 0..<3 {
                let mark = sprite.v == 1 && row == 0
                layer.fill(
                    rect(-3.2, -11.6 + CGFloat(row) * 3.4, row == 2 ? 4 : 6.4, mark ? 2.2 : 1.4),
                    with: .color(mark ? tone(Tone.red) : tone(Tone.gray))
                )
            }

        case .mustache:
            pixels(mustacheRows, px: 2.4, colors: ["X": Color(red: 0.20, green: 0.11, blue: 0.07)], in: layer)

        case .pie:
            layer.fill(polygon([(-7.5, 0), (7.5, 0), (5.5, 5), (-5.5, 5)]), with: .color(Color(red: 0.82, green: 0.60, blue: 0.33)))
            layer.fill(Path(ellipseIn: CGRect(x: -6.5, y: -6, width: 13, height: 8)), with: .color(tone(Tone.cream)))
            layer.fill(rect(-1.3, -8, 2.6, 2.6), with: .color(tone(Tone.red)))

        case .splat:
            let cream = tone(Tone.cream)
            layer.fill(Path(ellipseIn: CGRect(x: -23, y: -8.5, width: 46, height: 17)), with: .color(cream))
            for (x, y) in [(-28, -4), (23, -11), (-15, -14), (12, -13.5), (25, 3)] as [(CGFloat, CGFloat)] {
                layer.fill(rect(x, y, 4.5, 4.5), with: .color(cream))
            }
            let drip = CGFloat(sprite.v)
            layer.fill(rect(-13, 6, 4, 3 + 3.5 * drip), with: .color(cream))
            layer.fill(rect(7, 6, 4, 2 + 4.5 * drip), with: .color(cream))

        case .xEye:
            layer.fill(rect(-5, -6, 10, 12), with: .color(orange))
            for points in [[(-3.4, -3.4), (3.4, 3.4)], [(-3.4, 3.4), (3.4, -3.4)], [(-4, 0), (4, 0)]] as [[(CGFloat, CGFloat)]] {
                layer.stroke(polygon(points, closed: false), with: .color(.black), lineWidth: 2)
            }

        case .flag:
            layer.fill(rect(-0.8, -18, 1.6, 18), with: .color(pale))
            layer.fill(rect(0.8, -18, 12, 8), with: .color(.white))
            layer.fill(rect(2.6, -16, 8, 1.4), with: .color(steel))
            layer.fill(rect(2.6, -13.2, 5, 1.4), with: .color(steel))

        case .steam:
            for (x, y) in [(-2.5, -6), (0.5, -2), (-2.5, 2)] as [(CGFloat, CGFloat)] {
                layer.fill(rect(x, y, 3, 3), with: .color(.white.opacity(0.65)))
            }

        case .fanSticker:
            layer.fill(Path(roundedRect: CGRect(x: -7, y: -7, width: 14, height: 14), cornerRadius: 2.5), with: .color(pale))
            var blades = layer
            blades.rotate(by: .degrees(Double(sprite.v) * 45))
            blades.fill(rect(-1.4, -5.5, 2.8, 11), with: .color(steel))
            blades.fill(rect(-5.5, -1.4, 11, 2.8), with: .color(steel))
            layer.fill(rect(-1.3, -1.3, 2.6, 2.6), with: .color(.white))

        case .mirror:
            let glass = CGRect(x: -length / 2, y: -height, width: length, height: height)
            layer.fill(Path(glass), with: .color(Color(red: 0.55, green: 0.72, blue: 0.85).opacity(0.28)))
            layer.stroke(Path(glass), with: .color(pale), lineWidth: 2.4)
            layer.stroke(
                polygon([(-length / 2 + 4, -height + 12), (-length / 2 + 10, -height + 4)], closed: false),
                with: .color(.white.opacity(0.6)),
                lineWidth: 1.6
            )
            layer.fill(rect(-length / 2 - 1.5, -1.5, 5, 3), with: .color(pale))
            layer.fill(rect(length / 2 - 3.5, -1.5, 5, 3), with: .color(pale))

        case .bot:
            // Generic chat-bot: a grey speech bubble with two eyes; its arm is on the crab's side
            let body = Color(red: 0.62, green: 0.63, blue: 0.68)
            switch sprite.v {
            case 1: layer.fill(rect(-15, -13, 3.6, 8), with: .color(body))
            case 2:
                layer.fill(rect(-11 - length, -3, length + 2, 4), with: .color(body))
                layer.fill(rect(-13.5 - length, -5.5, 3.5, 9), with: .color(body))
            default: layer.fill(rect(-14.6, -1, 3.6, 7), with: .color(body))
            }
            layer.fill(Path(roundedRect: CGRect(x: -11, y: -10, width: 22, height: 17), cornerRadius: 5), with: .color(body))
            layer.fill(polygon([(1.5, 6.5), (9, 12.5), (8, 6.5)]), with: .color(body))
            layer.fill(rect(-6.5, -4.5, 3.6, 4.2), with: .color(steel))
            layer.fill(rect(3, -4.5, 3.6, 4.2), with: .color(steel))

        case .ghost:
            layer.fill(rect(-6, -10, 12, 4), with: .color(orange))
            layer.fill(rect(-8, -6, 16, 12), with: .color(orange))
            for x in [-8, -2, 4] as [CGFloat] {
                layer.fill(rect(x, 6, 4, 3), with: .color(orange))
            }
            layer.fill(rect(-11, -3, 3, 5), with: .color(orange))
            layer.fill(rect(8, -3, 3, 5), with: .color(orange))
            layer.fill(rect(-5, -5, 3, 4), with: .color(.black))
            layer.fill(rect(2, -5, 3, 4), with: .color(.black))

        case .cable:
            let hump = length * 0.78
            let snagged = sprite.v == 1
            let spread: CGFloat = snagged ? 9 : 6
            let line = polygon(
                [(0, 0), (hump - spread, 0), (hump, snagged ? -8 : -3.5), (hump + spread, 0), (length, 0)],
                closed: false
            )
            layer.stroke(line, with: .color(tone(Tone.gray)), lineWidth: 2)
            layer.fill(rect(length - 2, -3, 6, 6), with: .color(tone(Tone.blue)))

        case .pulse:
            let line: Path
            if sprite.v == 1 {
                line = polygon([(0, 0), (length, 0)], closed: false)
            } else {
                let blip = length * (sprite.v == 0 ? 0.35 : 0.65)
                line = polygon([(0, 0), (blip - 5, 0), (blip - 2.5, -7), (blip, 5), (blip + 2.5, 0), (length, 0)], closed: false)
            }
            layer.stroke(line, with: .color(tone(Tone.green)), lineWidth: 1.8)

        case .hand:
            var glove = layer
            glove.translateBy(x: 0, y: -CGFloat(handRows.count) * 2.6 / 2)
            pixels(handRows, px: 2.6, colors: ["W": .white, "C": tone(Tone.blue)], in: glove)

        case .key:
            let pressed = sprite.v == 1
            let dip: CGFloat = pressed ? 2.5 : 0
            if !pressed {
                layer.fill(Path(roundedRect: CGRect(x: -8, y: -4, width: 16, height: 13), cornerRadius: 3), with: .color(tone(Tone.gray)))
            }
            layer.fill(Path(roundedRect: CGRect(x: -8, y: -7 + dip, width: 16, height: 13), cornerRadius: 3), with: .color(pale))
            // Undo arrow
            layer.fill(polygon([(-5.5, -0.5 + dip), (-1.5, -4 + dip), (-1.5, 3 + dip)]), with: .color(steel))
            layer.fill(rect(-1.5, -1.6 + dip, 6.5, 2.2), with: .color(steel))

        case .door:
            layer.fill(rect(0, -2.5, length, 5), with: .color(tint))
            layer.fill(rect(0, -2.5, length, 1.3), with: .color(.white.opacity(0.35)))

        default:
            break
        }
    }
}
