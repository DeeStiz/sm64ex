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

private func record(_ hash: UInt64, _ result: SM64FrontEndTickResult) -> UInt64 {
    var value = hash
    value = hashU32(value, UInt32(result.screen.rawValue))
    value = hashU32(value, UInt32(result.transition.rawValue))
    value = hashU32(value, UInt32(bitPattern: Int32(result.selectedFile)))
    value = hashU32(value, UInt32(bitPattern: Int32(result.selectedCourse)))
    value = hashU32(value, UInt32(bitPattern: Int32(result.selectedLevel)))
    value = hashU32(value, UInt32(result.demoIndex))
    value = hashU32(value, UInt32(bitPattern: Int32(result.titleZoomCounter)))
    value = hashU32(value, UInt32(bitPattern: Int32(result.titleFadeCounter)))
    return value
}

@main
enum SM64ModernFrontEndSmoke {
    static func main() {
        var title = SM64IntroPresentationState()
        for _ in 0..<20 { title.tick(advanceLegacyDomain: true) }
        precondition(title.zoomCounter == 20)
        precondition(title.phase == .hold)
        precondition(title.fadeCounter == 52)
        let frozenZoom = title.zoomCounter
        title.tick(advanceLegacyDomain: false)
        precondition(title.zoomCounter == frozenZoom)

        var frontEnd = SM64FrontEndModel()
        var fingerprint = fnvOffset
        var result = frontEnd.tick(SM64FrontEndInput())
        precondition(result.screen == .title && result.titleZoomCounter == 1)
        fingerprint = record(fingerprint, result)

        for _ in 0..<799 { result = frontEnd.tick(SM64FrontEndInput()) }
        precondition(result.screen == .demo)
        precondition(result.transition == .startDemo)
        precondition(result.demoIndex == 1)
        fingerprint = record(fingerprint, result)

        frontEnd.enterTitle()
        result = frontEnd.tick(SM64FrontEndInput(startPressed: true))
        precondition(result.screen == .fileSelect && result.transition == .openFileSelect)
        fingerprint = record(fingerprint, result)

        result = frontEnd.tick(SM64FrontEndInput(selectionDelta: -1))
        precondition(result.selectedFile == 4)
        result = frontEnd.tick(SM64FrontEndInput(confirmPressed: true))
        precondition(result.screen == .courseSelect && result.selectedCourse == 1)
        fingerprint = record(fingerprint, result)

        result = frontEnd.tick(SM64FrontEndInput(selectionDelta: -1))
        precondition(result.selectedCourse == 15)
        result = frontEnd.tick(SM64FrontEndInput(confirmPressed: true))
        precondition(result.screen == .gameplay && result.selectedLevel == 15)
        fingerprint = record(fingerprint, result)

        result = frontEnd.tick(SM64FrontEndInput(creditsComplete: true))
        precondition(result.screen == .credits && result.transition == .openCredits)
        result = frontEnd.tick(SM64FrontEndInput(creditsComplete: true))
        precondition(result.screen == .title && result.transition == .returnToTitle)
        fingerprint = record(fingerprint, result)

        result = frontEnd.tick(SM64FrontEndInput(startPressed: true, debugLevelSelect: true))
        precondition(result.screen == .levelSelect && result.transition == .openLevelSelect)
        result = frontEnd.tick(SM64FrontEndInput(selectionDelta: -1))
        precondition(result.selectedLevel == 64)
        result = frontEnd.tick(SM64FrontEndInput(startPressed: true))
        precondition(result.screen == .gameplay && result.selectedLevel == 64)
        fingerprint = record(fingerprint, result)

        let frozen = frontEnd.tick(SM64FrontEndInput(advanceLegacyDomain: false, selectionDelta: 1))
        precondition(frozen == SM64FrontEndTickResult(
            screen: .gameplay,
            transition: .none,
            selectedFile: 4,
            selectedCourse: 15,
            selectedLevel: 64,
            demoIndex: 1,
            titleZoomCounter: 0,
            titleFadeCounter: 0
        ))
        fingerprint = record(fingerprint, frozen)

        print("frontEndFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern front-end smoke passed")
    }
}
