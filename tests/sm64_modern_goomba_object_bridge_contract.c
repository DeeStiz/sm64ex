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
    hash = hash_u64(hash, 2);   // jump
    hash = hash_u64(hash, 0);   // high death sound
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 0);

    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, tiny_effects);
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

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_tick(fingerprint, 1, 0, 0, 133, 136, 1, 1, 0);
    fingerprint = hash_tick(fingerprint, 2, 2, 1, 128, 240, 1, 0, 1);
    fingerprint = hash_triplet(fingerprint);
    printf("goombaObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    return 0;
}
