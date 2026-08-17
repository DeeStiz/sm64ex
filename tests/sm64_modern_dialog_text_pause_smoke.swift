import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ hash: UInt64, _ value: UInt32) -> UInt64 {
    var result = hash
    for shift in stride(from: 0, through: 24, by: 8) {
        result ^= UInt64((value >> UInt32(shift)) & 0xFF)
        result &*= fnvPrime
    }
    return result
}

private func hashBool(_ hash: UInt64, _ value: Bool) -> UInt64 {
    hashU32(hash, value ? 1 : 0)
}

private func hashLayout(_ hash: UInt64, _ layout: SM64DialogTextLayout) -> UInt64 {
    var result = hash
    result = hashU32(result, UInt32(layout.glyphs.count))
    for glyph in layout.glyphs {
        result = hashU32(result, UInt32(glyph.glyph))
        result = hashU32(result, UInt32(bitPattern: Int32(glyph.x)))
        result = hashU32(result, UInt32(bitPattern: Int32(glyph.line)))
        result = hashU32(result, UInt32(bitPattern: glyph.sourcePosition))
    }
    result = hashU32(result, UInt32(layout.pageState.rawValue))
    result = hashU32(result, UInt32(bitPattern: layout.pageStringPosition))
    result = hashU32(result, UInt32(bitPattern: layout.cursorPosition))
    result = hashU32(result, UInt32(bitPattern: Int32(layout.lastLine)))
    result = hashU32(result, UInt32(bitPattern: Int32(layout.lowerBound)))
    return result
}

private func hashPause(_ hash: UInt64, _ result: SM64PauseMenuTickResult) -> UInt64 {
    var value = hash
    value = hashU32(value, UInt32(result.state.rawValue))
    value = hashU32(value, UInt32(bitPattern: Int32(result.selection)))
    value = hashU32(value, UInt32(bitPattern: Int32(result.cameraSelection.rawValue)))
    value = hashU32(value, UInt32(result.textAlpha))
    value = hashBool(value, result.menuModeActive)
    value = hashU32(value, UInt32(bitPattern: Int32(result.outcome.rawValue)))
    value = hashBool(value, result.cameraChanged)
    return value
}

@main
enum SM64ModernDialogTextPauseSmoke {
    static func main() {
        let bytes: [UInt8] = [
            0x0A, 0x9E, 0x0B, 0xFE,
            0xD1, 0xFE,
            0x0C, 0xD0, 0x0D, 0xFE,
            0xFF
        ]
        let firstPage = SM64DialogTextLayout.project(SM64DialogTextLayoutInput(
            bytes: bytes,
            linesPerBox: 2,
            boxState: .vertical
        ))
        precondition(firstPage.pageState == .scroll)
        precondition(firstPage.pageStringPosition == 6)
        precondition(firstPage.glyphs.count == 5)
        precondition(firstPage.glyphs[0] == SM64DialogGlyphPlacement(glyph: 0x0A, x: 0, line: 1, sourcePosition: 0))
        precondition(firstPage.glyphs[1].x == 11)
        precondition(firstPage.glyphs[2].line == 2)
        precondition(firstPage.lastLine == 3)

        let secondPage = SM64DialogTextLayout.project(SM64DialogTextLayoutInput(
            bytes: bytes,
            startPosition: firstPage.pageStringPosition,
            linesPerBox: 2,
            boxState: .horizontal,
            scrollOffsetY: 16
        ))
        precondition(secondPage.lowerBound == 2)
        precondition(secondPage.pageState == .end)
        precondition(secondPage.pageStringPosition == -1)
        precondition(secondPage.glyphs.allSatisfy { $0.line >= 2 })

        let stars = SM64DialogTextLayout.project(SM64DialogTextLayoutInput(
            bytes: [0x9E, 0xE0, 0xFF],
            dialogVariable: 42
        ))
        precondition(stars.glyphs.map(\.glyph) == [4, 2])
        precondition(stars.glyphs[0].x == 5)
        precondition(stars.glyphs[1].x == 12)

        var fingerprint = hashLayout(fnvOffset, firstPage)
        fingerprint = hashLayout(fingerprint, secondPage)
        fingerprint = hashLayout(fingerprint, stars)

        var pause = SM64PauseMenuModel()
        let opened = pause.tick(SM64PauseMenuInput(courseNumber: 1))
        precondition(opened.state == .vertical && opened.textAlpha == 25)
        let cameraRow = pause.tick(SM64PauseMenuInput(
            verticalSelectionDelta: 2,
            horizontalCameraDelta: 1,
            courseNumber: 1,
            canExitCourse: true
        ))
        precondition(cameraRow.selection == 3)
        precondition(cameraRow.cameraSelection == .fixed)
        precondition(cameraRow.cameraChanged)
        let resumed = pause.tick(SM64PauseMenuInput(
            confirmPressed: true,
            courseNumber: 1,
            canExitCourse: true
        ))
        precondition(resumed.outcome == .resume && resumed.state == .opening)
        fingerprint = hashPause(fingerprint, opened)
        fingerprint = hashPause(fingerprint, cameraRow)
        fingerprint = hashPause(fingerprint, resumed)

        var exitPause = SM64PauseMenuModel()
        _ = exitPause.tick(SM64PauseMenuInput(courseNumber: 1, canExitCourse: true))
        _ = exitPause.tick(SM64PauseMenuInput(
            verticalSelectionDelta: 1,
            courseNumber: 1,
            canExitCourse: true
        ))
        let exited = exitPause.tick(SM64PauseMenuInput(
            confirmPressed: true,
            courseNumber: 1,
            canExitCourse: true
        ))
        precondition(exited.outcome == .exitCourse)
        fingerprint = hashPause(fingerprint, exited)

        let frozen = exitPause.tick(SM64PauseMenuInput(advanceLegacyDomain: false, courseNumber: 1))
        precondition(frozen == SM64PauseMenuTickResult(
            state: .opening,
            selection: 2,
            cameraSelection: .mario,
            textAlpha: 75,
            menuModeActive: false,
            outcome: .none,
            cameraChanged: false
        ))
        fingerprint = hashPause(fingerprint, frozen)

        print("dialogTextPauseFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern dialog text/pause smoke passed")
    }
}
