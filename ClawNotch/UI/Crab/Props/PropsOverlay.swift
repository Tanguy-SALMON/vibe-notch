//
//  PropsOverlay.swift
//  ClawNotch
//
//  Draws the Antics props over the crab. Only in the view tree while a story has sprites on
//  screen, so it costs nothing at rest.
//

import SwiftUI

/// Draws the props in the crab's coordinate space. The canvas extends a few points beyond the crab
/// frame (the closed notch leaves ~6pt each side and ~9pt above/below a 14pt crab); anything
/// further out is clipped by the canvas itself.
struct AnticsOverlay: View {
    let props: AnticsProps
    let size: CGFloat

    // Extra room around the 66x52 viewBox, in viewBox units
    static let padX: CGFloat = 20
    static let padTop: CGFloat = 26
    static let padBottom: CGFloat = 12

    /// App orange + a few muted accents; 5 = unpainted grey
    static let palette: [Color] = [
        Color(red: 0.85, green: 0.47, blue: 0.34),
        Color(red: 0.89, green: 0.76, blue: 0.52),
        Color(red: 0.42, green: 0.68, blue: 0.66),
        Color(red: 0.62, green: 0.56, blue: 0.80),
        Color(red: 0.82, green: 0.50, blue: 0.58),
        Color(red: 0.45, green: 0.45, blue: 0.48),
    ]

    var body: some View {
        let unit = size / 52.0
        Canvas { context, _ in
            for sprite in props.sprites {
                var layer = context
                layer.translateBy(x: (sprite.x + Self.padX) * unit, y: (sprite.y + Self.padTop) * unit)
                if sprite.angle != 0 { layer.rotate(by: .degrees(sprite.angle)) }
                layer.scaleBy(x: unit * sprite.size, y: unit * sprite.size)
                layer.opacity = min(max(sprite.alpha, 0), 1)
                Self.draw(sprite, in: layer)
            }
        }
        .frame(width: (66 + Self.padX * 2) * unit, height: (52 + Self.padTop + Self.padBottom) * unit)
        .offset(x: -Self.padX * unit, y: -Self.padTop * unit)
        .allowsHitTesting(false)
    }

    static func tintColor(_ index: Int) -> Color {
        palette[((index % palette.count) + palette.count) % palette.count]
    }

    static func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
        Path(CGRect(x: x, y: y, width: w, height: h))
    }

    static func polygon(_ points: [(CGFloat, CGFloat)], closed: Bool = true) -> Path {
        var path = Path()
        for (index, point) in points.enumerated() {
            let cgPoint = CGPoint(x: point.0, y: point.1)
            if index == 0 { path.move(to: cgPoint) } else { path.addLine(to: cgPoint) }
        }
        if closed { path.closeSubpath() }
        return path
    }

    /// Pixel map centred on the origin; "." = transparent
    static func pixels(_ rows: [String], px: CGFloat, colors: [Character: Color], in layer: GraphicsContext) {
        let width = CGFloat(rows.map(\.count).max() ?? 0) * px
        let height = CGFloat(rows.count) * px
        for (rowIndex, row) in rows.enumerated() {
            for (columnIndex, character) in row.enumerated() {
                guard let color = colors[character] else { continue }
                // Slight overlap so neighbouring pixels leave no anti-aliased seams
                let pixel = rect(CGFloat(columnIndex) * px - width / 2, CGFloat(rowIndex) * px - height / 2, px + 0.2, px + 0.2)
                layer.fill(pixel, with: .color(color))
            }
        }
    }

    private static let catRows = [
        "XX.......XX",
        "XXX.....XXX",
        "XXXXXXXXXXX",
        "XXEXXXXXEXX",
        "XXEXXXXXEXX",
        "XXXXXNXXXXX",
        ".XXXXXXXXX.",
        "..XXXXXXX..",
    ]

    private static let catBitingRows = [
        "XX.......XX",
        "XXX.....XXX",
        "XXXXXXXXXXX",
        "XEEXXXXXEEX",
        "XXXXXXXXXXX",
        "XXXXXNXXXXX",
        ".XXWKKKWXX.",
        "..XXKKKXX..",
    ]

    private static let catColors: [Character: Color] = [
        "X": Color(red: 0.66, green: 0.66, blue: 0.70),
        "E": Color(red: 0.78, green: 0.92, blue: 0.40),
        "N": Color(red: 0.92, green: 0.58, blue: 0.64),
        "W": .white,
        "K": Color(red: 0.25, green: 0.10, blue: 0.12),
    ]

    private static func draw(_ sprite: AnticsSprite, in layer: GraphicsContext) {
        let tint = tintColor(sprite.tint)
        let ink = Color.black.opacity(0.55)

        switch sprite.kind {
        case .art(let art):
            // Story-private art, declared in the story's own file
            art.draw(sprite, layer)

        case .token:
            layer.fill(Path(roundedRect: CGRect(x: -7, y: -7, width: 14, height: 14), cornerRadius: 3), with: .color(tint))
            switch ((sprite.v % 3) + 3) % 3 {
            case 0: // "T"
                layer.fill(rect(-4, -4, 8, 2.5), with: .color(ink))
                layer.fill(rect(-1.25, -4, 2.5, 8), with: .color(ink))
            case 1: // "="
                layer.fill(rect(-4, -3.5, 8, 2.5), with: .color(ink))
                layer.fill(rect(-4, 1, 8, 2.5), with: .color(ink))
            default: // dot
                layer.fill(rect(-2.5, -2.5, 5, 5), with: .color(ink))
            }

        case .halfLeft:
            layer.fill(polygon([(-7, -7), (0, -7), (-2, -3), (1, 0), (-2, 3), (0, 7), (-7, 7)]), with: .color(tint))
            layer.fill(rect(-5, -4, 3, 2.5), with: .color(ink))

        case .halfRight:
            layer.fill(polygon([(0, -7), (7, -7), (7, 7), (0, 7), (-2, 3), (1, 0), (-2, -3)]), with: .color(tint))
            layer.fill(rect(2.5, -4, 2.5, 2.5), with: .color(ink))

        case .bit:
            layer.fill(rect(-2.5, -2.5, 5, 5), with: .color(tint))

        case .crack:
            layer.stroke(
                polygon([(0, -7), (-2, -3), (1, 0), (-2, 3), (0, 7)], closed: false),
                with: .color(.black),
                lineWidth: 1.8
            )

        case .spark:
            let glow = Color(red: 1, green: 0.95, blue: 0.7)
            layer.fill(rect(-1.2, -6, 2.4, 12), with: .color(glow))
            layer.fill(rect(-6, -1.2, 12, 2.4), with: .color(glow))

        case .bang:
            let warning = Color(red: 1, green: 0.82, blue: 0.3)
            layer.fill(rect(-1.5, -7, 3, 9), with: .color(warning))
            layer.fill(rect(-1.5, 4, 3, 3), with: .color(warning))

        case .cat:
            pixels(sprite.v == 1 ? catBitingRows : catRows, px: 2.4,colors: catColors, in: layer)

        case .laser:
            let beam = sprite.tint == 1
                ? Color(red: 0.3, green: 0.9, blue: 1)
                : Color(red: 1, green: 0.25, blue: 0.3)
            let length = max(sprite.length, 0)
            layer.fill(rect(0, -3.5, length, 7), with: .color(beam.opacity(0.28)))
            layer.fill(rect(0, -1.3, length, 2.6), with: .color(beam))
            layer.fill(rect(length - 4, -2.2, 4.4, 4.4), with: .color(.white))

        case .hole:
            let width = max(sprite.length, 0)
            let rim = Path(ellipseIn: CGRect(x: -width / 2, y: -6, width: width, height: 12))
            layer.fill(rim, with: .color(Color(red: 0.36, green: 0.28, blue: 0.62)))
            let pit = Path(ellipseIn: CGRect(x: -width / 2 + 3, y: -3.5, width: max(width - 6, 0), height: 8.5))
            layer.fill(pit, with: .color(Color(red: 0.05, green: 0.03, blue: 0.10)))

        case .logo:
            // Generic "AI knot" badge: green disc, pale ring, three spokes
            let pale = Color.white.opacity(0.92)
            layer.fill(Path(ellipseIn: CGRect(x: -9, y: -9, width: 18, height: 18)), with: .color(Color(red: 0.29, green: 0.64, blue: 0.54)))
            layer.stroke(Path(ellipseIn: CGRect(x: -4, y: -4, width: 8, height: 8)), with: .color(pale), lineWidth: 1.8)
            for spoke in 0..<3 {
                let radians = CGFloat(spoke) * 2 * .pi / 3 - .pi / 2
                var line = Path()
                line.move(to: CGPoint(x: cos(radians) * 4, y: sin(radians) * 4))
                line.addLine(to: CGPoint(x: cos(radians) * 7.2, y: sin(radians) * 7.2))
                layer.stroke(line, with: .color(pale), lineWidth: 1.8)
            }

        case .brush:
            var handle = Path()
            handle.move(to: CGPoint(x: 1, y: -2))
            handle.addLine(to: CGPoint(x: 7, y: -12))
            layer.stroke(handle, with: .color(Color(red: 0.72, green: 0.56, blue: 0.38)), lineWidth: 2.6)
            layer.fill(rect(-3, -3, 6, 5), with: .color(tint))

        case .pencil:
            var shaft = Path()
            shaft.move(to: CGPoint(x: 1, y: -2))
            shaft.addLine(to: CGPoint(x: 6, y: -11))
            layer.stroke(shaft, with: .color(Color(red: 0.96, green: 0.82, blue: 0.32)), lineWidth: 2.8)
            layer.fill(rect(-1.2, -2.2, 2.6, 2.6), with: .color(.white))

        case .streak:
            layer.fill(rect(0, -0.7, max(sprite.length, 0), 1.4), with: .color(.white))

        case .mouth:
            if sprite.v == 0 {
                layer.fill(rect(-6, -3.5, 12, 8), with: .color(.black))
            } else {
                layer.fill(rect(-5, -1, 10, 2.4), with: .color(.black))
            }

        default:
            drawCommunity(sprite, in: layer)
        }
    }
}
