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
    uint64_t subtype,
    uint64_t held,
    uint64_t action,
    uint64_t position_x,
    uint64_t position_y,
    uint64_t position_z,
    uint64_t yaw,
    uint64_t forward_velocity,
    uint64_t velocity_y,
    uint64_t fuse_timer,
    uint64_t blink_timer,
    uint64_t scale,
    uint64_t fuse_lit,
    uint64_t hidden,
    uint64_t tangible,
    uint64_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, subtype);
    hash = hash_u64(hash, held);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, position_x);
    hash = hash_u64(hash, position_y);
    hash = hash_u64(hash, position_z);
    hash = hash_u64(hash, yaw);
    hash = hash_u64(hash, forward_velocity);
    hash = hash_u64(hash, velocity_y);
    hash = hash_u64(hash, fuse_timer);
    hash = hash_u64(hash, blink_timer);
    hash = hash_u64(hash, scale);
    hash = hash_u64(hash, fuse_lit);
    hash = hash_u64(hash, hidden);
    hash = hash_u64(hash, tangible);
    return hash_u64(hash, marked);
}

static uint64_t hash_effect(
    uint64_t initial,
    uint64_t object_id,
    uint64_t subtype,
    uint64_t held,
    uint64_t action,
    uint64_t effects,
    uint64_t child_count,
    const uint64_t *children,
    uint64_t marked) {
    uint64_t hash = hash_u64(initial, object_id);
    hash = hash_u64(hash, subtype);
    hash = hash_u64(hash, held);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, effects);
    hash = hash_u64(hash, child_count);
    for (uint64_t index = 0; index < child_count; ++index) {
        hash = hash_u64(hash, children[index]);
    }
    return hash_u64(hash, marked);
}

int main(void) {
    uint64_t hash = FNV_OFFSET;

    hash = hash_state(hash, 44, 0, 0, 2,
                      0, 1120075776, 1084227584, 0,
                      1084227584, 3223322624, 1, 0, 1065353216,
                      1, 0, 1, 0);
    hash = hash_state(hash, 38, 0, 0, 2,
                      1081718578, 1119420416, 1103424759, 2048,
                      1101004800, 3231711232, 2, 0, 1065353216,
                      1, 0, 1, 0);
    hash = hash_state(hash, 52, 0, 0, 1,
                      1081718578, 1118437376, 1110603388, 16384,
                      1103626240, 1106247680, 3, 0, 1065353216,
                      1, 0, 1, 0);
    hash = hash_state(hash, 65612, 0, 1, 0,
                      1121714176, 1117782016, 1106247680, 16384,
                      0, 0, 1, 0, 1065353216,
                      1, 1, 1, 0);
    hash = hash_state(hash, 139280, 0, 0, 1,
                      0, 0, 0, 49152,
                      1103626240, 1101004800, 0, 0, 1065353216,
                      0, 0, 1, 0);
    hash = hash_state(hash, 0, 1, 0, 3,
                      0, 0, 0, 0,
                      0, 0, 0, 0, 1065353216,
                      0, 0, 1, 0);
    hash = hash_state(hash, 5888, 0, 0, 3,
                      0, 0, 0, 0,
                      0, 0, 0, 0, 1073741824,
                      0, 0, 1, 1);

    const uint64_t first_children[] = { 3 };
    hash = hash_effect(hash, 1, 0, 0, 3, 44, 1, first_children, 0);
    const uint64_t children[] = { 3, 4 };
    hash = hash_effect(hash, 1, 0, 0, 3, 5892, 2, children, 1);

    printf("bobombObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)hash);
    return 0;
}
