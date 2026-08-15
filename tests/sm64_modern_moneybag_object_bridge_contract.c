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
    uint64_t jump,
    uint64_t position_x,
    uint64_t position_y,
    uint64_t position_z,
    uint64_t yaw,
    uint64_t forward_velocity,
    uint64_t velocity_y,
    uint64_t opacity,
    uint64_t timer,
    uint64_t tangible,
    uint64_t marked,
    uint64_t coins) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, jump);
    hash = hash_u64(hash, position_x);
    hash = hash_u64(hash, position_y);
    hash = hash_u64(hash, position_z);
    hash = hash_u64(hash, yaw);
    hash = hash_u64(hash, forward_velocity);
    hash = hash_u64(hash, velocity_y);
    hash = hash_u64(hash, opacity);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, tangible);
    hash = hash_u64(hash, marked);
    return hash_u64(hash, coins);
}

static uint64_t hash_hidden(
    uint64_t initial,
    uint64_t effects,
    uint64_t action,
    uint64_t position_x,
    uint64_t position_y,
    uint64_t position_z,
    uint64_t timer) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, position_x);
    hash = hash_u64(hash, position_y);
    hash = hash_u64(hash, position_z);
    return hash_u64(hash, timer);
}

static uint64_t hash_effect(
    uint64_t initial,
    uint64_t object_id,
    uint64_t kind,
    uint64_t action,
    uint64_t effects,
    uint64_t child_count,
    uint64_t first_child,
    uint64_t marked) {
    uint64_t hash = hash_u64(initial, object_id);
    hash = hash_u64(hash, kind);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, effects);
    hash = hash_u64(hash, child_count);
    for (uint64_t child = 0; child < child_count; ++child) {
        hash = hash_u64(hash, first_child + child);
    }
    return hash_u64(hash, marked);
}

int main(void) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_state(hash, 1, 0, 0, 0, 1120403456, 0, 0, 0, 0, 12, 1, 0, 0, 0);
    hash = hash_state(hash, 3, 2, 0, 0, 1120403456, 0, 0, 0, 0, 255, 2, 0, 0, 0);
    hash = hash_state(hash, 33028, 3, 1, 0, 1120010240, 0, 0, 0, 3225419776, 255, 32, 1, 0, 0);
    hash = hash_state(hash, 65632, 2, 2, 0, 1124663296, 1101004800, 0, 1101004800, 1108606976, 0, 1, 0, 0, 0);
    hash = hash_state(hash, 66112, 2, 2, 0, 1126891520, 1109393408, 40960, 1101004800, 1106247680, 0, 2, 0, 0, 0);
    hash = hash_state(hash, 65552, 5, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0);
    hash = hash_state(hash,
                      26640, 5, 0,
                      0, 0, 0, 0,
                      0, 0, 0,
                      2, 0, 1, 5);
    hash = hash_state(hash, 16392, 4, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0);
    hash = hash_hidden(hash, 135168, 1, 0, 0, 0, 1);
    hash = hash_effect(hash, 1, 0, 5, 16, 0, 0, 0);
    hash = hash_effect(hash, 1, 0, 5, 26640, 6, 3, 1);

    printf("moneybagObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)hash);
    return 0;
}
