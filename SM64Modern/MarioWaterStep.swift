import Foundation

enum SM64MarioWaterStepCollisionOutcome: UInt32, Equatable, Sendable {
    case none = 0
    case hitFloor = 1
    case hitCeiling = 2
    case cancelled = 3
    case hitWall = 4
}

struct SM64MarioWaterFloorProbe: Equatable, Sendable {
    let surfaceID: UInt32?
    let height: Float
}

struct SM64MarioWaterWallProbe: Equatable, Sendable {
    let surfaceID: UInt32
}

struct SM64MarioWaterStepInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let nextPosition: SM64ObjectVector3
    let currentFloor: SM64MarioWaterFloorProbe
    let floor: SM64MarioWaterFloorProbe?
    let ceilingHeight: Float
    let wall: SM64MarioWaterWallProbe?
}

struct SM64MarioWaterStepResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let floor: SM64MarioWaterFloorProbe
    let result: SM64MarioWaterStepCollisionOutcome
}

/// Value counterpart of `perform_water_full_step`. Current/whirlpool effects
/// stay in C; this reducer consumes only the sampled collision facts.
enum SM64MarioWaterStep {
    private static let marioHeight: Float = 160

    static func update(_ input: SM64MarioWaterStepInput) -> SM64MarioWaterStepResult? {
        guard input.position.x.isFinite,
              input.position.y.isFinite,
              input.position.z.isFinite,
              input.nextPosition.x.isFinite,
              input.nextPosition.y.isFinite,
              input.nextPosition.z.isFinite,
              input.currentFloor.height.isFinite,
              input.ceilingHeight.isFinite else {
            return nil
        }
        if let floor = input.floor, !floor.height.isFinite { return nil }

        var position = input.position
        var floor = input.currentFloor
        var result: SM64MarioWaterStepCollisionOutcome = .cancelled

        if let nextFloor = input.floor {
            if input.nextPosition.y >= nextFloor.height {
                if input.ceilingHeight - input.nextPosition.y >= marioHeight {
                    position = input.nextPosition
                    floor = nextFloor
                    result = input.wall == nil ? .none : .hitWall
                } else if input.ceilingHeight - nextFloor.height >= marioHeight {
                    position = SM64ObjectVector3(
                        x: input.nextPosition.x,
                        y: input.ceilingHeight - marioHeight,
                        z: input.nextPosition.z
                    )
                    floor = nextFloor
                    result = .hitCeiling
                }
            } else if input.ceilingHeight - nextFloor.height >= marioHeight {
                position = SM64ObjectVector3(
                    x: input.nextPosition.x,
                    y: nextFloor.height,
                    z: input.nextPosition.z
                )
                floor = nextFloor
                result = .hitFloor
            }
        }

        return SM64MarioWaterStepResult(position: position, floor: floor, result: result)
    }
}
