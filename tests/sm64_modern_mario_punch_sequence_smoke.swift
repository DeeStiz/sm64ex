import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hashU8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x=h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func hashU16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x=h; for i in 0..<2{x ^= UInt64((v >> UInt16(i*8)) & 0xff); x &*= fnvPrime}; return x }
private func hashU32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x=h; for i in 0..<4{x ^= UInt64((v >> UInt32(i*8)) & 0xff); x &*= fnvPrime}; return x }
private func hashResult(_ h: UInt64, _ r: SM64MarioPunchSequenceResult) -> UInt64 {
    var x=hashU32(h,r.actionArgument); x=hashU16(x,r.animationID); x=hashU32(x,r.transitionAction ?? UInt32.max)
    x=hashU32(x,r.flags); x=hashU8(x,r.punchState ?? UInt8.max); return hashU8(x,r.sound.rawValue)
}
private func input(_ arg: UInt32, moving: Bool = true, frame: Int16 = 3, atEnd: Bool = false, pastEnd: Bool = false, b: Bool = false) -> SM64MarioPunchSequenceInput {
    SM64MarioPunchSequenceInput(movingAction: moving, actionArgument: arg, animationFrame: frame, animationAtEnd: atEnd, animationPastEnd: pastEnd, bPressed: b)
}

@main
enum SM64ModernMarioPunchSequenceSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let first = SM64MarioPunchSequence.update(input(0, frame: 2))!
        precondition(first.animationID == SM64MarioPunchAnimationID.firstPunch && first.sound == .yah && first.flags == SM64MarioPunchSequence.punchingFlag)
        fingerprint = hashResult(fingerprint, first)
        let firstEnd = SM64MarioPunchSequence.update(input(1, frame: 3, pastEnd: true))!
        precondition(firstEnd.actionArgument == 2 && firstEnd.punchState == 4)
        fingerprint = hashResult(fingerprint, firstEnd)
        let fast = SM64MarioPunchSequence.update(input(2, frame: 0, b: true))!
        precondition(fast.actionArgument == 3 && fast.flags == SM64MarioPunchSequence.punchingFlag)
        fingerprint = hashResult(fingerprint, fast)
        let fastEnd = SM64MarioPunchSequence.update(input(2, atEnd: true))!
        precondition(fastEnd.transitionAction == SM64MarioActionID.walking)
        fingerprint = hashResult(fingerprint, fastEnd)
        let second = SM64MarioPunchSequence.update(input(3, frame: 1))!
        precondition(second.sound == .wah && second.flags == SM64MarioPunchSequence.punchingFlag)
        fingerprint = hashResult(fingerprint, second)
        let secondEnd = SM64MarioPunchSequence.update(input(4, frame: 1, pastEnd: true))!
        precondition(secondEnd.actionArgument == 5 && secondEnd.punchState == 68)
        fingerprint = hashResult(fingerprint, secondEnd)
        let kick = SM64MarioPunchSequence.update(input(6, frame: 0))!
        precondition(kick.flags == SM64MarioPunchSequence.kickingFlag && kick.punchState == 134 && kick.sound == .hoo)
        fingerprint = hashResult(fingerprint, kick)
        let kickEnd = SM64MarioPunchSequence.update(input(6, moving: false, frame: 8, atEnd: true))!
        precondition(kickEnd.transitionAction == SM64MarioActionID.idle)
        fingerprint = hashResult(fingerprint, kickEnd)
        let breakdance = SM64MarioPunchSequence.update(input(9, moving: false, frame: 3, atEnd: true))!
        precondition(breakdance.flags == SM64MarioPunchSequence.trippingFlag && breakdance.transitionAction == SM64MarioActionID.crouching)
        fingerprint = hashResult(fingerprint, breakdance)
        precondition(SM64MarioPunchSequence.update(input(7)) == nil)
        print(String(format: "marioPunchSequenceFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario punch-sequence smoke passed")
    }
}
