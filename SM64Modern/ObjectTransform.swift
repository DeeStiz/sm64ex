import Foundation

/// Column-major `Mat4` values matching the C engine's `Mat4` layout. The
/// translation is in entries 12...14 and the final row is [0, 0, 0, 1].
enum SM64ObjectTransform {
    static let identity: [Float] = [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    ]

    static func rotateZXYAndTranslate(
        translation: SM64ObjectVector3,
        angles: SM64ObjectAngles
    ) -> [Float] {
        let pitch = Int16(truncatingIfNeeded: angles.pitch)
        let yaw = Int16(truncatingIfNeeded: angles.yaw)
        let roll = Int16(truncatingIfNeeded: angles.roll)
        let sx = SM64CanonicalTrig.sins(pitch)
        let cx = SM64CanonicalTrig.coss(pitch)
        let sy = SM64CanonicalTrig.sins(yaw)
        let cy = SM64CanonicalTrig.coss(yaw)
        let sz = SM64CanonicalTrig.sins(roll)
        let cz = SM64CanonicalTrig.coss(roll)

        return [
            cy * cz + sx * sy * sz, cx * sz, -sy * cz + sx * cy * sz, 0,
            -cy * sz + sx * sy * cz, cx * cz, sy * sz + sx * cy * cz, 0,
            cx * sy, -sx, cx * cy, 0,
            translation.x, translation.y, translation.z, 1,
        ]
    }

    /// Mirrors `mtxf_mul(dest, a, b)` including its column-major ordering.
    static func multiply(_ a: [Float], _ b: [Float]) -> [Float] {
        precondition(a.count == 16 && b.count == 16)
        var result = identity
        for column in 0..<3 {
            for row in 0..<3 {
                result[column * 4 + row] =
                    a[column * 4 + 0] * b[0 * 4 + row]
                    + a[column * 4 + 1] * b[1 * 4 + row]
                    + a[column * 4 + 2] * b[2 * 4 + row]
            }
        }
        for row in 0..<3 {
            result[12 + row] =
                a[12 + 0] * b[0 * 4 + row]
                + a[12 + 1] * b[1 * 4 + row]
                + a[12 + 2] * b[2 * 4 + row]
                + b[12 + row]
        }
        return result
    }

    static func applyingScale(_ matrix: [Float], scale: SM64ObjectVector3) -> [Float] {
        precondition(matrix.count == 16)
        var result = matrix
        for row in 0..<3 { result[row] *= scale.x }
        for row in 0..<3 { result[4 + row] *= scale.y }
        for row in 0..<3 { result[8 + row] *= scale.z }
        return result
    }

    static func relativeToParent(
        relativePosition: SM64ObjectVector3,
        faceAngles: SM64ObjectAngles,
        scale: SM64ObjectVector3,
        parentTransform: [Float]
    ) -> [Float] {
        let local = applyingScale(
            rotateZXYAndTranslate(translation: relativePosition, angles: faceAngles),
            scale: scale
        )
        return multiply(local, parentTransform)
    }

    static func translation(of transform: [Float]) -> SM64ObjectVector3 {
        precondition(transform.count == 16)
        return SM64ObjectVector3(x: transform[12], y: transform[13], z: transform[14])
    }

    static func gfxPosition(
        position: SM64ObjectVector3,
        graphYOffset: Float
    ) -> SM64ObjectVector3 {
        SM64ObjectVector3(x: position.x, y: position.y + graphYOffset, z: position.z)
    }
}
