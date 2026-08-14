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

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernObjectTransformSmoke {
    static func main() {
        let rootPosition = SM64ObjectVector3(x: 10.25, y: -20.5, z: 30.75)
        let rootAngles = SM64ObjectAngles(pitch: 0x1234, yaw: 0x2A00, roll: Int32(Int16(bitPattern: 0xD000)))
        let root = SM64ObjectTransform.rotateZXYAndTranslate(
            translation: rootPosition,
            angles: rootAngles
        )
        let childPosition = SM64ObjectVector3(x: 5.5, y: 6.25, z: -7.75)
        let childAngles = SM64ObjectAngles(pitch: 0x4000, yaw: 0x1000, roll: 0x2000)
        let childScale = SM64ObjectVector3(x: 1.25, y: 0.75, z: 2.0)
        let child = SM64ObjectTransform.relativeToParent(
            relativePosition: childPosition,
            faceAngles: childAngles,
            scale: childScale,
            parentTransform: root
        )
        let childWorldPosition = SM64ObjectTransform.translation(of: child)
        let childGfxPosition = SM64ObjectTransform.gfxPosition(
            position: childWorldPosition,
            graphYOffset: 11.5
        )
        require(root.count == 16 && child.count == 16, "matrix shape")
        require(childGfxPosition.y == childWorldPosition.y + 11.5, "gfx offset")

        let state = SM64SwiftEngineState(objectCapacity: 2)
        let parentID = try! state.spawnObject(in: .spawner)
        let childID = try! state.spawnObject(in: .generalActor, parent: parentID)
        _ = state.objects.mutate(parentID) {
            $0.position = rootPosition
            $0.faceAngles = rootAngles
            $0.objectFlags = SM64ObjectScheduler.objectFlagBuildTransform
        }
        _ = state.objects.mutate(childID) {
            $0.parentRelativePosition = childPosition
            $0.faceAngles = childAngles
            $0.scale = childScale
            $0.graphYOffset = 11.5
            $0.objectFlags = SM64ObjectScheduler.objectFlagTransformRelativeToParent
                | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
        let transformed = SM64ObjectScheduler().updateTransforms(state: state)
        require(transformed == [parentID, childID], "owner-thread transform order")
        require(state.objects.record(for: childID)?.transform == child, "parent transform propagation")
        require(state.objects.record(for: childID)?.gfxPosition == childGfxPosition, "gfx transform propagation")

        var fingerprint = fnvOffset
        for value in root + child + [
            childWorldPosition.x, childWorldPosition.y, childWorldPosition.z,
            childGfxPosition.x, childGfxPosition.y, childGfxPosition.z,
        ] {
            fingerprint = hashU32(fingerprint, value.bitPattern)
        }
        print(String(format: "objectTransformFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern object transform smoke passed")
    }
}
