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
    uint16_t target_yaw,
    uint32_t forward,
    uint16_t turning,
    uint32_t change_timer,
    uint8_t alive_flags,
    uint8_t alive_count,
    uint32_t bottom_size,
    uint8_t head_killed,
    uint16_t death_delay,
    uint32_t scale,
    uint32_t timer,
    uint8_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, x);
    hash = hash_u64(hash, y);
    hash = hash_u64(hash, z);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, target_yaw);
    hash = hash_u64(hash, forward);
    hash = hash_u64(hash, turning);
    hash = hash_u64(hash, change_timer);
    hash = hash_u64(hash, alive_flags);
    hash = hash_u64(hash, alive_count);
    hash = hash_u64(hash, bottom_size);
    hash = hash_u64(hash, head_killed);
    hash = hash_u64(hash, death_delay);
    hash = hash_u64(hash, scale);
    hash = hash_u64(hash, timer);
    return hash_u64(hash, marked);
}

static uint64_t hash_bridge(uint64_t initial) {
    static const uint64_t list_counts[13] = {
        1, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0
    };
    uint64_t hash = hash_u64(initial, 1); // frame
    for (unsigned index = 0; index < 13; ++index) {
        hash = hash_u64(hash, list_counts[index]);
    }
    hash = hash_u64(hash, 7); // object counter
    hash = hash_u64(hash, 7); // updated count
    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 3);
    hash = hash_u64(hash, 4);
    hash = hash_u64(hash, 5);
    hash = hash_u64(hash, 6);
    hash = hash_u64(hash, 7);
    hash = hash_u64(hash, 0); // unloaded count
    hash = hash_u64(hash, 6); // parent plus five parts

    hash = hash_u64(hash, 1); // parent ID
    hash = hash_u64(hash, 0); // parent kind
    hash = hash_u64(hash, 0xFF); // body index -1
    hash = hash_u64(hash, 7); // spawn parts + wander
    hash = hash_u64(hash, 5); // spawned count
    hash = hash_u64(hash, 3);
    hash = hash_u64(hash, 4);
    hash = hash_u64(hash, 5);
    hash = hash_u64(hash, 6);
    hash = hash_u64(hash, 7);
    hash = hash_u64(hash, 5); // alive parts
    hash = hash_u64(hash, 0x3f800000U);
    hash = hash_u64(hash, 0);

    for (uint32_t id = 3; id <= 7; ++id) {
        hash = hash_u64(hash, id);
        hash = hash_u64(hash, 1); // body part kind
        hash = hash_u64(hash, id - 3); // body index
        hash = hash_u64(hash, 1); // animate
        hash = hash_u64(hash, 0); // no children
        hash = hash_u64(hash, 5);
        hash = hash_u64(hash, 0x3f800000U);
        hash = hash_u64(hash, 0);
    }

    hash = hash_u64(hash, 1); // parent record present
    hash = hash_u64(hash, 1); // action wander
    hash = hash_u64(hash, 0); // previous action
    hash = hash_u64(hash, 1); // timer
    hash = hash_u64(hash, 0x41200000U);
    hash = hash_u64(hash, 0x42c80000U);
    hash = hash_u64(hash, 0xc1a00000U);
    hash = hash_u64(hash, 0); // yaw
    hash = hash_u64(hash, 0); // forward
    hash = hash_u64(hash, 5); // alive count
    hash = hash_u64(hash, 0x1F); // alive flags
    return hash_u64(hash, 0); // parent has no interaction
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_kernel(fingerprint, 7, 1,
                              0x41200000U, 0x42c80000U, 0xc1a00000U,
                              0, 0, 0,
                              0, 0, 0x1F, 5, 0x3f800000U,
                              0, 0, 0x3f800000U, 1, 0);
    fingerprint = hash_kernel(fingerprint, 5, 1,
                              0x4123ece8U, 0x42c80000U, 0xc17018acU,
                              0x0200, 0x4000, 0x40a00000U,
                              0, 0, 0x1F, 5, 0x3f800000U,
                              0, 0, 0x3f800000U, 2, 0);
    fingerprint = hash_kernel(fingerprint, 21, 1,
                              0x412bc44cU, 0x42c80000U, 0xc1207b4aU,
                              0x0400, 0x4000, 0x40a00000U,
                              0, 0, 0x1F, 5, 0,
                              0, 0, 0x3f800000U, 1, 0);
    fingerprint = hash_kernel(fingerprint, 9, 2,
                              0x412bc44cU, 0x42c80000U, 0xc1207b4aU,
                              0x0400, 0x4000, 0,
                              0, 0, 0x1F, 5, 0,
                              0, 0, 0x3f800000U, 2, 0);
    fingerprint = hash_kernel(fingerprint, 1, 0,
                              0x417e27c7U, 0x44110000U, 0xc196a2bbU,
                              0, 0, 0,
                              0, 0, 0, 0, 0x3f800000U,
                              0, 20, 0x3f800000U, 1, 0);
    fingerprint = hash_kernel(fingerprint, 961, 0,
                              0x41800000U, 0x44110000U, 0xc1a00000U,
                              0, 0, 0,
                              0, 0, 0, 0, 0x3f800000U,
                              0, 20, 0x3f800000U, 2, 1);
    fingerprint = hash_bridge(fingerprint);
    printf("pokeyObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
