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
    uint32_t x,
    uint32_t y,
    uint32_t z,
    uint16_t move_yaw,
    uint16_t face_yaw,
    uint16_t target_angle,
    uint16_t smooth_yaw,
    uint16_t turning,
    uint32_t target_forward,
    uint32_t forward,
    uint32_t wait_time,
    uint32_t move_flags,
    uint32_t timer,
    uint8_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, x);
    hash = hash_u64(hash, y);
    hash = hash_u64(hash, z);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, face_yaw);
    hash = hash_u64(hash, target_angle);
    hash = hash_u64(hash, smooth_yaw);
    hash = hash_u64(hash, turning);
    hash = hash_u64(hash, target_forward);
    hash = hash_u64(hash, forward);
    hash = hash_u64(hash, wait_time);
    hash = hash_u64(hash, move_flags);
    hash = hash_u64(hash, timer);
    return hash_u64(hash, marked);
}

static uint64_t hash_record(
    uint64_t initial,
    uint8_t action,
    uint8_t previous_action,
    uint32_t timer,
    uint32_t x,
    uint32_t y,
    uint32_t z,
    uint32_t yaw,
    uint32_t forward,
    uint32_t down_offset,
    uint32_t radius,
    uint32_t height,
    uint32_t hurt_radius,
    uint32_t hurt_height,
    uint32_t interaction) {
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, previous_action);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, x);
    hash = hash_u64(hash, y);
    hash = hash_u64(hash, z);
    hash = hash_u64(hash, yaw);
    hash = hash_u64(hash, forward);
    hash = hash_u64(hash, down_offset);
    hash = hash_u64(hash, radius);
    hash = hash_u64(hash, height);
    hash = hash_u64(hash, hurt_radius);
    hash = hash_u64(hash, hurt_height);
    return hash_u64(hash, interaction);
}

static uint64_t hash_bridge(uint64_t initial) {
    static const uint64_t list_counts[13] = {
        1, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0
    };
    uint64_t hash = hash_u64(initial, 1); // frame
    for (unsigned index = 0; index < 13; ++index) {
        hash = hash_u64(hash, list_counts[index]);
    }
    hash = hash_u64(hash, 6); // object counter
    hash = hash_u64(hash, 6); // updated count
    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 3);
    hash = hash_u64(hash, 4);
    hash = hash_u64(hash, 5);
    hash = hash_u64(hash, 6);
    hash = hash_u64(hash, 0); // unloaded count
    hash = hash_u64(hash, 5); // parent plus four waves

    hash = hash_u64(hash, 1); // parent ID
    hash = hash_u64(hash, 0); // parent, not wave
    hash = hash_u64(hash, 3); // spawn waves
    hash = hash_u64(hash, 0); // idle action
    hash = hash_u64(hash, 4);
    hash = hash_u64(hash, 3);
    hash = hash_u64(hash, 4);
    hash = hash_u64(hash, 5);
    hash = hash_u64(hash, 6);
    hash = hash_u64(hash, 0x3f800000U);
    hash = hash_u64(hash, 0);
    hash = hash_u64(hash, 0);

    for (uint32_t id = 3; id <= 6; ++id) {
        hash = hash_u64(hash, id);
        hash = hash_u64(hash, 1); // wave
        hash = hash_u64(hash, 0);
        hash = hash_u64(hash, 0);
        hash = hash_u64(hash, 0); // no children
        hash = hash_u64(hash, 0x3f000000U);
        hash = hash_u64(hash, 0);
        hash = hash_u64(hash, 0);
    }

    return hash_record(
        hash,
        0, 0, 1,
        0x41200000U, 0x42c80000U, 0xc1a00000U,
        0, 0,
        0x41a00000U, 0x43340000U, 0x42c80000U,
        0x43160000U, 0x42b40000U,
        1
    );
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_kernel(fingerprint, 5, 2,
                              0x41200000U, 0x42c80000U, 0xc1a00000U,
                              0, 0, 0, 0, 0,
                              0, 0, 0, 2, 2, 0);
    fingerprint = hash_kernel(fingerprint, 5, 2,
                              0x4120a097U, 0x42c80000U, 0xc19cd0bfU,
                              0x0400, 0, 0x1000, 0, 0,
                              0x41a00000U, 0x3ecccccdU, 0, 2, 3, 0);
    fingerprint = hash_kernel(fingerprint, 37, 2,
                              0x41231fddU, 0x42c80000U, 0xc19689d4U,
                              0x0800, 0, 0x2000, 0, 4,
                              0x41200000U, 0x3f4ccccdU, 0, 2, 4, 0);
    fingerprint = hash_kernel(fingerprint, 5, 2,
                              0x4128b2acU, 0x42c80000U, 0xc18d5a0dU,
                              0x0c00, 0, 0x2000, 0, 2,
                              0x41200000U, 0x3f99999aU, 0, 2, 5, 0);
    fingerprint = hash_kernel(fingerprint, 69, 0,
                              0x41327ea0U, 0x42c80000U, 0xc18186afU,
                              0x1000, 0, 0x2000, 0, 0,
                              0x41200000U, 0x3fcccccdU, 5, 2, 6, 0);
    fingerprint = hash_kernel(fingerprint, 27, 1,
                              0x42271515U, 0x42c80000U, 0x4266e0deU,
                              0x1000, 0, 0x2000, 0, 0,
                              0x41200000U, 0x42a00000U, 0, 16, 62, 0);
    fingerprint = hash_kernel(fingerprint, 99, 0,
                              0x42271515U, 0x42c80000U, 0x4266e0deU,
                              0, 0, 0x1800, 0, 0,
                              0x41200000U, 0, 7, 16, 63, 0);
    fingerprint = hash_kernel(fingerprint, 897, 0,
                              0x42271515U, 0x42c80000U, 0x4266e0deU,
                              0, 0, 0x1800, 0, 0,
                              0x41200000U, 0, 7, 0, 64, 1);
    fingerprint = hash_bridge(fingerprint);
    printf("skeeterObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
