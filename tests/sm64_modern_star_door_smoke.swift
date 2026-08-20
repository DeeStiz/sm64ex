import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 0xff
        result &*= fnvPrime
    }
    return result
}

private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 {
    hash(seed, UInt64(bitPattern: Int64(value)))
}

private func hash(_ seed: UInt64, _ value: Float) -> UInt64 {
    hash(seed, UInt64(value.bitPattern))
}

@main
struct SM64StarDoorSmoke {
    static func main() {
        let closed = SM64StarDoorBehavior.update(.init(action: .closed, timer: 0, position: .zero, moveYaw: 0, interactionActivated: false, neighborAction: nil, roomVisible: true))
        let activate = SM64StarDoorBehavior.update(.init(action: .closed, timer: 7, position: .zero, moveYaw: 0, interactionActivated: true, neighborAction: nil, roomVisible: true))
        let opening = SM64StarDoorBehavior.update(.init(action: .opening, timer: 0, position: .zero, moveYaw: 0, interactionActivated: false, neighborAction: nil, roomVisible: true))
        let openingEnd = SM64StarDoorBehavior.update(.init(action: .opening, timer: 16, position: .init(x: -8, y: 0, z: 0), moveYaw: 0, interactionActivated: false, neighborAction: nil, roomVisible: true))
        let openHold = SM64StarDoorBehavior.update(.init(action: .open, timer: 31, position: .init(x: -136, y: 0, z: 0), moveYaw: 0, interactionActivated: false, neighborAction: nil, roomVisible: true))
        let closing = SM64StarDoorBehavior.update(.init(action: .closing, timer: 0, position: .init(x: -136, y: 0, z: 0), moveYaw: 0, interactionActivated: false, neighborAction: nil, roomVisible: true))
        let closingEnd = SM64StarDoorBehavior.update(.init(action: .closing, timer: 16, position: .init(x: -128, y: 0, z: 0), moveYaw: 0, interactionActivated: false, neighborAction: nil, roomVisible: true))
        let reset = SM64StarDoorBehavior.update(.init(action: .reset, timer: 0, position: .init(x: 0, y: 0, z: 0), moveYaw: 0, interactionActivated: false, neighborAction: nil, roomVisible: true))
        let hidden = SM64StarDoorBehavior.update(.init(action: .closed, timer: 0, position: .zero, moveYaw: 0, interactionActivated: false, neighborAction: nil, roomVisible: false))
        precondition(closed.action == .closed && closed.timer == 1 && closed.tangible && closed.visible && closed.loadCollisionModel, "star door closed route")
        precondition(activate.action == .opening && activate.timer == 0 && activate.tangible, "star door activation edge")
        precondition(opening.action == .opening && opening.timer == 1 && opening.position.x == -8 && opening.sound == .open && opening.rumble && !opening.tangible, "star door opening route")
        precondition(openingEnd.action == .open && openingEnd.timer == 0 && openingEnd.position.x == -16, "star door opening transition")
        precondition(openHold.action == .closing && openHold.timer == 0, "star door hold transition")
        precondition(closing.position.x == -128 && closing.sound == .close && closing.rumble && !closing.tangible, "star door closing route")
        precondition(closingEnd.action == .reset && closingEnd.timer == 0, "star door closing transition")
        precondition(reset.action == .closed && reset.timer == 0 && reset.clearInteraction, "star door reset route")
        precondition(!hidden.visible && hidden.tangible, "star door room visibility route")

        var fingerprint = fnvOffset
        for output in [closed, activate, opening, openingEnd, openHold, closing, closingEnd, reset, hidden] {
            fingerprint = hash(fingerprint, output.action.rawValue)
            fingerprint = hash(fingerprint, output.timer)
            fingerprint = hash(fingerprint, output.position.x)
            fingerprint = hash(fingerprint, output.position.z)
            fingerprint = hash(fingerprint, output.velocityX)
            fingerprint = hash(fingerprint, output.velocityZ)
            fingerprint = hash(fingerprint, UInt64(output.tangible ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.visible ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.loadCollisionModel ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.sound.rawValue))
            fingerprint = hash(fingerprint, UInt64(output.rumble ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.clearInteraction ? 1 : 0))
        }
        print(String(format: "starDoorFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern star-door smoke passed")
    }
}
