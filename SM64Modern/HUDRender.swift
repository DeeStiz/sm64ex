import Foundation

enum SM64HUDRenderKind: UInt8, Equatable, Sendable {
    case glyph = 1
    case powerMeterBase = 2
    case powerMeterHealth = 3
}

struct SM64HUDLayout: Equatable, Sendable {
    let screenWidth: Int32
    let screenHeight: Int32
    let aspectRatio: Double
    let japanese: Bool

    init(
        screenWidth: Int32 = 320,
        screenHeight: Int32 = 240,
        aspectRatio: Double = 4.0 / 3.0,
        japanese: Bool = false
    ) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.aspectRatio = aspectRatio
        self.japanese = japanese
    }

    var hudTopY: Int32 { japanese ? 210 : 209 }
    var starsX: Int32 { japanese ? 73 : 78 }

    func leftEdge(_ offset: Int32) -> Int32 {
        Int32(floor(
            Double(screenWidth) / 2.0
                - Double(screenHeight) / 2.0 * aspectRatio
                + Double(offset)
        ))
    }

    func rightEdge(_ offset: Int32) -> Int32 {
        Int32(ceil(
            Double(screenWidth) / 2.0
                + Double(screenHeight) / 2.0 * aspectRatio
                - Double(offset)
        ))
    }
}

struct SM64HUDRenderCommand: Equatable, Sendable {
    let kind: SM64HUDRenderKind
    let glyph: Int16
    let x: Int32
    let y: Int32
    let width: Int32
    let height: Int32
    let advance: Int32
    let healthWedges: Int16

    static func glyph(
        _ glyph: Int16,
        x: Int32,
        y: Int32,
        width: Int32 = 16,
        height: Int32 = 16,
        advance: Int32 = 12
    ) -> Self {
        Self(
            kind: .glyph,
            glyph: glyph,
            x: x,
            y: y,
            width: width,
            height: height,
            advance: advance,
            healthWedges: 0
        )
    }

    static func powerBase(x: Int32, y: Int32) -> Self {
        Self(
            kind: .powerMeterBase,
            glyph: -1,
            x: x,
            y: y,
            width: 64,
            height: 64,
            advance: 0,
            healthWedges: 0
        )
    }

    static func powerHealth(x: Int32, y: Int32, wedges: Int16) -> Self {
        Self(
            kind: .powerMeterHealth,
            glyph: -1,
            x: x,
            y: y,
            width: 32,
            height: 32,
            advance: 0,
            healthWedges: wedges
        )
    }
}

struct SM64HUDRenderPacket: Equatable, Sendable {
    let layout: SM64HUDLayout
    let commands: [SM64HUDRenderCommand]

    static func project(
        _ projection: SM64HUDProjection,
        keys: Int16 = 0,
        layout: SM64HUDLayout = SM64HUDLayout()
    ) -> Self {
        guard projection.configHUD && projection.flags != [] else {
            return Self(layout: layout, commands: [])
        }

        var commands: [SM64HUDRenderCommand] = []
        commands.reserveCapacity(48)

        if projection.showLives {
            appendGlyph(52, x: layout.leftEdge(22), y: layout.hudTopY, to: &commands)
            appendGlyph(50, x: layout.leftEdge(38), y: layout.hudTopY, to: &commands)
            appendNumber(Int32(projection.lives), x: layout.leftEdge(54), y: layout.hudTopY, to: &commands)
        }

        if projection.showCoins {
            appendGlyph(51, x: 168, y: layout.hudTopY, to: &commands)
            appendGlyph(50, x: 184, y: layout.hudTopY, to: &commands)
            appendNumber(Int32(projection.coins), x: 198, y: layout.hudTopY, to: &commands)
        }

        if projection.showStars {
            let starX = layout.rightEdge(layout.starsX)
            appendGlyph(53, x: starX, y: layout.hudTopY, to: &commands)
            if projection.showStarMultiplier {
                appendGlyph(50, x: starX + 16, y: layout.hudTopY, to: &commands)
            }
            let numberX = layout.rightEdge(layout.starsX - 16)
                + (projection.showStarMultiplier ? 14 : 0)
            appendNumber(Int32(projection.stars), x: numberX, y: layout.hudTopY, to: &commands)
        }

        if projection.showKeys {
            for index in 0..<max(keys, 0) {
                appendGlyph(55, x: Int32(index) * 16 + 220, y: 142, to: &commands)
            }
        }

        if projection.showCameraAndPower && projection.powerMeter.render {
            let meter = projection.powerMeter
            commands.append(.powerBase(x: Int32(meter.x) - 32, y: Int32(meter.y) - 32))
            if meter.shownHealthWedges != 0 {
                commands.append(.powerHealth(
                    x: Int32(meter.x) - 16,
                    y: Int32(meter.y) - 16,
                    wedges: meter.shownHealthWedges
                ))
            }
        }

        if projection.showTimer {
            appendText("TIME", x: layout.rightEdge(150), y: 185, to: &commands)
            appendNumber(
                Int32(projection.timer.minutes),
                x: layout.rightEdge(91), y: 185, to: &commands
            )
            appendNumber(
                Int32(projection.timer.seconds),
                x: layout.rightEdge(71), y: 185, width: 2, zeroPad: true,
                to: &commands
            )
            appendNumber(
                Int32(projection.timer.fractionalSeconds),
                x: layout.rightEdge(37), y: 185, to: &commands
            )
            appendGlyph(56, x: layout.rightEdge(81), y: 32, to: &commands)
            appendGlyph(57, x: layout.rightEdge(46), y: 32, to: &commands)
        }

        return Self(layout: layout, commands: commands)
    }

    private static func appendGlyph(
        _ glyph: Int16,
        x: Int32,
        y: Int32,
        to commands: inout [SM64HUDRenderCommand]
    ) {
        commands.append(.glyph(glyph, x: x, y: y))
    }

    private static func appendText(
        _ text: String,
        x: Int32,
        y: Int32,
        to commands: inout [SM64HUDRenderCommand]
    ) {
        for (index, character) in text.enumerated() {
            guard let glyph = glyphID(for: character), glyph >= 0 else { continue }
            appendGlyph(
                glyph,
                x: x + Int32(index) * 12,
                y: y,
                to: &commands
            )
        }
    }

    private static func appendNumber(
        _ value: Int32,
        x: Int32,
        y: Int32,
        width: Int32 = 0,
        zeroPad: Bool = false,
        to commands: inout [SM64HUDRenderCommand]
    ) {
        var glyphs: [Int16] = []
        var magnitude = value
        if magnitude < 0 {
            glyphs.append(22) // C format_integer's negative marker: 'M'.
            magnitude = -magnitude
        }
        glyphs.append(contentsOf: String(magnitude).compactMap { glyphID(for: $0) })
        if width > Int32(glyphs.count) {
            let pad: Int16 = zeroPad ? 0 : -1
            glyphs.insert(contentsOf: repeatElement(pad, count: Int(width) - glyphs.count), at: 0)
        }
        for (index, glyph) in glyphs.enumerated() where glyph >= 0 {
            appendGlyph(
                glyph,
                x: x + Int32(index) * 12,
                y: y,
                to: &commands
            )
        }
    }

    private static func glyphID(for character: Character) -> Int16? {
        guard let scalar = character.unicodeScalars.first, scalar.value < 128 else {
            return nil
        }
        let value = Int16(scalar.value)
        switch value {
        case 65...90: return value - 55
        case 97...122: return value - 87
        case 48...57: return value - 48
        case 32: return -1
        case 33: return 36
        case 35: return 37
        case 37: return 40
        case 38: return 39
        case 42: return 50
        case 43: return 51
        case 44: return 52
        case 45: return 53
        case 46: return 54
        case 47: return 55
        case 63: return 38
        case 39: return 56
        case 34: return 57
        default: return -1
        }
    }
}
