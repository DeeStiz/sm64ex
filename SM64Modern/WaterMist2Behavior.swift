import Foundation

struct SM64WaterMist2Input: Equatable, Sendable {
    let homePosition: SM64ObjectVector3
    let waterLevel: Float
    let randomOffsetX: Float
    let randomOffsetZ: Float
    let randomOpacity: Float
}

struct SM64WaterMist2Output: Equatable, Sendable {
    let position: SM64ObjectVector3
    let opacity: Int32
}

/// Value counterpart of `bhv_water_mist_2_loop`.
enum SM64WaterMist2Behavior {
    static func update(_ input: SM64WaterMist2Input) -> SM64WaterMist2Output {
        SM64WaterMist2Output(
            position: SM64ObjectVector3(
                x: input.homePosition.x + input.randomOffsetX,
                y: input.waterLevel + 20,
                z: input.homePosition.z + input.randomOffsetZ
            ),
            opacity: Int32(input.randomOpacity * 50 + 200)
        )
    }
}
