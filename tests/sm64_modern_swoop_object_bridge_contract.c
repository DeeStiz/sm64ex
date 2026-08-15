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

static uint64_t hash_kernel(
    uint64_t initial,
    uint16_t effects,
    uint8_t action,
    uint32_t scale_bits,
    uint16_t move_yaw,
    uint16_t face_roll,
    uint16_t face_pitch,
    uint32_t forward_bits,
    uint32_t velocity_y_bits,
    uint32_t position_y_bits,
    uint16_t target_yaw,
    uint16_t target_pitch,
    uint16_t bonk,
    uint32_t timer,
    uint8_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, scale_bits);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, face_roll);
    hash = hash_u64(hash, face_pitch);
    hash = hash_u64(hash, forward_bits);
    hash = hash_u64(hash, velocity_y_bits);
    hash = hash_u64(hash, position_y_bits);
    hash = hash_u64(hash, target_yaw);
    hash = hash_u64(hash, target_pitch);
    hash = hash_u64(hash, bonk);
    hash = hash_u64(hash, timer);
    return hash_u64(hash, marked);
}

static uint64_t hash_bridge(
    uint64_t initial,
    uint64_t frame,
    int unloaded,
    uint16_t effects,
    uint8_t action,
    uint8_t marked,
    int has_record,
    uint8_t record_action,
    uint8_t previous_action,
    uint32_t timer,
    uint32_t scale_bits,
    uint32_t forward_bits,
    uint32_t velocity_y_bits,
    uint32_t move_yaw,
    uint32_t pitch,
    uint32_t roll,
    uint32_t hitbox_radius_bits,
    uint32_t loot_coins,
    uint8_t active) {
    static const uint64_t list_counts[13] = {
        1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };
    uint64_t hash = hash_u64(initial, frame);
    for (unsigned index = 0; index < 13; ++index) {
        hash = hash_u64(hash, list_counts[index]);
    }
    hash = hash_u64(hash, 2); // player + general actor
    hash = hash_u64(hash, 2); // updated IDs
    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, unloaded ? 1 : 0);
    if (unloaded) {
        hash = hash_u64(hash, 1);
    }
    hash = hash_u64(hash, 1); // one effect
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, marked);
    if (!has_record) {
        return hash_u64(hash, 0);
    }
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, record_action);
    hash = hash_u64(hash, previous_action);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, scale_bits);
    hash = hash_u64(hash, forward_bits);
    hash = hash_u64(hash, velocity_y_bits);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, pitch);
    hash = hash_u64(hash, roll);
    hash = hash_u64(hash, hitbox_radius_bits);
    hash = hash_u64(hash, loot_coins);
    return hash_u64(hash, active);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_kernel(fingerprint, 7, 1, 0x3f800000u, 0, 0x8000, 0,
                               0, 0xc1400000u, 0x447a0000u, 0, 0, 0, 1, 0);
    fingerprint = hash_kernel(fingerprint, 9, 1, 0x3f800000u, 0, 0, 0,
                               0x41200000u, 0xc1200000u, 0x447a0000u, 0, 0, 0, 2, 0);
    fingerprint = hash_kernel(fingerprint, 17, 1, 0x3f800000u, 0, 0, 0,
                               0x41a00000u, 0, 0x42c80000u, 0, 0, 0, 3, 0);
    fingerprint = hash_kernel(fingerprint, 33, 1, 0x3f800000u, 1200, 0, 0,
                               0x41a00000u, 0, 0x42c80000u, 0x4000, 0, 30, 4, 0);
    fingerprint = hash_kernel(fingerprint, 65, 0, 0, 1200, 0, 0,
                               0, 0, 0x44610000u, 0x4000, 0, 30, 5, 0);
    fingerprint = hash_kernel(fingerprint, 769, 0, 0x3d4ccccdu, 1200, 0x8000, 0,
                               0, 0, 0x44610000u, 0x4000, 0, 30, 6, 1);

    fingerprint = hash_bridge(fingerprint, 1, 0, 1, 0, 0, 1,
                              0, 0, 1, 0x3d4ccccdu, 0, 0, 0, 0, 0xffff8000u,
                              0x42c80000u, 1, 1);
    fingerprint = hash_bridge(fingerprint, 20, 0, 7, 1, 0, 1,
                              1, 0, 20, 0x3f800000u, 0, 0xc1400000u, 0,
                              0, 0xffff8000u, 0x42c80000u, 1, 1);
    fingerprint = hash_bridge(fingerprint, 34, 0, 9, 1, 0, 1,
                              1, 1, 34, 0x3f800000u, 0x41200000u, 0xc1200000u,
                              0, 0, 0, 0x42c80000u, 1, 1);
    fingerprint = hash_bridge(fingerprint, 35, 1, 769, 1, 1, 0,
                              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    printf("swoopObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    return 0;
}
