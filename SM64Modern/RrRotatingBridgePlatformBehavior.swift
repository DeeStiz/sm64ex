import Foundation

struct SM64RrRotatingBridgePlatformInput: Equatable, Sendable { let moveYaw: Int32 }
struct SM64RrRotatingBridgePlatformOutput: Equatable, Sendable { let moveYaw: Int32; let angleVelocityYaw: Int32 }

/// Value counterpart of the rotating-platform prefix in
/// `bhv_rr_rotating_bridge_platform_loop`.
enum SM64RrRotatingBridgePlatformBehavior {
    static func update(_ input: SM64RrRotatingBridgePlatformInput) -> SM64RrRotatingBridgePlatformOutput {
        .init(moveYaw: input.moveYaw &- 0x80, angleVelocityYaw: -0x80)
    }
}
