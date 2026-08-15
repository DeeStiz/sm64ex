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
    uint16_t initial_yaw,
    uint16_t move_yaw,
    uint16_t pitch,
    uint16_t roll,
    uint32_t forward_bits,
    uint32_t position_y_bits,
    uint32_t timer,
    uint8_t intangible) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, initial_yaw);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, pitch);
    hash = hash_u64(hash, roll);
    hash = hash_u64(hash, forward_bits);
    hash = hash_u64(hash, position_y_bits);
    hash = hash_u64(hash, timer);
    return hash_u64(hash, intangible);
}

static uint64_t hash_bridge(
    uint64_t initial,
    uint64_t frame,
    int has_smoke,
    int unloaded,
    uint16_t effects,
    uint8_t action,
    uint32_t spawned_smoke,
    uint8_t record_action,
    uint8_t previous_action,
    uint32_t timer,
    uint32_t forward_bits,
    uint32_t move_yaw,
    uint32_t pitch,
    uint32_t roll,
    uint32_t position_y_bits,
    uint8_t intangible) {
    static const uint64_t base_counts[13] = {
        1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };
    static const uint64_t smoke_counts[13] = {
        1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0
    };
    uint64_t hash = hash_u64(initial, frame);
    for (unsigned index = 0; index < 13; ++index) {
        hash = hash_u64(hash, has_smoke ? smoke_counts[index] : base_counts[index]);
    }
    hash = hash_u64(hash, has_smoke ? 3 : 2);
    hash = hash_u64(hash, has_smoke ? 3 : 2);
    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, 1);
    if (has_smoke) {
        hash = hash_u64(hash, 3);
    }
    hash = hash_u64(hash, unloaded ? 1 : 0);
    if (unloaded) {
        hash = hash_u64(hash, 3);
    }
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, spawned_smoke);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, record_action);
    hash = hash_u64(hash, previous_action);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, forward_bits);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, pitch);
    hash = hash_u64(hash, roll);
    hash = hash_u64(hash, position_y_bits);
    hash = hash_u64(hash, intangible);
    return hash_u64(hash, 0); // smokeRecord is absent after end-of-frame unload
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_kernel(fingerprint, 259, 1, 0x1000, 0x1000, 0, 0,
                               0, 0x42f00000u, 1, 0);
    fingerprint = hash_kernel(fingerprint, 5, 2, 0x1000, 0x1000, 0, 0,
                               0, 0x42f00000u, 2, 0);
    fingerprint = hash_kernel(fingerprint, 1, 2, 0x1000, 0x1000, 0, 0,
                               0x40400000u, 0x42f00000u, 40, 0);
    fingerprint = hash_kernel(fingerprint, 1, 2, 0x1000, 0x1000, 0, 0,
                               0xc0400000u, 0x42f00000u, 41, 0);
    fingerprint = hash_kernel(fingerprint, 57, 2, 0x1000, 0x1100, 0, 0,
                               0x41f00000u, 0x42f00000u, 51, 0);
    fingerprint = hash_kernel(fingerprint, 73, 3, 0x1000, 0x1200, 0, 0,
                               0x41f00000u, 0x42f00000u, 152, 0);
    fingerprint = hash_kernel(fingerprint, 129, 4, 0, 0, 0x1000, 0x1000,
                               0xc1f00000u, 0x41a00000u, 1, 1);

    fingerprint = hash_bridge(fingerprint, 1, 0, 0, 259, 1, 0,
                              1, 0, 1, 0, 0, 0, 0, 0x42a00000u, 0);
    fingerprint = hash_bridge(fingerprint, 2, 0, 0, 5, 2, 0,
                              2, 1, 2, 0, 0, 0, 0, 0x42a00000u, 0);
    fingerprint = hash_bridge(fingerprint, 51, 1, 1, 57, 2, 3,
                              2, 2, 51, 0x41f00000u, 0, 0, 0, 0x42a00000u, 0);
    fingerprint = hash_bridge(fingerprint, 52, 1, 1, 73, 3, 3,
                              3, 2, 52, 0x41f00000u, 0, 0, 0, 0x42a00000u, 0);

    printf("bulletBillObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    return 0;
}
