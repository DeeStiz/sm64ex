import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func append(_ output: SM64WdwExpressElevatorOutput, to fingerprint: inout UInt64) {
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
    fingerprint = hashF32(fingerprint, output.positionY)
    fingerprint = hashF32(fingerprint, output.velocityY)
    fingerprint = hashU32(fingerprint, output.playedSound ? 1 : 0)
}

@main
enum SM64ModernWdwExpressElevatorSmoke {
    static func main() {
        let idle = SM64WdwExpressElevatorBehavior.update(SM64WdwExpressElevatorInput(
            kind: .elevator, action: 0, timer: 0, positionY: 100, homeY: 500,
            marioOnPlatform: false
        ))
        let start = SM64WdwExpressElevatorBehavior.update(SM64WdwExpressElevatorInput(
            kind: .elevator, action: 0, timer: 0, positionY: 100, homeY: 500,
            marioOnPlatform: true
        ))
        let down = SM64WdwExpressElevatorBehavior.update(SM64WdwExpressElevatorInput(
            kind: .elevator, action: 1, timer: 132, positionY: 100, homeY: 500,
            marioOnPlatform: true
        ))
        let downEnd = SM64WdwExpressElevatorBehavior.update(SM64WdwExpressElevatorInput(
            kind: .elevator, action: 1, timer: 133, positionY: 100, homeY: 500,
            marioOnPlatform: true
        ))
        let waitEnd = SM64WdwExpressElevatorBehavior.update(SM64WdwExpressElevatorInput(
            kind: .elevator, action: 2, timer: 111, positionY: 100, homeY: 500,
            marioOnPlatform: true
        ))
        let upEnd = SM64WdwExpressElevatorBehavior.update(SM64WdwExpressElevatorInput(
            kind: .elevator, action: 3, timer: 0, positionY: 490, homeY: 500,
            marioOnPlatform: true
        ))
        let reset = SM64WdwExpressElevatorBehavior.update(SM64WdwExpressElevatorInput(
            kind: .elevator, action: 4, timer: 0, positionY: 500, homeY: 500,
            marioOnPlatform: false
        ))
        let staticPlatform = SM64WdwExpressElevatorBehavior.update(SM64WdwExpressElevatorInput(
            kind: .staticPlatform, action: 2, timer: 9, positionY: 100, homeY: 500,
            marioOnPlatform: true
        ))
        precondition(idle == SM64WdwExpressElevatorOutput(action: 0, positionY: 100, velocityY: 0, playedSound: false))
        precondition(start.action == 1 && start.positionY == 100)
        precondition(down == SM64WdwExpressElevatorOutput(action: 1, positionY: 80, velocityY: -20, playedSound: true))
        precondition(downEnd.action == 2 && downEnd.positionY == 80)
        precondition(waitEnd.action == 3 && waitEnd.positionY == 100)
        precondition(upEnd == SM64WdwExpressElevatorOutput(action: 4, positionY: 500, velocityY: 10, playedSound: true))
        precondition(reset.action == 0 && staticPlatform.action == 2 && staticPlatform.positionY == 100)
        var fingerprint = fnvOffset
        append(idle, to: &fingerprint); append(start, to: &fingerprint); append(down, to: &fingerprint)
        append(downEnd, to: &fingerprint); append(waitEnd, to: &fingerprint); append(upEnd, to: &fingerprint)
        append(reset, to: &fingerprint); append(staticPlatform, to: &fingerprint)
        print(String(format: "wdwExpressElevatorFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern WDW express elevator smoke passed")
    }
}
