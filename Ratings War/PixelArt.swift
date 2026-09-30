import SpriteKit

/// 16-bit-style art drawn in code: each sprite is a grid of palette characters, one per pixel.
enum PixelArt {
    /// World points per art pixel.
    static let pixelSize: CGFloat = 2

    private static let palette: [Character: (r: CGFloat, g: CGFloat, b: CGFloat)] = [
        "k": (0.06, 0.05, 0.10),  // outline
        "w": (1.00, 1.00, 1.00),
        "s": (1.00, 0.80, 0.62),  // skin
        "b": (0.25, 0.55, 1.00),
        "B": (0.13, 0.27, 0.66),
        "r": (0.93, 0.22, 0.22),
        "R": (0.60, 0.10, 0.16),
        "g": (0.35, 0.80, 0.35),
        "G": (0.13, 0.48, 0.22),
        "y": (1.00, 0.86, 0.20),
        "o": (0.96, 0.52, 0.12),
        "p": (0.66, 0.38, 0.95),
        "P": (0.38, 0.18, 0.62),
        "n": (0.58, 0.38, 0.18),  // wood
        "d": (0.28, 0.12, 0.20),  // empty heart
    ]

    static let player = [
        "...kkkkkk...",
        "..knnnnnnk..",
        ".knnnnnnnnk.",
        ".knssssssnk.",
        ".kskssssksk.",
        ".kssssssssk.",
        "..kssRRssk..",
        "...kssssk...",
        ".kkggggggkk.",
        "ksggggggggsk",
        "ksggggggggsk",
        ".kkBBBBBBkk.",
        "..kBBkkBBk..",
        "..kwwkkwwk..",
    ]

    static let grunt = [
        "...kkkkkk...",
        "..krrrrrrk..",
        ".krrrrrrrrk.",
        ".krwkrrkwrk.",
        ".krrrrrrrrk.",
        ".krrkwwkrrk.",
        "..krrrrrrknn",
        ".kkRRRRRRknn",
        "kRkRRRRRRkn.",
        "kRkRRRRRRkn.",
        ".kkRRkkRRk..",
        "..kkk..kkk..",
    ]

    static let bruiser = [
        ".kk..........kk.",
        "kwwk.kkkkkk.kwwk",
        ".kwkkppppppkkwk.",
        "..kppppppppppk..",
        ".kppppppppppppk.",
        ".kppwwkppkwwppk.",
        ".kppwkkppkkwppk.",
        ".kppppppppppppk.",
        ".kppkwkwwkwkppk.",
        ".kppkkkkkkkkppk.",
        "..kppppppppppk..",
        ".kkPPPPPPPPPPkk.",
        "kPPkPPPPPPPPkPPk",
        "kPPkPPPPPPPPkPPk",
        ".kkkPPPkkPPPkkk.",
        "...kkkk..kkkk...",
    ]

    static let bullet = [
        ".yy.",
        "ywwy",
        "ywwy",
        ".yy.",
    ]

    static let cash = [
        "kkkkkkkkkkkk",
        "kggggggggggk",
        "kgGggyyggGgk",
        "kgggyggygggk",
        "kgggyggygggk",
        "kgGggyyggGgk",
        "kggggggggggk",
        "kkkkkkkkkkkk",
    ]

    static let heart = [
        ".kk...kk.",
        "krrk.krrk",
        "krwrkrrrk",
        "krrrrrrrk",
        ".krrrrrk.",
        "..krrrk..",
        "...krk...",
        "....k....",
    ]

    static let halfHeart = [
        ".kk...kk.",
        "krrk.kddk",
        "krwrkdddk",
        "krrrddddk",
        ".krrdddk.",
        "..krddk..",
        "...kdk...",
        "....k....",
    ]

    static let emptyHeart = [
        ".kk...kk.",
        "kddk.kddk",
        "kdddkdddk",
        "kdddddddk",
        ".kdddddk.",
        "..kdddk..",
        "...kdk...",
        "....k....",
    ]

    static let shadow = [
        ".kkkkkkkkkk.",
        "kkkkkkkkkkkk",
        ".kkkkkkkkkk.",
    ]

    static let spread = [
        "kkkkkkkkkk",
        "koooooooyk",
        "koooooyyok",
        "koooyyoook",
        "kwwyyyyyyk",
        "koooyyoook",
        "koooooyyok",
        "koooooooyk",
        "kooooooook",
        "kkkkkkkkkk",
    ]

    static let rapid = [
        "kkkkkkkkkk",
        "kBBBByyBBk",
        "kBBByyBBBk",
        "kBByyBBBBk",
        "kByyyyyBBk",
        "kBBByyBBBk",
        "kBByyBBBBk",
        "kByyBBBBBk",
        "kBBBBBBBBk",
        "kkkkkkkkkk",
    ]

    static func texture(_ rows: [String]) -> SKTexture {
        let height = rows.count
        let width = rows.map(\.count).max() ?? 0
        guard let context = bitmap(width: width, height: height) else { return SKTexture() }
        for (y, row) in rows.enumerated() {
            for (x, character) in row.enumerated() {
                guard let color = palette[character] else { continue }
                context.setFillColor(red: color.r, green: color.g, blue: color.b, alpha: 1)
                context.fill(CGRect(x: x, y: height - 1 - y, width: 1, height: 1))
            }
        }
        return finish(context)
    }

    /// The arena in one texture: a tall back wall seen face-on (the 3/4 top-down view), light metal side
    /// and front walls, a grey studio floor with walkways leading in from each door, floor vents, and a
    /// raised octagon stage in the middle. All sizes are in world points.
    static func arenaTexture(arena: CGSize, wall: CGFloat, backWall: CGFloat, door: CGFloat) -> SKTexture {
        let width = Int((arena.width + 2 * wall) / pixelSize)
        let height = Int((arena.height + wall + backWall) / pixelSize)
        let wallPixels = Int(wall / pixelSize)
        let backPixels = Int(backWall / pixelSize)
        let doorPixels = Int(door / pixelSize)
        let floorTop = height - backPixels
        let floorWidth = width - 2 * wallPixels
        let floorHeight = floorTop - wallPixels
        let centreX = width / 2
        let centreY = wallPixels + floorHeight / 2
        guard let context = bitmap(width: width, height: height) else { return SKTexture() }
        context.setShouldAntialias(false)

        func fill(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ x: Int, _ y: Int, _ w: Int, _ h: Int) {
            context.setFillColor(red: r, green: g, blue: b, alpha: 1)
            context.fill(CGRect(x: x, y: y, width: w, height: h))
        }
        func polygon(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ points: [(Int, Int)]) {
            context.setFillColor(red: r, green: g, blue: b, alpha: 1)
            context.beginPath()
            context.move(to: CGPoint(x: points[0].0, y: points[0].1))
            for point in points.dropFirst() { context.addLine(to: CGPoint(x: point.0, y: point.1)) }
            context.closePath()
            context.fillPath()
        }

        // Floor: grey metal with large panel seams.
        fill(0.36, 0.36, 0.42, 0, 0, width, height)
        for x in stride(from: wallPixels, to: width - wallPixels, by: 30) { fill(0.32, 0.32, 0.38, x, wallPixels, 1, floorHeight) }
        for y in stride(from: wallPixels, to: floorTop, by: 30) { fill(0.32, 0.32, 0.38, wallPixels, y, floorWidth, 1) }

        // Floor vents, placed symmetrically.
        for (dx, dy) in [(-110, 70), (110, 70), (-110, -70), (110, -70), (-60, 100), (60, 100), (-60, -100), (60, -100)] {
            let x = centreX + dx - 6
            let y = centreY + dy - 4
            fill(0.22, 0.22, 0.27, x, y, 12, 8)
            for slot in 0..<3 { fill(0.10, 0.10, 0.13, x + 2 + slot * 3, y + 2, 2, 4) }
        }

        // Raised octagon stage with four red chevrons pointing in.
        let r = 42, c = 17
        polygon(0.20, 0.20, 0.25, [(centreX - r + c, centreY - r - 1), (centreX + r - c, centreY - r - 1), (centreX + r + 1, centreY - r + c),
                                   (centreX + r + 1, centreY + r - c), (centreX + r - c, centreY + r + 1), (centreX - r + c, centreY + r + 1),
                                   (centreX - r - 1, centreY + r - c), (centreX - r - 1, centreY - r + c)])
        polygon(0.30, 0.30, 0.36, [(centreX - r + c, centreY - r), (centreX + r - c, centreY - r), (centreX + r, centreY - r + c),
                                   (centreX + r, centreY + r - c), (centreX + r - c, centreY + r), (centreX - r + c, centreY + r),
                                   (centreX - r, centreY + r - c), (centreX - r, centreY - r + c)])
        for (dx, dy) in [(0, 1), (0, -1), (1, 0), (-1, 0)] {
            let tipX = centreX + dx * 14, tipY = centreY + dy * 14
            let baseX = centreX + dx * 30, baseY = centreY + dy * 30
            let px = dy * 12, py = dx * 12
            polygon(0.80, 0.16, 0.22, [(tipX, tipY), (baseX + px, baseY + py), (baseX - px, baseY - py)])
        }

        // Walkways leading in from each door: stepped ramps with light rails.
        let rampLength = 44
        let doorX = centreX - doorPixels / 2
        let doorY = centreY - doorPixels / 2
        for (x, y, w, h, vertical) in [(doorX, floorTop - rampLength, doorPixels, rampLength, true),
                                        (doorX, wallPixels, doorPixels, rampLength, true),
                                        (wallPixels, doorY, rampLength + 26, doorPixels, false),
                                        (width - wallPixels - rampLength - 26, doorY, rampLength + 26, doorPixels, false)] {
            fill(0.22, 0.22, 0.27, x, y, w, h)
            if vertical {
                for step in stride(from: y, to: y + h, by: 3) { fill(0.30, 0.30, 0.36, x + 3, step, w - 6, 1) }
                fill(0.66, 0.66, 0.74, x, y, 2, h)
                fill(0.66, 0.66, 0.74, x + w - 2, y, 2, h)
            } else {
                for slat in stride(from: x, to: x + w, by: 3) { fill(0.30, 0.30, 0.36, slat, y + 3, 1, h - 6) }
                fill(0.66, 0.66, 0.74, x, y, w, 2)
                fill(0.66, 0.66, 0.74, x, y + h - 2, w, 2)
            }
        }
        // Red warning bars where each walkway meets the floor.
        fill(0.85, 0.18, 0.22, doorX + 6, floorTop - rampLength - 2, doorPixels - 12, 2)
        fill(0.85, 0.18, 0.22, doorX + 6, wallPixels + rampLength, doorPixels - 12, 2)
        fill(0.85, 0.18, 0.22, wallPixels + rampLength + 26, doorY + 6, 2, doorPixels - 12)
        fill(0.85, 0.18, 0.22, width - wallPixels - rampLength - 28, doorY + 6, 2, doorPixels - 12)

        // Back wall face: grey machinery panels with a purple trim band and vents.
        fill(0.44, 0.44, 0.50, 0, floorTop, width, backPixels)
        for x in stride(from: wallPixels, to: width, by: 22) { fill(0.34, 0.34, 0.40, x, floorTop, 1, backPixels) }
        fill(0.42, 0.26, 0.52, 0, floorTop + 4, width, 3)
        fill(0.06, 0.05, 0.10, 0, floorTop, width, 2)
        fill(0.84, 0.84, 0.90, 0, height - 3, width, 3)
        for x in stride(from: wallPixels + 10, to: width - wallPixels - 8, by: 44) {
            fill(0.26, 0.26, 0.31, x, height - 10, 12, 5)
        }

        // Side and front walls: a light metal bezel with seams and red accent lights.
        for x in [0, width - wallPixels] {
            fill(0.82, 0.82, 0.88, x, 0, wallPixels, height)
            for y in stride(from: 0, to: height, by: 16) { fill(0.62, 0.62, 0.70, x, y, wallPixels, 1) }
            fill(0.80, 0.18, 0.22, x + wallPixels / 2 - 1, centreY + doorPixels / 2 + 8, 2, 40)
            fill(0.80, 0.18, 0.22, x + wallPixels / 2 - 1, centreY - doorPixels / 2 - 48, 2, 40)
        }
        fill(0.82, 0.82, 0.88, 0, 0, width, wallPixels)
        for x in stride(from: 0, to: width, by: 16) { fill(0.62, 0.62, 0.70, x, 0, 1, wallPixels) }
        fill(0.06, 0.05, 0.10, wallPixels - 1, wallPixels - 1, 1, floorHeight + 1)
        fill(0.06, 0.05, 0.10, width - wallPixels, wallPixels - 1, 1, floorHeight + 1)
        fill(0.06, 0.05, 0.10, wallPixels - 1, wallPixels - 1, floorWidth + 2, 1)

        // Door openings.
        fill(0.66, 0.66, 0.74, doorX - 3, floorTop, doorPixels + 6, backPixels - 6)
        fill(0.03, 0.03, 0.06, doorX, floorTop, doorPixels, backPixels - 9)
        fill(0.03, 0.03, 0.06, doorX, 0, doorPixels, wallPixels)
        fill(0.03, 0.03, 0.06, 0, doorY, wallPixels, doorPixels)
        fill(0.03, 0.03, 0.06, width - wallPixels, doorY, wallPixels, doorPixels)
        return finish(context)
    }

    /// LCD-style digits 0-9, 5x7 pixels: lit segments bright blue, unlit ones faintly visible like a real display.
    static let digits: [SKTexture] = {
        // Segments: a top, b upper right, c lower right, d bottom, e lower left, f upper left, g middle.
        let litSegments = ["abcdef", "bc", "abged", "abgcd", "fgbc", "afgcd", "afgedc", "abc", "abcdefg", "abcdfg"]
        let segmentPixels: [Character: [(Int, Int)]] = [
            "a": [(1, 0), (2, 0), (3, 0)], "g": [(1, 3), (2, 3), (3, 3)], "d": [(1, 6), (2, 6), (3, 6)],
            "f": [(0, 1), (0, 2)], "b": [(4, 1), (4, 2)], "e": [(0, 4), (0, 5)], "c": [(4, 4), (4, 5)],
        ]
        return litSegments.map { lit in
            guard let context = bitmap(width: 5, height: 7) else { return SKTexture() }
            for (segment, pixels) in segmentPixels {
                if lit.contains(segment) {
                    context.setFillColor(red: 0.55, green: 0.82, blue: 1.00, alpha: 1)
                } else {
                    context.setFillColor(red: 0.07, green: 0.11, blue: 0.26, alpha: 1)
                }
                for (x, y) in pixels {
                    context.fill(CGRect(x: x, y: 6 - y, width: 1, height: 1))
                }
            }
            return finish(context)
        }
    }()

    /// A scoreboard panel: a light metal bezel around a dark display, with an optional bar strip along the bottom.
    static func panelTexture(size: CGSize, hasBar: Bool) -> SKTexture {
        let width = Int(size.width / pixelSize)
        let height = Int(size.height / pixelSize)
        guard let context = bitmap(width: width, height: height) else { return SKTexture() }
        func fill(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ x: Int, _ y: Int, _ w: Int, _ h: Int) {
            context.setFillColor(red: r, green: g, blue: b, alpha: 1)
            context.fill(CGRect(x: x, y: y, width: w, height: h))
        }
        fill(0.78, 0.78, 0.84, 0, 0, width, height)
        fill(0.55, 0.55, 0.62, 0, 0, width, 1)
        fill(0.20, 0.20, 0.26, 1, 1, width - 2, height - 2)
        let displayBottom = hasBar ? 10 : 3
        fill(0.03, 0.05, 0.16, 3, displayBottom, width - 6, height - 3 - displayBottom)
        if hasBar {
            fill(0.06, 0.06, 0.10, 3, 3, width - 6, 6)
        }
        return finish(context)
    }

    private static func bitmap(width: Int, height: Int) -> CGContext? {
        CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    private static func finish(_ context: CGContext) -> SKTexture {
        guard let image = context.makeImage() else { return SKTexture() }
        let texture = SKTexture(cgImage: image)
        // Nearest-neighbour keeps the pixels crisp when scaled up.
        texture.filteringMode = .nearest
        return texture
    }
}
