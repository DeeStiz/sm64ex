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

static uint64_t hash_tick(
    uint64_t initial,
    uint64_t frame,
    int has_child,
    int has_spiny_record,
    int unloaded,
    uint16_t lakitu_effects,
    uint8_t lakitu_action,
    uint8_t lakitu_sub_action,
    uint8_t lakitu_num_spinies,
    uint32_t lakitu_spawned,
    uint16_t spiny_effects,
    uint8_t spiny_handler,
    uint8_t spiny_action,
    uint8_t lakitu_record_action,
    uint8_t lakitu_record_sub_action,
    uint8_t lakitu_record_count,
    uint32_t lakitu_forward_bits,
    uint32_t lakitu_velocity_bits,
    uint32_t lakitu_previous,
    uint8_t spiny_record_action,
    uint32_t spiny_forward_bits,
    uint32_t spiny_velocity_bits,
    uint32_t spiny_graph_bits) {
    static const uint64_t no_child_counts[13] = {
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0
    };
    static const uint64_t child_counts[13] = {
        1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0
    };
    uint64_t hash = hash_u64(initial, frame);
    for (unsigned index = 0; index < 13; ++index) {
        hash = hash_u64(hash, has_child ? child_counts[index] : no_child_counts[index]);
    }
    hash = hash_u64(hash, has_child ? 2 : 1);
    hash = hash_u64(hash, has_child ? 3 : 2);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 2);
    if (has_child) {
        hash = hash_u64(hash, 3);
    }
    hash = hash_u64(hash, unloaded ? 1 : 0);
    if (unloaded) {
        hash = hash_u64(hash, 3);
    }

    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, lakitu_effects);
    hash = hash_u64(hash, lakitu_action);
    hash = hash_u64(hash, lakitu_sub_action);
    hash = hash_u64(hash, lakitu_num_spinies);
    hash = hash_u64(hash, lakitu_spawned);

    hash = hash_u64(hash, has_child ? 1 : 0);
    if (has_child) {
        hash = hash_u64(hash, 3);
        hash = hash_u64(hash, 1);
        hash = hash_u64(hash, spiny_effects);
        hash = hash_u64(hash, spiny_handler);
        hash = hash_u64(hash, spiny_action);
    }

    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, lakitu_record_action);
    hash = hash_u64(hash, lakitu_record_sub_action);
    hash = hash_u64(hash, lakitu_record_count);
    hash = hash_u64(hash, lakitu_forward_bits);
    hash = hash_u64(hash, lakitu_velocity_bits);
    hash = hash_u64(hash, lakitu_previous);

    hash = hash_u64(hash, has_spiny_record ? 1 : 0);
    if (has_spiny_record) {
        hash = hash_u64(hash, spiny_record_action);
        hash = hash_u64(hash, spiny_forward_bits);
        hash = hash_u64(hash, spiny_velocity_bits);
        hash = hash_u64(hash, spiny_graph_bits);
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;

    fingerprint = hash_tick(fingerprint, 1, 0, 0, 0,
                             2, 0, 0, 0, 0,
                             0, 0, 0,
                             0, 0, 0, 0, 0, 0,
                             0, 0, 0, 0);
    fingerprint = hash_tick(fingerprint, 2, 0, 0, 0,
                             3, 1, 0, 0, 0,
                             0, 0, 0,
                             1, 0, 0, 0, 0, 0,
                             0, 0, 0, 0);
    fingerprint = hash_tick(fingerprint, 3, 1, 1, 0,
                             14, 1, 1, 1, 3,
                             1, 0, 1,
                             1, 1, 1, 0x41800000u, 0x3ecccccd, 3,
                             1, 0, 0, 0x41700000u);
    fingerprint = hash_tick(fingerprint, 34, 1, 1, 0,
                             18, 1, 2, 1, 0,
                             1, 0, 1,
                             1, 2, 1, 0x41800000u, 0x40800000u, 3,
                             1, 0, 0, 0x41700000u);
    fingerprint = hash_tick(fingerprint, 35, 1, 1, 0,
                             98, 1, 2, 1, 0,
                             9, 0, 2,
                             1, 2, 1, 0x41800000u, 0x40800000u, 0,
                             2, 0x41d00000u, 0x41f00000u, 0x41700000u);
    fingerprint = hash_tick(fingerprint, 36, 1, 1, 0,
                             2, 1, 2, 1, 0,
                             65, 2, 2,
                             1, 2, 0, 0x41800000u, 0x40800000u, 0,
                             2, 0x41d00000u, 0x41f00000u, 0x41700000u);
    fingerprint = hash_tick(fingerprint, 37, 1, 1, 0,
                             2, 1, 2, 0, 0,
                             17, 0, 0,
                             1, 2, 0, 0x41800000u, 0x40800000u, 0,
                             0, 0x41d00000u, 0x41f00000u, 0xc1880000u);
    fingerprint = hash_tick(fingerprint, 38, 1, 0, 1,
                             2, 1, 2, 0, 0,
                             33, 0, 0,
                             1, 2, 0, 0x41800000u, 0x40800000u, 0,
                             0, 0, 0, 0);

    printf("enemyLakituObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    return 0;
}
