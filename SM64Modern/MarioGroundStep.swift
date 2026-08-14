import Foundation

enum SM64MarioGroundStepOutcome: UInt8, Equatable, Sendable {
    case leftGround = 0
    case none = 1
    case hitWall = 2
    case hitWallContinueQuarterSteps = 3
}

struct SM64MarioGroundFloorProbe: Equatable, Sendable {
    let surfaceID: UInt32?
    let height: Float
    let normalY: Float
}

struct SM64MarioGroundWallProbe: Equatable, Sendable {
    let surfaceID: UInt32
    let normalX: Float
    let normalZ: Float
}

/// Collision values sampled for one `perform_ground_quarter_step` query. The
/// collision world owns the query; this value boundary owns the C decision
/// order that consumes its result.
struct SM64MarioGroundQuarterProbe: Equatable, Sendable {
    let floor: SM64MarioGroundFloorProbe?
    let ceilingHeight: Float
    let waterLevel: Float
    let upperWall: SM64MarioGroundWallProbe?
}

struct SM64MarioGroundStepInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let floor: SM64MarioGroundFloorProbe
    let faceYaw: Int32
    let nativeStepScale: Float
    let ridingShell: Bool
    let terrainSoundAddend: UInt32
    let quarterProbes: [SM64MarioGroundQuarterProbe]
}

struct SM64MarioGroundStepResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let floor: SM64MarioGroundFloorProbe
    let wallSurfaceID: UInt32?
    let result: SM64MarioGroundStepOutcome
    let quarterSteps: UInt8
    let terrainSoundAddend: UInt32
}

/// Value counterpart of `perform_ground_step` and its quarter-step helper.
///
/// The legacy function queries walls/floors/ceilings through global collision
/// state and mutates `MarioState` directly. Swift receives immutable query
/// snapshots instead, then reproduces the four-quarter decision and state
/// update without a C pointer or object-graph dependency.
enum SM64MarioGroundStep {
    static let quarterCount = 4
    static let floorDepartureHeight: Float = 100
    static let marioHeight: Float = 160

    static func update(_ input: SM64MarioGroundStepInput) -> SM64MarioGroundStepResult? {
        guard input.position.x.isFinite,
              input.position.y.isFinite,
              input.position.z.isFinite,
              input.velocity.x.isFinite,
              input.velocity.y.isFinite,
              input.velocity.z.isFinite,
              input.floor.height.isFinite,
              input.floor.normalY.isFinite,
              input.nativeStepScale.isFinite,
              input.quarterProbes.count == quarterCount else {
            return nil
        }
        for probe in input.quarterProbes {
            guard probe.ceilingHeight.isFinite, probe.waterLevel.isFinite else { return nil }
            if let floor = probe.floor,
               (!floor.height.isFinite || !floor.normalY.isFinite) {
                return nil
            }
            if let wall = probe.upperWall,
               (!wall.normalX.isFinite || !wall.normalZ.isFinite) {
                return nil
            }
        }

        var position = input.position
        var floor = input.floor
        var wallSurfaceID: UInt32?
        var stepResult: SM64MarioGroundStepOutcome = .none
        var quarterSteps: UInt8 = 0

        for probe in input.quarterProbes {
            let intended = SM64ObjectVector3(
                x: position.x + floor.normalY * (input.velocity.x * input.nativeStepScale / 4),
                y: position.y,
                z: position.z + floor.normalY * (input.velocity.z * input.nativeStepScale / 4)
            )
            quarterSteps &+= 1

            guard var nextFloor = probe.floor else {
                stepResult = .hitWallContinueQuarterSteps
                break
            }

            if input.ridingShell && nextFloor.height < probe.waterLevel {
                nextFloor = SM64MarioGroundFloorProbe(
                    surfaceID: nil,
                    height: probe.waterLevel,
                    normalY: 1
                )
            }

            if intended.y > nextFloor.height + Self.floorDepartureHeight {
                if intended.y + Self.marioHeight >= probe.ceilingHeight {
                    stepResult = .hitWallContinueQuarterSteps
                    break
                }
                position = intended
                floor = nextFloor
                stepResult = .leftGround
                break
            }

            if nextFloor.height + Self.marioHeight >= probe.ceilingHeight {
                stepResult = .hitWallContinueQuarterSteps
                break
            }

            position = SM64ObjectVector3(x: intended.x, y: nextFloor.height, z: intended.z)
            floor = nextFloor

            guard let wall = probe.upperWall else {
                stepResult = .none
                continue
            }

            wallSurfaceID = wall.surfaceID
            let wallAngle = SM64CanonicalTrig.atan2s(y: wall.normalZ, x: wall.normalX)
            let faceYaw = Int16(truncatingIfNeeded: input.faceYaw)
            let wallDYaw = Int32(Int16(truncatingIfNeeded: Int32(wallAngle) - Int32(faceYaw)))
            if (wallDYaw >= 0x2AAA && wallDYaw <= 0x5555)
                || (wallDYaw <= -0x2AAA && wallDYaw >= -0x5555) {
                stepResult = .none
                continue
            }

            stepResult = .hitWallContinueQuarterSteps
        }

        if stepResult == .hitWallContinueQuarterSteps {
            stepResult = .hitWall
        }

        return SM64MarioGroundStepResult(
            position: position,
            floor: floor,
            wallSurfaceID: wallSurfaceID,
            result: stepResult,
            quarterSteps: quarterSteps,
            terrainSoundAddend: input.terrainSoundAddend
        )
    }
}
