import Foundation

struct SM64KoopaRaceEndpointInput: Equatable, Sendable {
    let raceBegun: Bool
    let raceEnded: Bool
    let koopaFinished: Bool
    let distanceToMario: Float
    let marioShotFromCannon: Bool
    let raceStatus: Int32
}

struct SM64KoopaRaceEndpointOutput: Equatable, Sendable {
    let raceEnded: Bool
    let raceStatus: Int32
    let playFanfare: Bool
    let stopTimer: Bool
}

/// Value counterpart of `bhv_koopa_race_endpoint_update`.
enum SM64KoopaRaceEndpointBehavior {
    static func update(_ input: SM64KoopaRaceEndpointInput) -> SM64KoopaRaceEndpointOutput {
        var ended = input.raceEnded
        var status = input.raceStatus
        var fanfare = false
        var stopTimer = false
        if input.raceBegun && !input.raceEnded
            && (input.koopaFinished || input.distanceToMario < 400.0) {
            ended = true
            stopTimer = true
            if !input.koopaFinished {
                fanfare = true
                status = input.marioShotFromCannon ? -1 : 1
            }
        }
        return .init(raceEnded: ended, raceStatus: status, playFanfare: fanfare, stopTimer: stopTimer)
    }
}
