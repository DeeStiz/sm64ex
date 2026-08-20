import Foundation
struct SM64UnusedParticleSpawnOutput: Equatable, Sendable { let shouldRetire: Bool; let spawnCount: Int }
enum SM64UnusedParticleSpawnBehavior { static func update(onGround: Bool, collidedWithMario: Bool) -> SM64UnusedParticleSpawnOutput { let retire = onGround || collidedWithMario; return .init(shouldRetire: retire, spawnCount: retire && collidedWithMario ? 10 : 0) } }
