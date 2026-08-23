import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private let parentBehaviorID: UInt64 = 0x6268_765f_706f_6b
private let bodyBehaviorID: UInt64 = 0x6268_765f_7062
private let collisionID: UInt64 = 0x12cf_919f_bb09_8397
private let parentSourceID: UInt64 = 0x88bd_956f_3e11_b0e9
private let parentOwnerID: UInt64 = 0x2b82_b65e_014d_17b6
private let childSourceID: UInt64 = 0x6061_b2b7_d4be_b1f0
private let childOwnerID: UInt64 = 0xdeac_9568_ef96_8759

private struct SourceTuple: Equatable {
    let x: Int32
    let y: Int32
    let z: Int32
    let yaw: Int32
    let parameter: UInt32
}

private struct ChildTuple: Equatable {
    let sourceOrder: UInt32
    let model: UInt32
    let offsetX: Int32
    let offsetY: Int32
    let offsetZ: Int32
}

private struct ChildReceipt {
    var subject: UInt32
    var generation: UInt32
    var parentSubject: UInt32
    var parentGeneration: UInt32
    var sourceOrder: UInt32
    var model: UInt32
    var offsetX: Int32
    var offsetY: Int32
    var offsetZ: Int32
    var parameter: UInt32
    var behaviorIdentity: UInt64
    var collisionIdentity: UInt64
    var aliveBefore: UInt32
    var aliveAfter: UInt32
    var attackHandled: UInt32
    var headKilled: UInt32
    var intangible: UInt32
    var markedForDeletion: UInt32
    var collisionObserved: UInt32
    var effects: UInt32
    var eventSequence: UInt32
}

private struct RouteInput {
    var sourceSubject: UInt32
    var sourceGeneration: UInt32
    var sourceOrder: UInt32
    var level: UInt32
    var area: UInt32
    var act: UInt32
    var parentModel: UInt32
    var parameter: UInt32
    var parentX: Int32
    var parentY: Int32
    var parentZ: Int32
    var parentYaw: Int32
    var parentIdentity: UInt64
    var childIdentity: UInt64
    var collisionIdentity: UInt64
    var actionBefore: UInt32
    var actionAfter: UInt32
    var aliveMaskBefore: UInt32
    var aliveMaskAfter: UInt32
    var aliveCountBefore: UInt32
    var aliveCountAfter: UInt32
    var headKilledBefore: UInt32
    var headKilledAfter: UInt32
    var spawnGate: UInt32
    var replenishGate: UInt32
    var unloadGate: UInt32
    var markedForDeletion: UInt32
    var effects: UInt32
    var collisionSequence: UInt32
    var effectSequence: UInt32
    var deletionSequence: UInt32
    var children: [ChildReceipt]
}

private struct Schema4Receipt {
    let abiVersion: UInt32
    let schemaVersion: UInt32
    let sourceIdentity: UInt64
    let ownerIdentity: UInt64
    let childSourceIdentity: UInt64
    let childOwnerIdentity: UInt64
    let parentIdentity: UInt64
    let childIdentity: UInt64
    let collisionIdentity: UInt64
    let flags: UInt32
    let input: RouteInput
}

private let parentTuples: [SourceTuple] = [
    SourceTuple(x: 4602, y: 40, z: 4622, yaw: 0, parameter: 0),
    SourceTuple(x: 5057, y: 143, z: 256, yaw: 0, parameter: 0),
    SourceTuple(x: -6858, y: 8, z: -3711, yaw: 0, parameter: 0),
    SourceTuple(x: -5372, y: 64, z: 3083, yaw: 0, parameter: 0),
]

private let childTuples: [ChildTuple] = [
    ChildTuple(sourceOrder: 0, model: 0x54, offsetX: 0, offsetY: 480, offsetZ: 0),
    ChildTuple(sourceOrder: 1, model: 0x55, offsetX: 0, offsetY: 360, offsetZ: 0),
    ChildTuple(sourceOrder: 2, model: 0x55, offsetX: 0, offsetY: 240, offsetZ: 0),
    ChildTuple(sourceOrder: 3, model: 0x55, offsetX: 0, offsetY: 120, offsetZ: 0),
    ChildTuple(sourceOrder: 4, model: 0x55, offsetX: 0, offsetY: 0, offsetZ: 0),
]

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func binary(_ value: UInt32) -> Bool { value <= 1 }

private func validChild(_ child: ChildReceipt, parent: RouteInput) -> Bool {
    guard child.subject != 0,
          child.generation == 1,
          child.parentSubject == parent.sourceSubject,
          child.parentGeneration == parent.sourceGeneration,
          child.sourceOrder < UInt32(childTuples.count),
          child.behaviorIdentity == bodyBehaviorID,
          child.collisionIdentity == collisionID,
          child.parameter == child.sourceOrder,
          binary(child.aliveBefore), binary(child.aliveAfter),
          binary(child.attackHandled), binary(child.headKilled),
          binary(child.intangible), binary(child.markedForDeletion),
          binary(child.collisionObserved),
          child.effects & ~UInt32(0x7f) == 0,
          child.eventSequence <= 3 else { return false }
    let expected = childTuples[Int(child.sourceOrder)]
    guard child.model == expected.model,
          child.offsetX == expected.offsetX,
          child.offsetY == expected.offsetY,
          child.offsetZ == expected.offsetZ else { return false }
    if child.collisionObserved == 1 && child.eventSequence != 1 { return false }
    if child.effects != 0 && child.eventSequence < 2 { return false }
    if child.markedForDeletion == 1 && child.eventSequence != 3 { return false }
    if child.sourceOrder == 0 && child.headKilled == 1 && child.attackHandled == 0 {
        return false
    }
    return child.sourceOrder != 0 || child.headKilled == 0 || child.attackHandled == 1
}

private func valid(_ input: RouteInput) -> Bool {
    guard input.sourceSubject != 0,
          input.sourceGeneration == 1,
          input.sourceOrder < UInt32(parentTuples.count),
          input.level == 8, input.area == 1, input.act == 1,
          input.parentModel == 0, input.parameter == 0,
          input.parentYaw == 0,
          input.parentIdentity == parentBehaviorID,
          input.childIdentity == bodyBehaviorID,
          input.collisionIdentity == collisionID,
          input.actionBefore <= 2, input.actionAfter <= 2,
          input.aliveMaskBefore <= 0x1f, input.aliveMaskAfter <= 0x1f,
          input.aliveCountBefore <= 5, input.aliveCountAfter <= 5,
          binary(input.headKilledBefore), binary(input.headKilledAfter),
          binary(input.spawnGate), binary(input.replenishGate),
          binary(input.unloadGate), binary(input.markedForDeletion),
          input.effects & ~UInt32(0x7f) == 0,
          input.collisionSequence <= 3, input.effectSequence <= 3,
          input.deletionSequence <= 3,
          input.children.count == childTuples.count else { return false }
    let expected = parentTuples[Int(input.sourceOrder)]
    guard input.parentX == expected.x,
          input.parentY == expected.y,
          input.parentZ == expected.z else { return false }
    if input.aliveCountAfter == 0 && input.markedForDeletion == 0 { return false }
    if input.markedForDeletion == 1 && input.deletionSequence != 3 { return false }
    if input.effects != 0 && input.effectSequence < 2 { return false }
    if input.collisionSequence != 0 && input.collisionSequence != 1 { return false }
    return input.children.allSatisfy { validChild($0, parent: input) }
}

private func sample() -> RouteInput {
    let children = childTuples.enumerated().map { index, tuple in
        ChildReceipt(
            subject: UInt32(index + 2), generation: 1,
            parentSubject: 1, parentGeneration: 1,
            sourceOrder: tuple.sourceOrder, model: tuple.model,
            offsetX: tuple.offsetX, offsetY: tuple.offsetY, offsetZ: tuple.offsetZ,
            parameter: UInt32(index), behaviorIdentity: bodyBehaviorID,
            collisionIdentity: collisionID, aliveBefore: 1, aliveAfter: 1,
            attackHandled: 0, headKilled: 0, intangible: 0,
            markedForDeletion: 0, collisionObserved: 1, effects: 0,
            eventSequence: 1)
    }
    return RouteInput(
        sourceSubject: 1, sourceGeneration: 1, sourceOrder: 0,
        level: 8, area: 1, act: 1, parentModel: 0, parameter: 0,
        parentX: 4602, parentY: 40, parentZ: 4622, parentYaw: 0,
        parentIdentity: parentBehaviorID, childIdentity: bodyBehaviorID,
        collisionIdentity: collisionID, actionBefore: 0, actionAfter: 1,
        aliveMaskBefore: 0x1f, aliveMaskAfter: 0x1f,
        aliveCountBefore: 5, aliveCountAfter: 5,
        headKilledBefore: 0, headKilledAfter: 0,
        spawnGate: 1, replenishGate: 0, unloadGate: 0,
        markedForDeletion: 0, effects: 0x03,
        collisionSequence: 1, effectSequence: 2, deletionSequence: 0,
        children: children)
}

@main
enum SM64ModernPokeyRouteSwiftSmoke {
    static func main() {
        precondition(parentTuples.count == 4)
        precondition(childTuples.map(\.offsetY) == [480, 360, 240, 120, 0])
        precondition(childTuples[0].model == 0x54)
        precondition(childTuples.dropFirst().allSatisfy { $0.model == 0x55 })

        var input = sample()
        precondition(valid(input), "source-authored parent/child tuple")
        let receipt = Schema4Receipt(
            abiVersion: 1, schemaVersion: 4,
            sourceIdentity: parentSourceID, ownerIdentity: parentOwnerID,
            childSourceIdentity: childSourceID, childOwnerIdentity: childOwnerID,
            parentIdentity: parentBehaviorID, childIdentity: bodyBehaviorID,
            collisionIdentity: collisionID, flags: 0x7f, input: input)
        precondition(receipt.abiVersion == 1 && receipt.schemaVersion == 4)
        precondition(receipt.sourceIdentity == parentSourceID)
        precondition(receipt.ownerIdentity == parentOwnerID)
        precondition(receipt.childSourceIdentity == childSourceID)
        precondition(receipt.childOwnerIdentity == childOwnerID)

        var fingerprint = fnvOffset
        for value in [parentBehaviorID, bodyBehaviorID, collisionID,
                      parentSourceID, parentOwnerID, childSourceID, childOwnerID] {
            fingerprint = hashU64(fingerprint, value)
        }
        for tuple in parentTuples {
            fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(tuple.x)))
            fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(tuple.y)))
            fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(tuple.z)))
        }
        for tuple in childTuples {
            fingerprint = hashU64(fingerprint, UInt64(tuple.sourceOrder))
            fingerprint = hashU64(fingerprint, UInt64(tuple.model))
            fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(tuple.offsetY)))
        }
        fingerprint = hashU64(fingerprint, UInt64(receipt.schemaVersion))

        input.children[0].parentGeneration = 2
        precondition(!valid(input), "generation-safe parent link")
        input = sample()
        input.children[1].model = 0x54
        precondition(!valid(input), "source-order model identity")
        input = sample()
        input.childIdentity = 0x6268_765f_706f_6b
        precondition(!valid(input), "semantic child identity")

        print(String(format: "pokeyRouteSwiftFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Pokey route Swift smoke passed")
        print("schema4=1 parent_child_identity=1 generation_link=1")
    }
}
