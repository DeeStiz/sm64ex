import Foundation

private func input(
    floorPresent: UInt32 = 1,
    floorType: UInt32 = 0,
    terrainType: UInt32 = 0,
    normalY: Float = 1,
    floorAngle: Int32 = 0,
    faceYaw: Int32 = 0,
    crawling: UInt32 = 0,
    turnYaw: Int32 = 0,
    forwardVelocity: Float = 0
) -> SM64ModernMarioFloorPredicatesInputV1 {
    SM64ModernMarioFloorPredicatesInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioFloorPredicatesInputV1>.size)
        ),
        simulation_tick: 1,
        floor_present: floorPresent,
        floor_type: floorType,
        terrain_type: terrainType,
        normal_y_bits: normalY.bitPattern,
        floor_angle: floorAngle,
        face_yaw: faceYaw,
        is_crawling: crawling,
        turn_yaw: turnYaw,
        forward_velocity_bits: forwardVelocity.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioFloorPredicatesOutputV1,
    _ rhs: SM64ModernMarioFloorPredicatesOutputV1
) -> Bool {
    lhs.floor_class == rhs.floor_class
        && lhs.is_slippery == rhs.is_slippery
        && lhs.is_slope == rhs.is_slope
        && lhs.is_steep == rhs.is_steep
        && lhs.facing_downhill == rhs.facing_downhill
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioFloorPredicatesABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioFloorPredicatesAPI(service: service)
        precondition(sm64_modern_install_mario_floor_predicates_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(),
            input(terrainType: 6, normalY: 0.99),
            input(floorType: 0x0015, normalY: 0.9),
            input(floorType: 0x0014, normalY: 0.98),
            input(floorType: 0x0013, normalY: 0.99),
            input(normalY: 0.6, crawling: 1),
            input(floorType: 0x0015, normalY: 0.9, floorAngle: 0, faceYaw: 0x8000),
            input(floorPresent: 0, terrainType: 6, normalY: 0.7),
            input(floorType: 0x002E, normalY: 0.93, floorAngle: 0x4000, faceYaw: 0),
            input(floorAngle: 0, faceYaw: 0x8000, turnYaw: 1, forwardVelocity: -5)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioFloorPredicatesOutputV1()
            var cOutput = SM64ModernMarioFloorPredicatesOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_floor_predicates(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_floor_predicates(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "floor-predicate status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "floor-predicate ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioFloorPredicateUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_floor_predicates_api()
        print("SM64 Modern Mario floor-predicates C-to-Swift ABI smoke passed updates=\(evidence.marioFloorPredicateUpdates)")
    }
}
