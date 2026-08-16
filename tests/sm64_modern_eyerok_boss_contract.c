#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u32(uint64_t initial, uint32_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_i32(uint64_t initial, int32_t value) {
    return hash_u32(initial, (uint32_t) value);
}

static uint64_t hash_float(uint64_t initial, uint32_t bits) {
    return hash_u32(initial, bits);
}

struct hand_data {
    int32_t side;
    uint32_t model;
    uint32_t x;
    uint32_t y;
    uint32_t z;
    int32_t face_yaw;
    uint32_t scale;
};

static uint64_t hash_result(
    uint64_t initial,
    uint32_t action,
    int32_t sub_action,
    int32_t num_hands,
    int32_t active_hand,
    int32_t busy_hand,
    int32_t counter,
    int32_t phase,
    uint32_t direction,
    uint32_t target_z,
    uint32_t blend,
    uint32_t position_x,
    uint32_t position_y,
    uint32_t position_z,
    uint32_t timer,
    uint32_t effects,
    int32_t dialog,
    uint32_t hand_count,
    const struct hand_data *hands,
    int star,
    uint32_t star_x,
    uint32_t star_y,
    uint32_t star_z,
    int marked) {
    uint64_t hash = hash_u32(initial, action);
    hash = hash_i32(hash, sub_action);
    hash = hash_i32(hash, num_hands);
    hash = hash_i32(hash, active_hand);
    hash = hash_i32(hash, busy_hand);
    hash = hash_i32(hash, counter);
    hash = hash_i32(hash, phase);
    hash = hash_float(hash, direction);
    hash = hash_float(hash, target_z);
    hash = hash_float(hash, blend);
    hash = hash_float(hash, position_x);
    hash = hash_float(hash, position_y);
    hash = hash_float(hash, position_z);
    hash = hash_i32(hash, (int32_t) timer);
    hash = hash_u32(hash, effects);
    hash = hash_i32(hash, dialog);
    hash = hash_u32(hash, hand_count);
    for (uint32_t index = 0; index < hand_count; ++index) {
        hash = hash_i32(hash, hands[index].side);
        hash = hash_u32(hash, hands[index].model);
        hash = hash_float(hash, hands[index].x);
        hash = hash_float(hash, hands[index].y);
        hash = hash_float(hash, hands[index].z);
        hash = hash_i32(hash, hands[index].face_yaw);
        hash = hash_float(hash, hands[index].scale);
    }
    hash = hash_u32(hash, star ? 1 : 0);
    if (star) {
        hash = hash_float(hash, star_x);
        hash = hash_float(hash, star_y);
        hash = hash_float(hash, star_z);
    }
    return hash_u32(hash, marked ? 1 : 0);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    const struct hand_data hands[] = {
        { -1, 88, UINT32_C(0x44160000), UINT32_C(0x42480000), UINT32_C(0x42c80000), 0x4100, UINT32_C(0x3fc00000) },
        { 1, 89, UINT32_C(0xc3c80000), UINT32_C(0x42480000), UINT32_C(0x42c80000), -0x3f00, UINT32_C(0x3fc00000) }
    };
    fingerprint = hash_result(
        fingerprint, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0,
        UINT32_C(0x42c80000), UINT32_C(0x42480000), UINT32_C(0xc3480000), 1, 1, 0,
        2, hands, 0, 0, 0, 0, 0
    );
    fingerprint = hash_result(
        fingerprint, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0,
        UINT32_C(0x42c80000), UINT32_C(0x42480000), UINT32_C(0xc3480000), 2, 2, 0,
        0, NULL, 0, 0, 0, 0, 0
    );
    fingerprint = hash_result(
        fingerprint, 2, 1, 2, 0, 0, 0, 0, 0, 0, 0,
        UINT32_C(0x42c80000), UINT32_C(0x42480000), UINT32_C(0xc3480000), 7, 12, 117,
        0, NULL, 0, 0, 0, 0, 0
    );
    fingerprint = hash_result(
        fingerprint, 3, 1, 2, 0, 0, 0, 0, 0, 0, 0,
        UINT32_C(0x42c80000), UINT32_C(0x42480000), UINT32_C(0xc3480000), 8, 8, 117,
        0, NULL, 0, 0, 0, 0, 0
    );
    fingerprint = hash_result(
        fingerprint, 3, 0, 2, 0, 0, 1, -8, 0, 0, UINT32_C(0x3f800000),
        0, 0, UINT32_C(0x42c80000), 1, 0, 0,
        0, NULL, 0, 0, 0, 0, 0
    );
    fingerprint = hash_result(
        fingerprint, 3, 0, 2, 0, 0, 1, 8, UINT32_C(0xbf800000), UINT32_C(0x44d48000), 0,
        0, 0, UINT32_C(0x42c80000), 1, 64, 0,
        0, NULL, 0, 0, 0, 0, 0
    );
    fingerprint = hash_result(
        fingerprint, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 0, 0,
        0, NULL, 0, 0, 0, 0, 0
    );
    fingerprint = hash_result(
        fingerprint, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 60, 8, 118,
        0, NULL, 0, 0, 0, 0, 0
    );
    fingerprint = hash_result(
        fingerprint, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 61, 136, 118,
        0, NULL, 1, 0, UINT32_C(0xc4610000), UINT32_C(0xc5674000), 0
    );
    fingerprint = hash_result(
        fingerprint, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 122, 768, 0,
        0, NULL, 0, 0, 0, 0, 1
    );
    printf("eyerokBossFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern Eyerok boss C contract passed\n");
    return 0;
}
