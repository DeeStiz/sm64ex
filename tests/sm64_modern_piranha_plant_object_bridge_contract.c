#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_state(
    uint64_t initial,
    uint64_t effects,
    uint64_t action,
    uint64_t position_x,
    uint64_t position_y,
    uint64_t position_z,
    uint64_t yaw,
    uint64_t scale,
    uint64_t opacity,
    uint64_t timer,
    uint64_t tangible,
    uint64_t hidden,
    uint64_t blue_coin,
    uint64_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, position_x);
    hash = hash_u64(hash, position_y);
    hash = hash_u64(hash, position_z);
    hash = hash_u64(hash, yaw);
    hash = hash_u64(hash, scale);
    hash = hash_u64(hash, opacity);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, tangible);
    hash = hash_u64(hash, hidden);
    hash = hash_u64(hash, blue_coin);
    return hash_u64(hash, marked);
}

static uint64_t hash_effect(
    uint64_t initial,
    uint64_t object_id,
    uint64_t action,
    uint64_t effects,
    uint64_t child_count,
    uint64_t marked) {
    uint64_t hash = hash_u64(initial, object_id);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, effects);
    hash = hash_u64(hash, child_count);
    for (uint64_t child = 3; child <= 22; ++child) {
        hash = hash_u64(hash, child);
    }
    return hash_u64(hash, marked);
}

int main(void) {
    uint64_t hash = FNV_OFFSET;
    const uint64_t one = UINT64_C(1065353216); // 1.0f

    hash = hash_state(hash, 40961, 0, 0, 0, 0, 0, one, 255, 1, 0, 0, 0, 0);
    hash = hash_state(hash, 40961, 1, 0, 0, 0, 0, one, 255, 2, 0, 0, 0, 0);
    hash = hash_state(hash, 36870, 3, 0, 0, 0, 0, one, 255, 3, 1, 0, 0, 0);
    hash = hash_state(hash, 36876, 2, 0, 0, 0, 0, one, 255, 12, 1, 0, 0, 0);
    hash = hash_state(hash, 36888, 2, 0, 0, 0, 1024, one, 255, 13, 1, 0, 0, 0);
    hash = hash_state(hash, 36904, 4, 0, 0, 0, 0, one, 255, 14, 1, 0, 0, 0);
    hash = hash_state(hash, 40994, 1, 0, 0, 0, 0, one, 255, 15, 0, 0, 0, 0);
    hash = hash_state(hash, 45250, 5, 0, 0, 0, 0, one, 255, 16, 0, 0, 0, 0);
    hash = hash_state(hash, 42752, 7, 0, 0, 0, 0, 0, 255, 1, 0, 0, 1, 0);
    hash = hash_state(hash, 41984, 8, 0, 0, 0, 0, 0, 255, 2, 0, 0, 1, 0);
    hash = hash_effect(hash, 1, 5, 45250, 20, 0);

    printf("piranhaPlantObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)hash);
    return 0;
}
