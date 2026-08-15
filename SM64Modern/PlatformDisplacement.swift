import Foundation

struct SM64PlatformDisplacementInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let platformPosition: SM64ObjectVector3
    let platformVelocity: SM64ObjectVector3
    let angleVelocity: SM64ObjectAngles
    let faceAngles: SM64ObjectAngles
    let nativeStepScale: Float
    let isMario: Bool
    let faceYaw: Int16
}

struct SM64PlatformDisplacementOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let faceYaw: Int16
    let rotationApplied: Bool
}

/// Value-only counterpart of `apply_platform_displacement`.
///
/// The legacy routine first advances X/Z by the native-step displacement,
/// then rotates the object into platform-local space using the previous
/// platform orientation and back into world space using the current
/// orientation. No object pointers or global Mario state cross this boundary.
enum SM64PlatformDisplacement {
    static func apply(
        _ input: SM64PlatformDisplacementInput
    ) -> SM64PlatformDisplacementOutput {
        var position = input.position
        position.x += input.platformVelocity.x * input.nativeStepScale
        position.z += input.platformVelocity.z * input.nativeStepScale

        let rotationApplied = input.angleVelocity.pitch != 0
            || input.angleVelocity.yaw != 0
            || input.angleVelocity.roll != 0
        guard rotationApplied else {
            return SM64PlatformDisplacementOutput(
                position: position,
                faceYaw: input.faceYaw,
                rotationApplied: false
            )
        }

        var faceYaw = input.faceYaw
        if input.isMario {
            faceYaw = Int16(
                bitPattern: UInt16(bitPattern: faceYaw)
                    &+ UInt16(bitPattern: Int16(truncatingIfNeeded: input.angleVelocity.yaw))
            )
        }

        let currentOffset = SM64ObjectVector3(
            x: position.x - input.platformPosition.x,
            y: position.y - input.platformPosition.y,
            z: position.z - input.platformPosition.z
        )
        let previousAngles = SM64ObjectAngles(
            pitch: Int32(Int16(truncatingIfNeeded: input.faceAngles.pitch - input.angleVelocity.pitch)),
            yaw: Int32(Int16(truncatingIfNeeded: input.faceAngles.yaw - input.angleVelocity.yaw)),
            roll: Int32(Int16(truncatingIfNeeded: input.faceAngles.roll - input.angleVelocity.roll))
        )
        let previous = SM64ObjectTransform.rotateZXYAndTranslate(
            translation: currentOffset,
            angles: previousAngles
        )
        let relativeOffset = transposeMultiply(previous, currentOffset)
        let current = SM64ObjectTransform.rotateZXYAndTranslate(
            translation: currentOffset,
            angles: input.faceAngles
        )
        let newObjectOffset = linearMultiply(current, relativeOffset)
        position = SM64ObjectVector3(
            x: input.platformPosition.x + newObjectOffset.x,
            y: input.platformPosition.y + newObjectOffset.y,
            z: input.platformPosition.z + newObjectOffset.z
        )
        return SM64PlatformDisplacementOutput(
            position: position,
            faceYaw: faceYaw,
            rotationApplied: true
        )
    }

    private static func transposeMultiply(
        _ matrix: [Float],
        _ vector: SM64ObjectVector3
    ) -> SM64ObjectVector3 {
        precondition(matrix.count == 16)
        return SM64ObjectVector3(
            x: matrix[0] * vector.x + matrix[1] * vector.y + matrix[2] * vector.z,
            y: matrix[4] * vector.x + matrix[5] * vector.y + matrix[6] * vector.z,
            z: matrix[8] * vector.x + matrix[9] * vector.y + matrix[10] * vector.z
        )
    }

    private static func linearMultiply(
        _ matrix: [Float],
        _ vector: SM64ObjectVector3
    ) -> SM64ObjectVector3 {
        precondition(matrix.count == 16)
        return SM64ObjectVector3(
            x: matrix[0] * vector.x + matrix[4] * vector.y + matrix[8] * vector.z,
            y: matrix[1] * vector.x + matrix[5] * vector.y + matrix[9] * vector.z,
            z: matrix[2] * vector.x + matrix[6] * vector.y + matrix[10] * vector.z
        )
    }
}
