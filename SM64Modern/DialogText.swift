import Foundation

/// The US dialog stream uses a compact byte alphabet.  Keep this value-only
/// model independent from the ROM pointer and the display-list builder so a
/// renderer can consume the same layout on the owner thread.
struct SM64DialogFontMetrics: Equatable, Sendable {
    let widths: [UInt8]

    init(widths: [UInt8] = SM64DialogFontMetrics.usWidths) {
        var normalized = Array(widths.prefix(256))
        normalized.append(contentsOf: repeatElement(0, count: max(0, 256 - normalized.count)))
        self.widths = normalized
    }

    func width(for glyph: UInt8) -> Int16 {
        Int16(widths[Int(glyph)])
    }

    static let usWidths: [UInt8] = {
        var result = Array(repeating: UInt8(0), count: 256)
        let digits: [UInt8] = [7, 7, 7, 7, 7, 7, 7, 7, 7, 7]
        let uppercase: [UInt8] = [6, 6, 6, 6, 6, 6, 6, 6, 5, 6, 6, 5, 8, 8, 6, 6, 6, 6, 6, 5, 6, 6, 8, 7, 6, 6]
        let lowercase: [UInt8] = [6, 6, 6, 5, 5, 6, 5, 5, 6, 5, 4, 5, 5, 3, 7, 5, 5, 5, 6, 5, 5, 5, 5, 5, 7, 7]
        result.replaceSubrange(0..<digits.count, with: digits)
        result.replaceSubrange(0x0A..<(0x0A + uppercase.count), with: uppercase)
        result.replaceSubrange(0x24..<(0x24 + lowercase.count), with: lowercase)
        // These are the US metrics used by the dialog printer for control
        // characters that advance the cursor without emitting a glyph.
        result[0x9E] = 5 // DIALOG_CHAR_SPACE
        result[0xD0] = 10 // DIALOG_CHAR_SLASH (two spaces, represented below)
        return result
    }()
}

enum SM64DialogTextPageState: UInt8, Equatable, Sendable {
    case none = 0
    case scroll = 1
    case end = 2
}

struct SM64DialogTextLayoutInput: Equatable, Sendable {
    let bytes: [UInt8]
    let startPosition: Int32
    let linesPerBox: Int8
    let boxState: SM64DialogBoxState
    let scrollOffsetY: Int16
    let lowerBound: Int8?
    let dialogVariable: Int16
    let metrics: SM64DialogFontMetrics

    init(
        bytes: [UInt8],
        startPosition: Int32 = 0,
        linesPerBox: Int8 = 2,
        boxState: SM64DialogBoxState = .vertical,
        scrollOffsetY: Int16 = 0,
        lowerBound: Int8? = nil,
        dialogVariable: Int16 = 0,
        metrics: SM64DialogFontMetrics = SM64DialogFontMetrics()
    ) {
        self.bytes = bytes
        self.startPosition = startPosition
        self.linesPerBox = max(linesPerBox, 0)
        self.boxState = boxState
        self.scrollOffsetY = max(scrollOffsetY, 0)
        self.lowerBound = lowerBound
        self.dialogVariable = max(dialogVariable, 0)
        self.metrics = metrics
    }
}

struct SM64DialogGlyphPlacement: Equatable, Sendable {
    let glyph: UInt8
    let x: Int16
    let line: Int8
    let sourcePosition: Int32
}

struct SM64DialogTextLayout: Equatable, Sendable {
    let glyphs: [SM64DialogGlyphPlacement]
    let pageState: SM64DialogTextPageState
    let pageStringPosition: Int32
    let cursorPosition: Int32
    let lastLine: Int8
    let lowerBound: Int8

    static func project(_ input: SM64DialogTextLayoutInput) -> Self {
        let lineLimit = max(Int(input.linesPerBox), 0)
        let totalLines = input.boxState == .horizontal ? (lineLimit * 2 + 1) : (lineLimit + 1)
        let derivedLowerBound = input.boxState == .horizontal
            ? Int8(input.scrollOffsetY / 16 + 1)
            : 1
        let lowerBound = max(input.lowerBound ?? derivedLowerBound, 1)

        var glyphs: [SM64DialogGlyphPlacement] = []
        glyphs.reserveCapacity(64)
        var strIndex = max(0, min(Int(input.startPosition), input.bytes.count))
        var lineNumber: Int8 = 1
        var xMatrix: Int16 = 1
        var linePosition: Int16 = 0
        var cursorX: Int16 = 0
        var pageState: SM64DialogTextPageState = .none
        var pageStringPosition: Int32 = 0

        while pageState == .none {
            guard strIndex < input.bytes.count else {
                pageState = .end
                pageStringPosition = -1
                break
            }

            let character = input.bytes[strIndex]
            switch character {
            case 0xFF: // DIALOG_CHAR_TERMINATOR
                pageState = .end
                pageStringPosition = -1
            case 0xFE: // DIALOG_CHAR_NEWLINE
                lineNumber += 1
                if Int(lineNumber) == totalLines {
                    pageState = .scroll
                    strIndex += 1
                    pageStringPosition = Int32(strIndex)
                    continue
                }
                linePosition = 0
                xMatrix = 1
                cursorX = 0
            case 0x9E: // DIALOG_CHAR_SPACE
                xMatrix += 1
                linePosition += 1
            case 0xD0: // DIALOG_CHAR_SLASH
                xMatrix += 2
                linePosition += 2
            case 0xD1, 0xD2: // DIALOG_CHAR_MULTI_THE / DIALOG_CHAR_MULTI_YOU
                let expansion: [UInt8] = character == 0xD1
                    ? [Self.asciiToDialog("t"), Self.asciiToDialog("h"), Self.asciiToDialog("e")]
                    : [Self.asciiToDialog("y"), Self.asciiToDialog("o"), Self.asciiToDialog("u")]
                if isVisible(lineNumber, lowerBound: lowerBound, linesPerBox: lineLimit) {
                    applyPendingSpace(
                        xMatrix: &xMatrix,
                        linePosition: linePosition,
                        cursorX: &cursorX,
                        spaceWidth: input.metrics.width(for: 0x9E)
                    )
                    for glyph in expansion {
                        glyphs.append(SM64DialogGlyphPlacement(
                            glyph: glyph,
                            x: cursorX,
                            line: lineNumber,
                            sourcePosition: Int32(strIndex)
                        ))
                        cursorX += input.metrics.width(for: glyph)
                    }
                    xMatrix = 1
                    linePosition += Int16(expansion.count)
                } else {
                    linePosition += Int16(expansion.count)
                }
            case 0xE0: // DIALOG_CHAR_STAR_COUNT
                let value = min(Int(input.dialogVariable), 99)
                let tens = value / 10
                let ones = value % 10
                let expansion: [UInt8] = tens == 0
                    ? [UInt8(ones)]
                    : [UInt8(tens), UInt8(ones)]
                if isVisible(lineNumber, lowerBound: lowerBound, linesPerBox: lineLimit) {
                    applyPendingSpace(
                        xMatrix: &xMatrix,
                        linePosition: linePosition,
                        cursorX: &cursorX,
                        spaceWidth: input.metrics.width(for: 0x9E)
                    )
                    for glyph in expansion {
                        glyphs.append(SM64DialogGlyphPlacement(
                            glyph: glyph,
                            x: cursorX,
                            line: lineNumber,
                            sourcePosition: Int32(strIndex)
                        ))
                        cursorX += input.metrics.width(for: glyph)
                    }
                    xMatrix = 1
                    linePosition += Int16(expansion.count)
                } else {
                    linePosition += Int16(expansion.count)
                }
            default:
                if isVisible(lineNumber, lowerBound: lowerBound, linesPerBox: lineLimit) {
                    applyPendingSpace(
                        xMatrix: &xMatrix,
                        linePosition: linePosition,
                        cursorX: &cursorX,
                        spaceWidth: input.metrics.width(for: 0x9E)
                    )
                    glyphs.append(SM64DialogGlyphPlacement(
                        glyph: character,
                        x: cursorX,
                        line: lineNumber,
                        sourcePosition: Int32(strIndex)
                    ))
                    cursorX += input.metrics.width(for: character)
                    xMatrix = 1
                    linePosition += 1
                }
            }
            strIndex += 1
        }

        if pageState == .end {
            pageStringPosition = -1
        }
        return Self(
            glyphs: glyphs,
            pageState: pageState,
            pageStringPosition: pageStringPosition,
            cursorPosition: Int32(strIndex),
            lastLine: lineNumber,
            lowerBound: lowerBound
        )
    }

    private static func isVisible(_ line: Int8, lowerBound: Int8, linesPerBox: Int) -> Bool {
        line >= lowerBound && Int(line) <= Int(lowerBound) + linesPerBox
    }

    private static func applyPendingSpace(
        xMatrix: inout Int16,
        linePosition: Int16,
        cursorX: inout Int16,
        spaceWidth: Int16
    ) {
        if linePosition != 0 || xMatrix != 1 {
            cursorX += spaceWidth * (xMatrix - 1)
        }
    }

    private static func asciiToDialog(_ character: Character) -> UInt8 {
        guard let scalar = character.unicodeScalars.first else { return 0 }
        switch scalar.value {
        case 48...57: return UInt8(scalar.value - 48)
        case 65...90: return UInt8(scalar.value - 65 + 0x0A)
        case 97...122: return UInt8(scalar.value - 97 + 0x24)
        default: return 0
        }
    }
}
