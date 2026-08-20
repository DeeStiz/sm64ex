import Foundation

struct SM64BoulderGeneratorOutput: Equatable, Sendable {
    let timer: Int32
    let shouldSpawn: Bool
    let spawnPeriod: Int32
}

enum SM64BoulderGeneratorBehavior {
    static func update(timer inputTimer: Int32, distanceToMario: Float, currentRoomIsFour: Bool) -> SM64BoulderGeneratorOutput {
        var timer = inputTimer >= 256 ? 0 : inputTimer
        var spawn = false
        var period: Int32 = 0
        if currentRoomIsFour && distanceToMario > 1500 {
            if distanceToMario <= 6000 { period = 64 } else { period = 128 }
            spawn = timer % period == 0
        }
        timer &+= 1
        return .init(timer: timer, shouldSpawn: spawn, spawnPeriod: period)
    }
}
