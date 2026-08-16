import Foundation

struct SM64TuxiesMotherEyesInput: Equatable, Sendable {
    let run: Bool
    let globalTimer: UInt64
    let objectBehaviorIdentity: UInt64
    let motherBehaviorIdentity: UInt64
    let forwardVelocity: Float
    let previousSelectedCase: Int32

    init(
        run: Bool = true,
        globalTimer: UInt64 = 0,
        objectBehaviorIdentity: UInt64 = 0,
        motherBehaviorIdentity: UInt64 = 0,
        forwardVelocity: Float = 0,
        previousSelectedCase: Int32 = 0
    ) {
        self.run = run
        self.globalTimer = globalTimer
        self.objectBehaviorIdentity = objectBehaviorIdentity
        self.motherBehaviorIdentity = motherBehaviorIdentity
        self.forwardVelocity = forwardVelocity
        self.previousSelectedCase = previousSelectedCase
    }
}

struct SM64TuxiesMotherEyesOutput: Equatable, Sendable {
    let selectedCase: Int32
    let blinkingCase: Int32
    let angryOverride: Bool
}

/// Value counterpart of `geo_switch_tuxie_mother_eyes`.
///
/// The callback is evaluated only on a graph-node run.  Its normal cadence is
/// 43 open frames, two half-closed frames, two closed frames, then one
/// half-closed frame in each 50-frame period.  The moving Tuxie's mother
/// behavior identity gates the authored angry-eye case 3 override.
enum SM64TuxiesMotherEyes {
    static let openCase: Int32 = 0
    static let halfClosedCase: Int32 = 1
    static let closedCase: Int32 = 2
    static let angryCase: Int32 = 3

    static func update(_ input: SM64TuxiesMotherEyesInput) -> SM64TuxiesMotherEyesOutput {
        guard input.run else {
            return SM64TuxiesMotherEyesOutput(
                selectedCase: input.previousSelectedCase,
                blinkingCase: input.previousSelectedCase,
                angryOverride: false
            )
        }

        let timer = Int(input.globalTimer % 50)
        let blinkingCase: Int32
        if timer < 43 {
            blinkingCase = openCase
        } else if timer < 45 {
            blinkingCase = halfClosedCase
        } else if timer < 47 {
            blinkingCase = closedCase
        } else {
            blinkingCase = halfClosedCase
        }
        let angryOverride = input.objectBehaviorIdentity == input.motherBehaviorIdentity
            && input.forwardVelocity > 5
        return SM64TuxiesMotherEyesOutput(
            selectedCase: angryOverride ? angryCase : blinkingCase,
            blinkingCase: blinkingCase,
            angryOverride: angryOverride
        )
    }
}
