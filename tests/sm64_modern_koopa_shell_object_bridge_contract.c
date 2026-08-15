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

static uint64_t hash_state(
    uint64_t initial,
    uint64_t effects,
    uint8_t kind,
    uint8_t action,
    uint8_t held,
    uint32_t x,
    uint32_t y,
    uint32_t z,
    uint32_t floor_height,
    uint16_t move_yaw,
    uint16_t face_yaw,
    uint32_t forward,
    uint32_t velocity_y,
    uint32_t move_flags,
    uint16_t floor_type,
    uint8_t hidden,
    uint8_t marked,
    uint32_t timer) {
    const uint64_t values[] = {
        effects, kind, action, held, x, y, z, floor_height,
        move_yaw, face_yaw, forward, velocity_y, move_flags,
        floor_type, hidden, marked, timer,
    };
    uint64_t hash = initial;
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
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
    uint32_t held,
    uint32_t interaction) {
    uint64_t hash = hash_u64(initial, present);
    if (!present) return hash;
    const uint64_t values[] = {
        action, previous_action, timer, x, y, z, held, interaction,
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
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
    uint64_t effect_record_count,
    const uint64_t *effects,
    size_t effect_value_count,
    const uint64_t *records,
    size_t record_count) {
    uint64_t hash = hash_u64(initial, frame);
    for (size_t index = 0; index < 13; ++index) hash = hash_u64(hash, list_counts[index]);
    hash = hash_u64(hash, object_counter);
    hash = hash_u64(hash, updated_count);
    for (size_t index = 0; index < updated_count; ++index) hash = hash_u64(hash, updated[index]);
    hash = hash_u64(hash, unloaded_count);
    for (size_t index = 0; index < unloaded_count; ++index) hash = hash_u64(hash, unloaded[index]);
    hash = hash_u64(hash, effect_record_count);
    for (size_t index = 0; index < effect_value_count; ++index) hash = hash_u64(hash, effects[index]);
    for (size_t index = 0; index < record_count; ++index) {
        hash = hash_u64(hash, records[index]);
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_state(fingerprint, 63, 0, 1, 0,
                              0x417a827aU, 0x42c00000U, 0xc1657d86U,
                              0, 0x2000, 0x2000, 0x41000000U, 0xc0800000U,
                              515, 0, 0, 0, 1);
    fingerprint = hash_state(fingerprint, 195, 0, 1, 0,
                              0x41f00000U, 0x42480000U, 0xc0800000U,
                              0, 0x2000, 0x3000, 0x41000000U, 0xc0800000U,
                              0, 0, 0, 0, 2);
    fingerprint = hash_state(fingerprint, 1571, 0, 0, 0,
                              0x41f00000U, 0, 0xc0800000U,
                              0, 0x2000, 0, 0x41000000U, 0xc0800000U,
                              0, 0, 0, 1, 3);
    fingerprint = hash_state(fingerprint, 2049, 1, 0, 1,
                              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1);
    fingerprint = hash_state(fingerprint, 1537, 1, 0, 2,
                              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2);

    const uint64_t lists1[13] = { 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1 };
    const uint64_t updated1[4] = { 3, 2, 1, 4 };
    const uint64_t unloaded1[1] = { 4 };
    const uint64_t effects1[] = {
        2, 1, 2049, 0, 0, 0,
        1, 0, 59, 1, 1, 4, 0,
    };
    const uint64_t records1[] = {
        1, 1, 0, 1, 0x4150fbc5U, 0x42c00000U, 0xc149be51U, 0, 524288,
        1, 0, 0, 1, 0xc1f00000U, 0x41a00000U, 0x40800000U, 1, 0,
        0,
    };
    fingerprint = hash_bridge(fingerprint, 1, lists1, 4, updated1, 4,
                              unloaded1, 1, 2, effects1, sizeof(effects1) / sizeof(effects1[0]),
                              records1, sizeof(records1) / sizeof(records1[0]));

    const uint64_t effects2[] = {
        2, 1, 4097, 0, 0, 0,
        1, 0, 1571, 0, 1, 4, 1,
    };
    const uint64_t records2[] = {
        0,
        1, 0, 0, 2, 0xc1f00000U, 0x41a00000U, 0x40800000U, 0, 2,
        0,
    };
    fingerprint = hash_bridge(fingerprint, 2, lists1, 4, updated1, 4,
                              (const uint64_t[]){ 1, 4 }, 2,
                              2, effects2, sizeof(effects2) / sizeof(effects2[0]),
                              records2, sizeof(records2) / sizeof(records2[0]));

    printf("koopaShellObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
