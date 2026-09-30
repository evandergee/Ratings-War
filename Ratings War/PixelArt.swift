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
    ]

    static let player = [
        "....kkkk....",
        "..kkbbbbkk..",
        ".kbbbwwbbbk.",
        ".kbbbbbbbbk.",
        ".kkkkkkkkkk.",
        "..kswsswsk..",
        "..kskssksk..",
        "..kssssssk..",
        ".kkrrrrrrkk.",
        "ksrryyyyrrsk",
        "ksrrrrrrrrsk",
        ".kkBBBBBBkk.",
        "..kBBkkBBk..",
        "..kkk..kkk..",
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

    /// Walls, doors and a checkered studio floor in one texture. All sizes are in world points.
    static func arenaTexture(arena: CGSize, wall: CGFloat, door: CGFloat) -> SKTexture {
        let width = Int((arena.width + 2 * wall) / pixelSize)
        let height = Int((arena.height + 2 * wall) / pixelSize)
        let wallPixels = Int(wall / pixelSize)
        let doorPixels = Int(door / pixelSize)
        let tile = 24
        guard let context = bitmap(width: width, height: height) else { return SKTexture() }

        func fill(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ x: Int, _ y: Int, _ w: Int, _ h: Int) {
            context.setFillColor(red: r, green: g, blue: b, alpha: 1)
            context.fill(CGRect(x: x, y: y, width: w, height: h))
        }

        // Steel wall panels with seams, a lit outer rim and a dark inner edge.
        fill(0.38, 0.44, 0.64, 0, 0, width, height)
        for x in stride(from: 0, to: width, by: 12) { fill(0.24, 0.28, 0.44, x, 0, 1, height) }
        for y in stride(from: 0, to: height, by: 12) { fill(0.24, 0.28, 0.44, 0, y, width, 1) }
        fill(0.62, 0.70, 0.90, 0, height - 1, width, 1)
        fill(0.62, 0.70, 0.90, 0, 0, 1, height)
        fill(0.06, 0.05, 0.10, wallPixels - 1, wallPixels - 1, width - 2 * wallPixels + 2, height - 2 * wallPixels + 2)

        // Checkered floor.
        let floorWidth = width - 2 * wallPixels
        let floorHeight = height - 2 * wallPixels
        for row in 0..<(floorHeight / tile) {
            for column in 0..<(floorWidth / tile) {
                let x = wallPixels + column * tile
                let y = wallPixels + row * tile
                if (row + column).isMultiple(of: 2) {
                    fill(0.17, 0.18, 0.33, x, y, tile, tile)
                } else {
                    fill(0.13, 0.13, 0.26, x, y, tile, tile)
                }
                fill(0.22, 0.24, 0.42, x, y + tile - 1, tile, 1)
            }
        }

        // Studio emblem on the centre of the floor.
        context.setShouldAntialias(false)
        context.setLineWidth(2)
        context.setStrokeColor(red: 0.36, green: 0.22, blue: 0.40, alpha: 1)
        context.strokeEllipse(in: CGRect(x: width / 2 - 34, y: height / 2 - 34, width: 68, height: 68))
        context.setStrokeColor(red: 0.40, green: 0.38, blue: 0.34, alpha: 1)
        context.strokeEllipse(in: CGRect(x: width / 2 - 26, y: height / 2 - 26, width: 52, height: 52))

        // Doors: a dark opening with a hazard-striped threshold.
        let doorX = (width - doorPixels) / 2
        let doorY = (height - doorPixels) / 2
        fill(0.03, 0.03, 0.06, doorX, height - wallPixels, doorPixels, wallPixels)
        fill(0.03, 0.03, 0.06, doorX, 0, doorPixels, wallPixels)
        fill(0.03, 0.03, 0.06, 0, doorY, wallPixels, doorPixels)
        fill(0.03, 0.03, 0.06, width - wallPixels, doorY, wallPixels, doorPixels)
        for step in 0..<(doorPixels / 6) where step.isMultiple(of: 2) {
            fill(1.00, 0.86, 0.20, doorX + step * 6, height - wallPixels, 6, 2)
            fill(1.00, 0.86, 0.20, doorX + step * 6, wallPixels - 2, 6, 2)
            fill(1.00, 0.86, 0.20, wallPixels - 2, doorY + step * 6, 2, 6)
            fill(1.00, 0.86, 0.20, width - wallPixels, doorY + step * 6, 2, 6)
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
