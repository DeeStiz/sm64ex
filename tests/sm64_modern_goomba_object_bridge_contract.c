#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = 1469598103934665603ULL;
static const uint64_t FNV_PRIME = 1099511628211ULL;

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & 0xffu;
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_record(uint64_t initial, int32_t action,
                            int32_t previous_action, uint32_t object_flags,
                            uint32_t gravity_bits, uint32_t hitbox_bits,
                            uint32_t velocity_y_bits, uint32_t scale_bits) {
    uint64_t hash = hash_u64(initial, (uint64_t)(int64_t)action);
    hash = hash_u64(hash, (uint64_t)(int64_t)previous_action);
    hash = hash_u64(hash, object_flags);
    hash = hash_u64(hash, gravity_bits);
    hash = hash_u64(hash, hitbox_bits);
    hash = hash_u64(hash, velocity_y_bits);
    return hash_u64(hash, scale_bits);
}

static uint64_t hash_tick(uint64_t initial, uint64_t frame,
                          int32_t previous_action, uint32_t unloaded_count,
                          uint16_t regular_effects,
                          uint16_t tiny_effects, uint8_t tiny_action,
                          uint8_t tiny_coins, uint8_t tiny_respawn) {
    static const uint64_t list_counts[13] = { 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0 };
    static const uint64_t updated[3] = { 1, 3, 2 };
    uint64_t hash = hash_u64(initial, frame);
    for (unsigned index = 0; index < 13; ++index) {
        hash = hash_u64(hash, list_counts[index]);
    }
    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, 3);
    for (unsigned index = 0; index < 3; ++index) {
        hash = hash_u64(hash, updated[index]);
    }
    hash = hash_u64(hash, unloaded_count);
    if (unloaded_count != 0) {
        hash = hash_u64(hash, 2);
    }
    hash = hash_u64(hash, 2);

    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, regular_effects);
    hash = hash_u64(hash, 0);   // no attack handler
    hash = hash_u64(hash, 0);   // no blue coin
    hash = hash_u64(hash, 2);   // jump
    hash = hash_u64(hash, 0);   // high death sound
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 0);

    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, tiny_effects);
    hash = hash_u64(hash, frame == 1 ? 3 : 0); // squished only on first attack tick
    hash = hash_u64(hash, 0);   // no blue coin
    hash = hash_u64(hash, tiny_action);
    hash = hash_u64(hash, 0);   // high death sound
    hash = hash_u64(hash, tiny_coins);
    hash = hash_u64(hash, tiny_respawn);

    return hash_record(hash, 2, previous_action, 33,
                       0xc0800000u, 0x42900000u, 0x41c80000u,
                       0x3fc00000u);
}

static uint64_t hash_triplet(uint64_t initial) {
    uint64_t hash = hash_u64(initial, 1); // spawner
    hash = hash_u64(hash, 1);             // loaded
    hash = hash_u64(hash, 3);
    hash = hash_u64(hash, 3); hash = hash_u64(hash, 6);
    hash = hash_u64(hash, 4); hash = hash_u64(hash, 10);
    hash = hash_u64(hash, 5); hash = hash_u64(hash, 18);
    hash = hash_u64(hash, 5);             // spawned updated count
    hash = hash_u64(hash, 1); hash = hash_u64(hash, 2);
    hash = hash_u64(hash, 3); hash = hash_u64(hash, 4);
    hash = hash_u64(hash, 5);
    hash = hash_u64(hash, 1);             // death unloaded count
    hash = hash_u64(hash, 3);
    hash = hash_u64(hash, 1);             // respawn request count
    hash = hash_u64(hash, 3);             // source
    hash = hash_u64(hash, 1);             // parent
    hash = hash_u64(hash, 4);             // triplet flag
    hash = hash_u64(hash, 0x100);
    hash = hash_u64(hash, 1);
    return hash_u64(hash, 0x100);
}

static uint64_t hash_attack_table(uint64_t initial) {
    static const uint8_t handlers[3][8] = {
        { 0, 2, 3, 3, 2, 2, 2, 2 },
        { 0, 7, 3, 8, 7, 7, 7, 7 },
        { 0, 2, 3, 3, 2, 2, 2, 2 },
    };
    uint64_t hash = initial;
    for (unsigned size = 0; size < 3; ++size) {
        hash = hash_u64(hash, size == 2 ? 2 : size);
        for (unsigned attack = 0; attack < 8; ++attack) {
            const uint8_t handler = handlers[size][attack];
            hash = hash_u64(hash, attack);
            hash = hash_u64(hash, handler);
            hash = hash_u64(hash, handler != 0);
            hash = hash_u64(hash, handler == 8);
        }
    }
    return hash;
}

static uint64_t hash_collision_admission(uint64_t initial) {
    static const uint32_t statuses[9] = {
        0, 0x8001, 0x8002, 0x8003, 0x8004,
        0x8005, 0x8006, 0xA000, 0x8007,
    };
    static const uint8_t attacks[9] = { 0, 4, 5, 2, 3, 6, 7, 0, 0 };
    static const uint8_t attacked_mario[9] = { 0, 0, 0, 0, 0, 0, 0, 1, 0 };
    uint64_t hash = initial;
    for (unsigned index = 0; index < 9; ++index) {
        hash = hash_u64(hash, statuses[index]);
        hash = hash_u64(hash, attacks[index]);
        hash = hash_u64(hash, attacked_mario[index]);
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_tick(fingerprint, 1, 0, 0, 133, 136, 1, 1, 0);
    fingerprint = hash_tick(fingerprint, 2, 2, 1, 128, 240, 1, 0, 1);
    fingerprint = hash_triplet(fingerprint);
    fingerprint = hash_attack_table(fingerprint);
    fingerprint = hash_collision_admission(fingerprint);
    printf("goombaObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    return 0;
}
