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

private func record(_ hash: UInt64, _ result: SM64DialogTickResult) -> UInt64 {
    let state = result.state
    var fingerprint = hash
    fingerprint = hashU32(fingerprint, UInt32(state.boxState.rawValue))
    fingerprint = hashU32(fingerprint, UInt32(state.boxType.rawValue))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: state.openTimerHalf))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: state.scaleHalf))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: Int32(state.scrollOffsetY)))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: Int32(state.dialogID)))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: Int32(state.textPosition)))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: Int32(state.lineNumber)))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: Int32(state.lastDialogResponse)))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: state.dialogResponse))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: Int32(result.lowerBound)))
    fingerprint = hashBool(fingerprint, result.effects.appearanceSound)
    fingerprint = hashBool(fingerprint, result.effects.nextPageSound)
    fingerprint = hashBool(fingerprint, result.effects.disappearSound)
    return hashBool(fingerprint, result.effects.responseChanged)
}

@main
enum SM64ModernDialogSmoke {
    static func main() {
        var state = SM64DialogState()
        var fingerprint = fnvOffset
        precondition(state.create(dialogID: 42, withResponse: true))

        var opening = state.tick(SM64DialogTickInput())
        precondition(opening.effects.appearanceSound)
        precondition(opening.state.boxState == .opening)
        precondition(opening.state.openTimerHalf == 165)
        fingerprint = record(fingerprint, opening)

        for _ in 0..<11 {
            opening = state.tick(SM64DialogTickInput())
            fingerprint = record(fingerprint, opening)
        }
        precondition(opening.state.boxState == .vertical)
        precondition(opening.state.openTimerHalf == 0)

        let nextPage = state.tick(SM64DialogTickInput(
            aPressed: true, lastPageStringPosition: 12, linesPerBox: 2
        ))
        precondition(nextPage.state.boxState == .horizontal)
        precondition(nextPage.effects.nextPageSound)
        fingerprint = record(fingerprint, nextPage)

        for _ in 0..<7 {
            let scrolling = state.tick(SM64DialogTickInput(
                lastPageStringPosition: 12, linesPerBox: 2
            ))
            precondition(scrolling.state.boxState == .horizontal)
            fingerprint = record(fingerprint, scrolling)
        }
        let pageDone = state.tick(SM64DialogTickInput(
            lastPageStringPosition: 12, linesPerBox: 2
        ))
        precondition(pageDone.state.boxState == .vertical)
        precondition(pageDone.state.textPosition == 12)
        precondition(pageDone.state.scrollOffsetY == 0)
        fingerprint = record(fingerprint, pageDone)

        let closeStart = state.tick(SM64DialogTickInput(
            aPressed: true, lastPageStringPosition: -1
        ))
        precondition(closeStart.state.boxState == .closing)
        fingerprint = record(fingerprint, closeStart)
        _ = state.tick(SM64DialogTickInput())
        _ = state.tick(SM64DialogTickInput())
        let closeEvent = state.tick(SM64DialogTickInput())
        precondition(closeEvent.effects.disappearSound)
        precondition(closeEvent.effects.responseChanged)
        precondition(closeEvent.state.dialogResponse == 1)
        fingerprint = record(fingerprint, closeEvent)
        for _ in 0..<5 {
            fingerprint = record(fingerprint, state.tick(SM64DialogTickInput()))
        }
        let closed = state.tick(SM64DialogTickInput())
        precondition(closed.state.dialogID == -1)
        precondition(closed.state.boxState == .opening)
        fingerprint = record(fingerprint, closed)

        precondition(state.create(dialogID: 7, type: .zoom))
        let paused = state.tick(SM64DialogTickInput(advanceLegacyDomain: false))
        precondition(paused.state.openTimerHalf == 180 && paused.effects == SM64DialogEffects())
        fingerprint = record(fingerprint, paused)
        print("dialogFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern dialog smoke passed")
    }
}
