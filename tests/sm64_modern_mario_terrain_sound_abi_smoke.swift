import Foundation

private func input(
    floorPresent: UInt32 = 1,
    floorType: UInt32 = 0,
    floorHeight: Float = 0,
    waterLevel: Float = 0,
    terrainType: UInt32 = 0,
    lava: UInt32 = 0
) -> SM64ModernMarioTerrainSoundInputV1 {
    SM64ModernMarioTerrainSoundInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioTerrainSoundInputV1>.size)
        ),
        simulation_tick: 1,
        floor_present: floorPresent,
        floor_type: floorType,
        floor_height_bits: floorHeight.bitPattern,
        water_level_bits: waterLevel.bitPattern,
        terrain_type: terrainType,
        is_lava_level: lava,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioTerrainSoundOutputV1,
    _ rhs: SM64ModernMarioTerrainSoundOutputV1
) -> Bool {
    lhs.terrain_sound_addend == rhs.terrain_sound_addend && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioTerrainSoundABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioTerrainSoundAPI(service: service)
        precondition(sm64_modern_install_mario_terrain_sound_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(floorPresent: 0),
            input(floorHeight: 0, waterLevel: 100),
            input(floorHeight: 0, waterLevel: 100, lava: 1),
            input(floorType: 0x0022),
            input(floorType: 0x0015, terrainType: 0),
            input(floorType: 0x0015, terrainType: 2),
            input(floorType: 0x002E, terrainType: 5),
            input(floorType: 0x002A, terrainType: 6)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioTerrainSoundOutputV1()
            var cOutput = SM64ModernMarioTerrainSoundOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_terrain_sound(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_terrain_sound(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "terrain-sound status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "terrain-sound ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioTerrainSoundUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_terrain_sound_api()
        print("SM64 Modern Mario terrain-sound C-to-Swift ABI smoke passed updates=\(evidence.marioTerrainSoundUpdates)")
    }
}
