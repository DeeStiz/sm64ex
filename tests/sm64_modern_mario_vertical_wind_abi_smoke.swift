import Foundation

private func input(
    action: UInt32,
    floorType: UInt32,
    positionY: Float,
    velocityY: Float
) -> SM64ModernMarioVerticalWindInputV1 {
    SM64ModernMarioVerticalWindInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioVerticalWindInputV1>.size)
        ),
        simulation_tick: 1,
        action: action,
        floor_type: floorType,
        position_y_bits: positionY.bitPattern,
        velocity_y_bits: velocityY.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioVerticalWindOutputV1,
    _ rhs: SM64ModernMarioVerticalWindOutputV1
) -> Bool {
    lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.active == rhs.active
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioVerticalWindABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioVerticalWindAPI(service: service)
        precondition(sm64_modern_install_mario_vertical_wind_api(&api) == SM64_MODERN_STATUS_OK)

        let wind: UInt32 = 0x0038
        let cases = [
            input(action: SM64MarioActionID.groundPound, floorType: wind, positionY: -1500, velocityY: 0),
            input(action: 0, floorType: 0, positionY: -1500, velocityY: 0),
            input(action: 0, floorType: wind, positionY: -4501, velocityY: 0),
            input(action: 0, floorType: wind, positionY: -1500, velocityY: 0),
            input(action: 0, floorType: wind, positionY: -1000, velocityY: 0),
            input(action: 0, floorType: wind, positionY: -1000, velocityY: 30),
            input(action: 0, floorType: wind, positionY: -1500, velocityY: 49)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioVerticalWindOutputV1()
            var cOutput = SM64ModernMarioVerticalWindOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_vertical_wind(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_vertical_wind(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "vertical-wind status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "vertical-wind ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioVerticalWindUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_vertical_wind_api()
        print("SM64 Modern Mario vertical-wind C-to-Swift ABI smoke passed updates=\(evidence.marioVerticalWindUpdates)")
    }
}
