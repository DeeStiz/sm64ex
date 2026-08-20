import Foundation

enum SM64GroundParticleKind: UInt8, Equatable, Sendable { case dirt = 0; case snow = 1 }
struct SM64GroundParticleSpawnerInput: Equatable, Sendable { let kind: SM64GroundParticleKind; let position: SM64ObjectVector3; let timer: Int32; let activeParticleFlags: UInt32; let particleFlag: UInt32; let seeds: [SM64StarKeyPuffSeed] }
struct SM64GroundParticleSpawnerOutput: Equatable, Sendable { let kind: SM64GroundParticleKind; let position: SM64ObjectVector3; let seeds: [SM64StarKeyPuffSeed]; let clearParticleFlag: Bool; let shouldDeactivate: Bool }
enum SM64GroundParticleSpawnerBehavior { static func update(_ input: SM64GroundParticleSpawnerInput) -> SM64GroundParticleSpawnerOutput { SM64GroundParticleSpawnerOutput(kind: input.kind, position: input.position, seeds: input.timer == 0 ? input.seeds : [], clearParticleFlag: input.activeParticleFlags & input.particleFlag != 0, shouldDeactivate: input.timer >= 1) } }
