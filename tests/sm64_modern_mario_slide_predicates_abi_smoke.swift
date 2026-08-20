import Foundation

private func input(
    flags: UInt32,
    terrainIsSlide: UInt32,
    forwardVelocity: Float,
    facingDownhill: UInt32,
    intendedYaw: Int32,
    faceYaw: Int32
) -> SM64ModernMarioSlidePredicatesInputV1 {
    SM64ModernMarioSlidePredicatesInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioSlidePredicatesInputV1>.size)
        ),
        simulation_tick: 1,
        input: flags,
        terrain_is_slide: terrainIsSlide,
        forward_velocity_bits: forwardVelocity.bitPattern,
        facing_downhill: facingDownhill,
        intended_yaw: intendedYaw,
        face_yaw: faceYaw,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioSlidePredicatesOutputV1,
    _ rhs: SM64ModernMarioSlidePredicatesOutputV1
) -> Bool {
    lhs.should_begin_sliding == rhs.should_begin_sliding
        && lhs.analog_stick_held_back == rhs.analog_stick_held_back
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioSlidePredicatesABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioSlidePredicatesAPI(service: service)
        precondition(sm64_modern_install_mario_slide_predicates_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(flags: 0, terrainIsSlide: 0, forwardVelocity: 0, facingDownhill: 0,
                  intendedYaw: 0, faceYaw: 0),
            input(flags: 0x0008, terrainIsSlide: 1, forwardVelocity: 0, facingDownhill: 0,
                  intendedYaw: 0, faceYaw: 0),
            input(flags: 0x0008, terrainIsSlide: 0, forwardVelocity: -1, facingDownhill: 0,
                  intendedYaw: 0, faceYaw: 0),
            input(flags: 0x0008, terrainIsSlide: 0, forwardVelocity: 4, facingDownhill: 1,
                  intendedYaw: 0x5000, faceYaw: 0),
            input(flags: 0, terrainIsSlide: 0, forwardVelocity: 4, facingDownhill: 0,
                  intendedYaw: 0x5000, faceYaw: 0x1000),
            input(flags: 0x0008, terrainIsSlide: 0, forwardVelocity: 4, facingDownhill: 0,
                  intendedYaw: 0x471C, faceYaw: 0)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioSlidePredicatesOutputV1()
            var cOutput = SM64ModernMarioSlidePredicatesOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_slide_predicates(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_slide_predicates(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "slide-predicates status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "slide-predicates ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioSlidePredicatesUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_slide_predicates_api()
        print("SM64 Modern Mario slide-predicates C-to-Swift ABI smoke passed updates=\(evidence.marioSlidePredicatesUpdates)")
    }
}
