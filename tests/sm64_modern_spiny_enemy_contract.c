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

static uint64_t hash_tick(uint64_t initial, uint64_t frame,
                          uint32_t unloaded_count, uint16_t effects,
                          uint8_t handler, uint8_t action,
                          uint32_t forward_bits, uint32_t velocity_bits,
                          uint32_t graph_y_bits) {
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
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, effects);
    hash = hash_u64(hash, handler);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, forward_bits);
    hash = hash_u64(hash, velocity_bits);
    return hash_u64(hash, graph_y_bits);
}

static uint64_t hash_attack_table(uint64_t initial) {
    static const uint8_t handlers[7] = { 0, 2, 2, 0, 0, 2, 2 };
    uint64_t hash = initial;
    for (unsigned attack = 0; attack < 7; ++attack) {
        hash = hash_u64(hash, attack);
        hash = hash_u64(hash, handlers[attack]);
        hash = hash_u64(hash, handlers[attack] != 0);
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_tick(fingerprint, 1, 0, 9, 0, 2,
                             0x41200000u, 0x41f00000u, 0x41700000u);
    fingerprint = hash_tick(fingerprint, 2, 0, 17, 0, 0,
                             0x41200000u, 0x41f00000u, 0xc1880000u);
    fingerprint = hash_tick(fingerprint, 3, 0, 7, 2, 0,
                             0x3f666667u, 0x41a80000u, 0xc1880000u);
    fingerprint = hash_tick(fingerprint, 4, 1, 33, 0, 0,
                             0x3f666667u, 0x41a80000u, 0xc1880000u);
    fingerprint = hash_attack_table(fingerprint);
    printf("spinyEnemyFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    return 0;
}
