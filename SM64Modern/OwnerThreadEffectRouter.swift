import Foundation

/// Stable delivery kinds shared by migrated actor bridges. Value kernels emit
/// intents; this owner-thread router is the only place that applies pool,
/// respawn, or transient-child mutations.
enum SM64OwnerThreadEffectKind: UInt8, Equatable, Sendable {
    case sound = 0
    case particle = 1
    case cameraShake = 2
    case spawnCoin = 3
    case setRespawnBit = 4
    case releaseChain = 5
    case markForDeletion = 6
    case updatePosition = 7
    case dialog = 8
    case star = 9
    case music = 10
    case cameraFocus = 11
}

struct SM64OwnerThreadEffectIntent: Equatable, Sendable {
    let sequence: UInt64
    let objectID: SM64ObjectID
    let kind: SM64OwnerThreadEffectKind
    let value: Int32
    let auxiliary: Int32

    init(
        sequence: UInt64,
        objectID: SM64ObjectID,
        kind: SM64OwnerThreadEffectKind,
        value: Int32 = 0,
        auxiliary: Int32 = 0
    ) {
        self.sequence = sequence
        self.objectID = objectID
        self.kind = kind
        self.value = value
        self.auxiliary = auxiliary
    }
}

struct SM64OwnerThreadEffectDeliveryResult: Equatable, Sendable {
    let delivered: [SM64OwnerThreadEffectIntent]
    let presented: [SM64OwnerThreadEffectIntent]
    let spawned: [SM64ObjectID]
    let deleted: [SM64ObjectID]
    let rejected: [SM64OwnerThreadEffectIntent]
}

/// Owner-thread-only effect sink. It deliberately has no `Sendable`
/// conformance: callers must construct, enqueue, and deliver it on the same
/// engine-owner thread that owns `SM64ObjectPool`.
final class SM64OwnerThreadEffectRouter {
    static let coinModel: UInt32 = 0x74 // MODEL_YELLOW_COIN
    static let coinBehaviorIdentity: UInt64 = 0x6268_765F_636F_69

    private var nextSequence: UInt64 = 1
    private(set) var pending: [SM64OwnerThreadEffectIntent] = []

    func beginTick() {
        pending.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func enqueue(
        objectID: SM64ObjectID,
        kind: SM64OwnerThreadEffectKind,
        value: Int32 = 0,
        auxiliary: Int32 = 0
    ) -> SM64OwnerThreadEffectIntent {
        let sequence = nextSequence
        nextSequence = nextSequence == UInt64.max ? 1 : nextSequence + 1
        let intent = SM64OwnerThreadEffectIntent(
            sequence: sequence,
            objectID: objectID,
            kind: kind,
            value: value,
            auxiliary: auxiliary
        )
        pending.append(intent)
        return intent
    }

    /// Converts the Chain Chomp release bridge's typed effect records into the
    /// common delivery contract without allowing the C object graph to cross
    /// this boundary.
    func enqueue(_ effects: [SM64ChainChompReleaseObjectEffectRecord]) {
        for effect in effects {
            if effect.kind == .woodenPost {
                if effect.effects.contains(.poundSound) {
                    enqueue(objectID: effect.objectID, kind: .sound)
                }
                if effect.effects.contains(.updatePosition) {
                    enqueue(objectID: effect.objectID, kind: .updatePosition)
                }
                if effect.effects.contains(.releaseChain) {
                    enqueue(objectID: effect.objectID, kind: .releaseChain)
                }
                if effect.effects.contains(.spawnCoins), effect.spawnedCoins > 0 {
                    enqueue(objectID: effect.objectID, kind: .spawnCoin, value: Int32(effect.spawnedCoins))
                }
                if effect.effects.contains(.setRespawnBit) {
                    enqueue(objectID: effect.objectID, kind: .setRespawnBit, value: 1)
                }
            } else {
                if effect.effects.contains(.wallExplosionSound) {
                    enqueue(objectID: effect.objectID, kind: .sound)
                }
                if effect.effects.contains(.cameraShake) {
                    enqueue(objectID: effect.objectID, kind: .cameraShake)
                }
                if effect.effects.contains(.mist) {
                    enqueue(objectID: effect.objectID, kind: .particle, value: 1)
                }
                if effect.effects.contains(.breakParticles) {
                    enqueue(objectID: effect.objectID, kind: .particle, value: 30, auxiliary: 0x8A)
                }
                if effect.effects.contains(.markForDeletion) {
                    enqueue(objectID: effect.objectID, kind: .markForDeletion)
                }
            }
        }
    }

    /// Applies the mutable effects in stable sequence order. Presentation
    /// intents are returned as immutable records for audio, renderer,
    /// progression, and camera owners; they are not silently discarded.
    @discardableResult
    func deliver(to pool: SM64ObjectPool) -> SM64OwnerThreadEffectDeliveryResult {
        let intents = pending
        pending.removeAll(keepingCapacity: true)

        var delivered: [SM64OwnerThreadEffectIntent] = []
        var presented: [SM64OwnerThreadEffectIntent] = []
        var spawned: [SM64ObjectID] = []
        var deleted: [SM64ObjectID] = []
        var rejected: [SM64OwnerThreadEffectIntent] = []

        for intent in intents.sorted(by: { $0.sequence < $1.sequence }) {
            switch intent.kind {
            case .markForDeletion:
                if pool.markForDeletion(intent.objectID) {
                    deleted.append(intent.objectID)
                    delivered.append(intent)
                } else {
                    rejected.append(intent)
                }
            case .spawnCoin:
                guard pool.record(for: intent.objectID) != nil,
                      intent.value > 0,
                      intent.value <= 255 else {
                    rejected.append(intent)
                    continue
                }
                var didSpawn = false
                for _ in 0..<intent.value {
                    guard let coin = try? pool.spawn(
                        in: .unimportant,
                        model: Self.coinModel,
                        behaviorIdentity: Self.coinBehaviorIdentity,
                        parent: intent.objectID
                    ) else { break }
                    _ = pool.markForDeletion(coin)
                    spawned.append(coin)
                    didSpawn = true
                }
                if didSpawn {
                    delivered.append(intent)
                } else {
                    rejected.append(intent)
                }
            case .setRespawnBit:
                guard pool.record(for: intent.objectID) != nil, intent.value >= 0, intent.value <= 255 else {
                    rejected.append(intent)
                    continue
                }
                _ = pool.mutate(intent.objectID) { record in
                    record.behaviorParams |= intent.value << 8
                }
                delivered.append(intent)
            case .sound, .particle, .cameraShake, .releaseChain, .updatePosition, .dialog, .star, .music, .cameraFocus:
                guard pool.record(for: intent.objectID) != nil else {
                    rejected.append(intent)
                    continue
                }
                delivered.append(intent)
                presented.append(intent)
            }
        }

        return SM64OwnerThreadEffectDeliveryResult(
            delivered: delivered,
            presented: presented,
            spawned: spawned,
            deleted: deleted,
            rejected: rejected
        )
    }
}
