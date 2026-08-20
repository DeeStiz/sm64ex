import Foundation

enum SM64ClockArmKind: UInt8, Equatable, Sendable { case hour = 0; case minute = 1 }
enum SM64ClockSpeedSetting: UInt8, Equatable, Sendable { case slow = 0; case fast = 1; case random = 2; case stopped = 3 }
enum SM64ClockSurface: UInt8, Equatable, Sendable { case `default` = 0; case painting = 1; case other = 2 }
struct SM64ClockArmInput: Equatable, Sendable { let kind: SM64ClockArmKind; let action: Int32; let timer: Int32; let roll: Int32; let angleVelocity: Int32; let surface: SM64ClockSurface }
struct SM64ClockArmOutput: Equatable, Sendable { let action: Int32; let timer: Int32; let roll: Int32; let speedSetting: SM64ClockSpeedSetting?; let rotating: Bool }

enum SM64ClockArmBehavior {
    static func update(_ input: SM64ClockArmInput) -> SM64ClockArmOutput {
        var action = input.action
        var speedSetting: SM64ClockSpeedSetting?
        if input.action == 0, input.surface == .default, input.timer >= 4 { action = 1 }
        if input.action == 1, input.surface == .painting {
            if input.kind == .minute { speedSetting = speed(forRoll: UInt16(truncatingIfNeeded: input.roll)) }
            action = 2
        }
        let rotating = action < 2
        return .init(action: action, timer: input.timer &+ 1, roll: rotating ? input.roll &+ input.angleVelocity : input.roll, speedSetting: speedSetting, rotating: rotating)
    }

    private static func speed(forRoll roll: UInt16) -> SM64ClockSpeedSetting {
        if roll < 0x0AAA { return .stopped }
        if roll < 0x6AA4 { return .fast }
        if roll < 0x954C { return .random }
        if roll < 0xF546 { return .slow }
        return .stopped
    }
}
