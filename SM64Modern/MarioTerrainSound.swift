import Foundation

struct SM64MarioTerrainSoundInput: Equatable, Sendable {
    let floorPresent: Bool
    let floorType: UInt32
    let floorHeight: Float
    let waterLevel: Float
    let terrainType: UInt16
    let isLavaLevel: Bool
}

struct SM64MarioTerrainSoundResult: Equatable, Sendable {
    let terrainSoundAddend: UInt32
}

/// Value counterpart of `mario_get_terrain_sound_addend`; C retains playback.
enum SM64MarioTerrainSound {
    static func update(_ input: SM64MarioTerrainSoundInput) -> SM64MarioTerrainSoundResult? {
        guard input.floorHeight.isFinite, input.waterLevel.isFinite else { return nil }
        var sound: UInt32 = 0
        if input.floorPresent {
            if !input.isLavaLevel && input.floorHeight < input.waterLevel - 10 {
                sound = 2
            } else if (0x0021...0x0027).contains(input.floorType) {
                sound = 7
            } else {
                let floorSoundType: Int
                switch input.floorType {
                case 0x0015, 0x0030, 0x0037, 0x007A:
                    floorSoundType = 1
                case 0x0014, 0x0035, 0x0079:
                    floorSoundType = 2
                case 0x0013, 0x002E, 0x0036, 0x0073, 0x0074, 0x0075, 0x0078:
                    floorSoundType = 3
                case 0x0029:
                    floorSoundType = 4
                case 0x002A:
                    floorSoundType = 5
                default:
                    floorSoundType = 0
                }
                let sounds: [[UInt32]] = [
                    [0, 3, 1, 1, 1, 0],
                    [3, 3, 3, 3, 1, 1],
                    [5, 6, 5, 6, 3, 3],
                    [7, 3, 7, 7, 3, 3],
                    [4, 4, 4, 4, 3, 3],
                    [0, 3, 1, 6, 3, 6],
                    [3, 3, 3, 3, 6, 6]
                ]
                sound = sounds[Int(input.terrainType & 0x0007)][floorSoundType]
            }
        }
        return SM64MarioTerrainSoundResult(terrainSoundAddend: sound << 16)
    }
}
