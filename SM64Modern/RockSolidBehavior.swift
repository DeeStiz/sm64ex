import Foundation

struct SM64RockSolidInput: Equatable, Sendable { let timer: Int32 }
struct SM64RockSolidOutput: Equatable, Sendable { let timer: Int32; let loadCollisionModel: Bool }
enum SM64RockSolidBehavior { static func update(_ input: SM64RockSolidInput) -> SM64RockSolidOutput { .init(timer: input.timer &+ 1, loadCollisionModel: true) } }
