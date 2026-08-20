import Foundation

enum SM64MarioAirStepCollisionOutcome: UInt32, Equatable, Sendable {
    case none = 0
    case landed = 1
    case hitWall = 2
    case grabbedLedge = 3
    case grabbedCeiling = 4
    case hitLavaWall = 6
}

struct SM64MarioAirWallProbe: Equatable, Sendable {
    let surfaceID: UInt32
    let surfaceType: UInt32
    let normalX: Float
    let normalZ: Float
    let wallAngle: Int16
}

struct SM64MarioAirQuarterProbe: Equatable, Sendable {
    let floor: SM64MarioGroundFloorProbe?
    let ceilingHeight: Float
    let waterLevel: Float
    let upperWall: SM64MarioAirWallProbe?
    let lowerWall: SM64MarioAirWallProbe?
    let ledgeFloor: SM64MarioGroundFloorProbe?
    let ledgePosition: SM64ObjectVector3
    let ledgeFloorAngle: Int16
    let ledgePresent: Bool
}

struct SM64MarioAirStepInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let floor: SM64MarioGroundFloorProbe
    let facePitch: Int32
    let faceYaw: Int32
    let faceRoll: Int32
    let floorAngle: Int32
    let action: UInt32
    let stepArg: UInt32
    let nativeStepScale: Float
    let ridingShell: Bool
    let ceilPresent: Bool
    let ceilType: UInt32
    let quarterProbes: [SM64MarioAirQuarterProbe]
}

struct SM64MarioAirStepResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocityY: Float
    let floor: SM64MarioGroundFloorProbe
    let wall: SM64MarioAirWallProbe?
    let result: SM64MarioAirStepCollisionOutcome
    let quarterSteps: UInt8
    let flagsOr: UInt32
    let facePitch: Int32
    let faceYaw: Int32
    let faceRoll: Int32
    let floorAngle: Int32
    let terrainSoundAddend: UInt32
}

/// Value counterpart of `perform_air_step`. C owns collision queries and
/// effects; Swift consumes four immutable probes and reproduces the exact
/// landing, ceiling, ledge, and wall decision order.
enum SM64MarioAirStep {
    private static let marioHeight: Float = 160
    private static let ledgeHeight: Float = 100
    private static let ledgeCheck: UInt32 = 0x1
    private static let hangCheck: UInt32 = 0x2
    private static let hangableSurface: UInt32 = 0x0005
    private static let burningSurface: UInt32 = 0x0001
    private static let marioUnknown30: UInt32 = 0x4000_0000

    static func update(_ input: SM64MarioAirStepInput) -> SM64MarioAirStepResult? {
        guard input.position.x.isFinite,
              input.position.y.isFinite,
              input.position.z.isFinite,
              input.velocity.x.isFinite,
              input.velocity.y.isFinite,
              input.velocity.z.isFinite,
              input.floor.height.isFinite,
              input.floor.normalY.isFinite,
              input.nativeStepScale.isFinite,
              input.nativeStepScale >= 0,
              input.quarterProbes.count == 4 else {
            return nil
        }
        for probe in input.quarterProbes {
            guard probe.ceilingHeight.isFinite, probe.waterLevel.isFinite,
                  probe.ledgePosition.x.isFinite,
                  probe.ledgePosition.y.isFinite,
                  probe.ledgePosition.z.isFinite else { return nil }
            if let floor = probe.floor,
               (!floor.height.isFinite || !floor.normalY.isFinite) { return nil }
            if let floor = probe.ledgeFloor,
               (!floor.height.isFinite || !floor.normalY.isFinite) { return nil }
            if let wall = probe.upperWall,
               (!wall.normalX.isFinite || !wall.normalZ.isFinite) { return nil }
            if let wall = probe.lowerWall,
               (!wall.normalX.isFinite || !wall.normalZ.isFinite) { return nil }
        }

        var position = input.position
        var velocityY = input.velocity.y
        var floor = input.floor
        var wall: SM64MarioAirWallProbe?
        var result: SM64MarioAirStepCollisionOutcome = .none
        var quarterSteps: UInt8 = 0
        var flagsOr: UInt32 = 0
        var facePitch = input.facePitch
        var faceYaw = input.faceYaw
        let faceRoll = input.faceRoll
        var floorAngle = input.floorAngle

        for probe in input.quarterProbes {
            let intended = SM64ObjectVector3(
                x: position.x + input.velocity.x * input.nativeStepScale / 4,
                y: position.y + input.velocity.y * input.nativeStepScale / 4,
                z: position.z + input.velocity.z * input.nativeStepScale / 4
            )
            quarterSteps &+= 1
            wall = nil

            guard var nextFloor = probe.floor else {
                if intended.y <= floor.height {
                    position.y = floor.height
                    result = .landed
                    break
                }
                position.y = intended.y
                result = .hitWall
                continue
            }

            if input.ridingShell && nextFloor.height < probe.waterLevel {
                nextFloor = SM64MarioGroundFloorProbe(
                    surfaceID: nil, height: probe.waterLevel, normalY: 1
                )
            }

            if intended.y <= nextFloor.height {
                if probe.ceilingHeight - nextFloor.height > marioHeight {
                    position.x = intended.x
                    position.z = intended.z
                    floor = nextFloor
                }
                position.y = nextFloor.height
                result = .landed
                break
            }

            if intended.y + marioHeight > probe.ceilingHeight {
                if input.velocity.y >= 0 {
                    velocityY = 0
                    if input.stepArg & hangCheck != 0,
                       input.ceilPresent,
                       input.ceilType == hangableSurface {
                        result = .grabbedCeiling
                    }
                    break
                }
                if intended.y <= floor.height {
                    position.y = floor.height
                    result = .landed
                    break
                }
                position.y = intended.y
                result = .hitWall
                continue
            }

            if input.stepArg & ledgeCheck != 0,
               probe.upperWall == nil,
               let lowerWall = probe.lowerWall {
                if probe.ledgePresent,
                   let ledgeFloor = probe.ledgeFloor,
                   ledgeFloor.height - intended.y > ledgeHeight {
                    position = probe.ledgePosition
                    floor = ledgeFloor
                    floorAngle = Int32(probe.ledgeFloorAngle)
                    facePitch = 0
                    faceYaw = Int32(
                        Int16(truncatingIfNeeded: Int32(lowerWall.wallAngle) + Int32(Int16(bitPattern: 0x8000)))
                    )
                    result = .grabbedLedge
                    break
                }
                position = intended
                floor = nextFloor
                continue
            }

            position = intended
            floor = nextFloor
            if let selectedWall = probe.upperWall ?? probe.lowerWall {
                wall = selectedWall
                if selectedWall.surfaceType == burningSurface {
                    result = .hitLavaWall
                    break
                }
                let wallDelta = Int32(Int16(truncatingIfNeeded:
                    Int32(selectedWall.wallAngle) - input.faceYaw))
                if wallDelta < -0x6000 || wallDelta > 0x6000 {
                    flagsOr |= marioUnknown30
                    result = .hitWall
                }
            }
        }

        return SM64MarioAirStepResult(
            position: position,
            velocityY: velocityY,
            floor: floor,
            wall: wall,
            result: result,
            quarterSteps: quarterSteps,
            flagsOr: flagsOr,
            facePitch: facePitch,
            faceYaw: faceYaw,
            faceRoll: faceRoll,
            floorAngle: floorAngle,
            terrainSoundAddend: 0
        )
    }
}
