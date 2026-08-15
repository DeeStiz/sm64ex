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

static uint64_t hash_values(uint64_t initial, const uint64_t *values, size_t count) {
    uint64_t hash = initial;
    for (size_t index = 0; index < count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t hash_spawner(
    uint64_t initial,
    uint64_t effects,
    uint32_t x,
    uint32_t y,
    uint32_t z,
    uint16_t radius,
    uint8_t active,
    uint16_t delay,
    uint32_t timer) {
    const uint64_t values[] = {
        effects, x, y, z, radius, active, delay, timer,
    };
    return hash_values(initial, values, sizeof(values) / sizeof(values[0]));
}

static uint64_t hash_bomb(
    uint64_t initial,
    uint64_t effects,
    uint8_t action,
    uint32_t x,
    uint32_t y,
    uint32_t z,
    uint32_t floor_height,
    uint16_t move_yaw,
    uint16_t angle_to_mario,
    uint32_t forward,
    uint32_t velocity_y,
    uint32_t vertical_stretch,
    uint32_t stretch_speed,
    uint8_t on_ground,
    uint32_t num_bounces,
    uint32_t scale_x,
    uint32_t scale_y,
    uint32_t scale_z,
    uint32_t timer,
    uint8_t marked) {
    const uint64_t values[] = {
        effects, action, x, y, z, floor_height, move_yaw, angle_to_mario,
        forward, velocity_y, vertical_stretch, stretch_speed, on_ground,
        num_bounces, scale_x, scale_y, scale_z, timer, marked,
    };
    return hash_values(initial, values, sizeof(values) / sizeof(values[0]));
}

static uint64_t hash_shadow(
    uint64_t initial,
    uint64_t effects,
    uint32_t x,
    uint32_t y,
    uint32_t z,
    uint32_t scale_x,
    uint32_t scale_y,
    uint32_t scale_z,
    uint32_t timer,
    uint8_t marked) {
    const uint64_t values[] = {
        effects, x, y, z, scale_x, scale_y, scale_z, timer, marked,
    };
    return hash_values(initial, values, sizeof(values) / sizeof(values[0]));
}

static uint64_t hash_record(
    uint64_t initial,
    uint8_t present,
    uint32_t action,
    uint32_t previous_action,
    uint32_t timer,
    uint32_t x,
    uint32_t y,
    uint32_t z,
    uint32_t scale_x,
    uint32_t scale_y,
    uint32_t scale_z,
    uint32_t interaction) {
    uint64_t hash = hash_u64(initial, present);
    if (!present) return hash;
    const uint64_t values[] = {
        action, previous_action, timer, x, y, z,
        scale_x, scale_y, scale_z, interaction,
    };
    return hash_values(hash, values, sizeof(values) / sizeof(values[0]));
}

static uint64_t hash_bridge(
    uint64_t initial,
    uint64_t frame,
    const uint64_t *list_counts,
    uint64_t object_counter,
    const uint64_t *updated,
    size_t updated_count,
    const uint64_t *unloaded,
    size_t unloaded_count,
    uint64_t effect_count,
    const uint64_t *effects,
    size_t effect_value_count,
    const uint64_t *records,
    size_t record_value_count) {
    uint64_t hash = hash_u64(initial, frame);
    hash = hash_values(hash, list_counts, 13);
    hash = hash_u64(hash, object_counter);
    hash = hash_u64(hash, updated_count);
    hash = hash_values(hash, updated, updated_count);
    hash = hash_u64(hash, unloaded_count);
    hash = hash_values(hash, unloaded, unloaded_count);
    // `effects` is already the exact value stream emitted by the Swift
    // effect-record loop: id, kind, effect bits, optional action (0xff for
    // spawners), child count/IDs, and deletion bit.
    hash = hash_u64(hash, effect_count);
    hash = hash_values(hash, effects, effect_value_count);
    return hash_values(hash, records, record_value_count);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_spawner(fingerprint, 3, 0x41200000U, 0x42c80000U,
                               0xc1a00000U, 1, 1, 7, 1);
    fingerprint = hash_spawner(fingerprint, 1, 0x41200000U, 0x42c80000U,
                               0xc1a00000U, 1, 1, 7, 2);

    fingerprint = hash_bomb(fingerprint, 5, 2, 0x42c80000U, 0x45034000U,
                            0x42200000U, 0, 0x1000, 0x2000, 0,
                            0xc2200000U, 0, 0, 0, 0, 0x3f800000U,
                            0x3f800000U, 0x3f800000U, 1, 0);
    fingerprint = hash_bomb(fingerprint, 1, 2, 0x42c80000U, 0x45008000U,
                            0x42200000U, 0, 0x1000, 0x2000, 0,
                            0xc2300000U, 0, 0, 0, 0, 0x3f800000U,
                            0x3f800000U, 0x3f800000U, 2, 0);
    fingerprint = hash_bomb(fingerprint, 41, 2, 0x42da7a43U, 0x44fb0000U,
                            0x422f4eaeU, 0, 0x3000, 0x3000, 0x41200000U,
                            0xc2400000U, 0xbe8e5604U, 0xc1de6666U, 1,
                            0x3f800000U, 0x3fa39581U, 0x3f38d4feU,
                            0x3fa39581U, 3, 0);
    fingerprint = hash_bomb(fingerprint, 49, 3, 0x42ecf486U, 0x44f48000U,
                            0x423e9d5cU, 0, 0x3000, 0x3000, 0x41200000U,
                            0xc2500000U, 0xbe8e5604U, 0xc1de6666U, 1,
                            0x3f800000U, 0x3fa39581U, 0x3f38d4feU,
                            0x3fa39581U, 4, 0);
    fingerprint = hash_bomb(fingerprint, 833, 3, 0x42ecf486U, 0x44f48000U,
                            0x423e9d5cU, 0, 0x3000, 0x3000, 0x41200000U,
                            0xc2500000U, 0xbe8e5604U, 0xc1de6666U, 1,
                            0x3f800000U, 0x3fa39581U, 0x3f38d4feU,
                            0x3fa39581U, 5, 1);
    fingerprint = hash_bomb(fingerprint, 193, 0, 0x40400000U, 0x3f800000U,
                            0x40e00000U, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0x3eccccccU, 0x3fcccccdU, 0x3eccccccU, 2, 0);
    fingerprint = hash_shadow(fingerprint, 1, 0x42ecf486U, 0x43fa0000U,
                              0x423e9d5cU, 0x3fa39581U, 0x3f38d4feU,
                              0x3fa39581U, 1, 0);
    fingerprint = hash_shadow(fingerprint, 1537, 0x42ecf486U, 0x43fa0000U,
                              0x423e9d5cU, 0x3fa39581U, 0x3f38d4feU,
                              0x3fa39581U, 2, 1);

    const uint64_t list1[13] = { 1, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0 };
    const uint64_t updated1[4] = { 2, 1, 3, 4 };
    const uint64_t effects1[] = {
        1, 0, 3, 255, 2, 3, 4, 0,
        3, 1, 5, 2, 0, 0,
        4, 2, 1, 2, 0, 0,
    };
    const uint64_t records1[] = {
        1, 1, 0, 1, 0x41200000U, 0x42c80000U, 0xc1a00000U,
        0x3f800000U, 0x3f800000U, 0x3f800000U, 0,
        1, 2, 1, 1, 0x433fd812U, 0x45034000U, 0x4382dd94U,
        0x3f800000U, 0x3f800000U, 0x3f800000U, 0x200000,
        1, 2, 0, 1, 0x433fd812U, 0x43fa0000U, 0x4382dd94U,
        0x3f800000U, 0x3f800000U, 0x3f800000U, 0,
    };
    fingerprint = hash_bridge(fingerprint, 1, list1, 4, updated1, 4,
                              NULL, 0, 3, effects1,
                              sizeof(effects1) / sizeof(effects1[0]),
                              records1, sizeof(records1) / sizeof(records1[0]));

    const uint64_t unloaded2[1] = { 4 };
    const uint64_t effects2[] = {
        1, 0, 1, 255, 0, 0,
        3, 1, 49, 3, 0, 0,
        4, 2, 1537, 3, 0, 1,
    };
    const uint64_t records2[] = {
        1, 1, 0, 2, 0x41200000U, 0x42c80000U, 0xc1a00000U,
        0x3f800000U, 0x3f800000U, 0x3f800000U, 0,
        1, 3, 2, 2, 0x433fd812U, 0x45008000U, 0x4382dd94U,
        0x3f800000U, 0x3f800000U, 0x3f800000U, 0,
        0,
    };
    fingerprint = hash_bridge(fingerprint, 2, list1, 4, updated1, 4,
                              unloaded2, 1, 3, effects2,
                              sizeof(effects2) / sizeof(effects2[0]),
                              records2, sizeof(records2) / sizeof(records2[0]));

    const uint64_t list3[13] = { 1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0 };
    const uint64_t updated3[3] = { 2, 1, 3 };
    const uint64_t unloaded3[1] = { 3 };
    const uint64_t effects3[] = {
        1, 0, 1, 255, 0, 0,
        3, 1, 833, 3, 0, 1,
    };
    const uint64_t records3[] = {
        1, 0, 0, 3, 0x41200000U, 0x42c80000U, 0xc1a00000U,
        0x3f800000U, 0x3f800000U, 0x3f800000U, 0,
        0, 0,
    };
    fingerprint = hash_bridge(fingerprint, 3, list3, 3, updated3, 3,
                              unloaded3, 1, 2, effects3,
                              sizeof(effects3) / sizeof(effects3[0]),
                              records3, sizeof(records3) / sizeof(records3[0]));

    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, 1);

    printf("waterBombObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
