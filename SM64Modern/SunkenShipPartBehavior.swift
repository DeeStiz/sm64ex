import Foundation

struct SM64SunkenShipPartInput: Equatable, Sendable { let distanceToMario: Float }
struct SM64SunkenShipPartOutput: Equatable, Sendable { let opacity: Int32; let disableRendering: Bool }

enum SM64SunkenShipPartBehavior {
    static func update(_ input: SM64SunkenShipPartInput) -> SM64SunkenShipPartOutput {
        let opacity: Int32 = input.distanceToMario > 10_000 ? 140 : Int32(input.distanceToMario * 140 / 10_000)
        return .init(opacity: opacity, disableRendering: true)
    }
}
