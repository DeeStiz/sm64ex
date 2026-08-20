import Foundation

struct SM64CourtyardBooTripletOutput: Equatable, Sendable {
    let spawnCount: Int
    let shouldDeactivate: Bool
    let starGatePassed: Bool
}

/// Value counterpart of `bhv_courtyard_boo_triplet_init`.
enum SM64CourtyardBooTripletBehavior {
    static let relativePositions: [SM64ObjectVector3] = [
        .init(x: 0, y: 50, z: 0),
        .init(x: 210, y: 110, z: 210),
        .init(x: -210, y: 70, z: -210),
    ]

    static func update(timer: Int32, totalStars: Int32) -> SM64CourtyardBooTripletOutput {
        let passed = totalStars >= 12
        return .init(spawnCount: timer == 0 && passed ? 3 : 0, shouldDeactivate: true, starGatePassed: passed)
    }
}
