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
    uint8_t size,
    uint8_t subtype,
    uint8_t action,
    uint32_t x,
    uint32_t y,
    uint32_t z,
    uint16_t move_yaw,
    uint16_t face_yaw,
    uint32_t forward,
    uint32_t velocity_y,
    uint16_t knockback,
    uint32_t timer,
    uint8_t tangible,
    uint8_t invisible,
    uint8_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, size);
    hash = hash_u64(hash, subtype);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, x);
    hash = hash_u64(hash, y);
    hash = hash_u64(hash, z);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, face_yaw);
    hash = hash_u64(hash, forward);
    hash = hash_u64(hash, velocity_y);
    hash = hash_u64(hash, knockback);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, tangible);
    hash = hash_u64(hash, invisible);
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
    hash = hash_u64(hash, radius);
    hash = hash_u64(hash, height);
    hash = hash_u64(hash, hurt_radius);
    hash = hash_u64(hash, hurt_height);
    return hash_u64(hash, interaction);
}

static uint64_t hash_bridge(uint64_t initial) {
    static const uint64_t list_counts[13] = {
        1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0
    };
    uint64_t hash = hash_u64(initial, 1); // frame
    for (unsigned index = 0; index < 13; ++index) {
        hash = hash_u64(hash, list_counts[index]);
    }
    hash = hash_u64(hash, 3); // player + two Bullies
    hash = hash_u64(hash, 3); // updated IDs
    hash = hash_u64(hash, 3);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, 0); // no unloads
    hash = hash_u64(hash, 2); // two effect records
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 0); // small
    hash = hash_u64(hash, 13);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 0);
    hash = hash_u64(hash, 2); // big object ID
    hash = hash_u64(hash, 1); // big size
    hash = hash_u64(hash, 13);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 0); // big not deleted
    hash = hash_record(
        hash,
        1, 0, 1,
        0, 0x42c80000U, 0x40a00000U,
        0, 0x40a00000U,
        0x42920000U, 0x42f60000U, 0x427c0000U, 0x42e20000U,
        1
    );
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_kernel(fingerprint, 13, 0, 0, 1,
                              0, 0x42c80000U, 0x40a00000U,
                              0, 0, 0x40a00000U, 0, 0, 1, 1, 0, 0);
    fingerprint = hash_kernel(fingerprint, 5, 0, 0, 1,
                              0x3f92f350U, 0x42c80000U, 0x40f8b143U,
                              0x1000, 0, 0x40400000U, 0, 0, 1, 1, 0, 0);
    fingerprint = hash_kernel(fingerprint, 5, 0, 0, 1,
                              0x410cd3d7U, 0x42c80000U, 0x41d1fe6cU,
                              0x1000, 0, 0x41a00000U, 0, 0, 11, 1, 0, 0);
    fingerprint = hash_kernel(fingerprint, 9, 0, 0, 0,
                              0x412b7132U, 0x42c80000U, 0x41f6f2f3U,
                              0x1000, 0, 0x40a00000U, 0, 0, 12, 1, 0, 0);
    fingerprint = hash_kernel(fingerprint, 35, 0, 0, 2,
                              0x412b7132U, 0x42c80000U, 0x41fef2f3U,
                              0, 0, 0x3f800000U, 0, 1, 13, 1, 0, 0);
    fingerprint = hash_kernel(fingerprint, 37, 0, 0, 1,
                              0x412b7132U, 0x42c80000U, 0x4203797aU,
                              0, 0, 0x3f800000U, 0, 0, 1, 1, 0, 0);
    fingerprint = hash_kernel(fingerprint, 17, 0, 0, 3,
                              0x412b7132U, 0x42c80000U, 0x41def2f4U,
                              0x8000, 0, 0x40a00000U, 0, 0, 1, 1, 0, 0);
    fingerprint = hash_kernel(fingerprint, 9, 0, 0, 0,
                              0x412b7132U, 0x42c80000U, 0x4203797aU,
                              0, 0, 0x40a00000U, 0, 0, 16, 1, 0, 0);
    fingerprint = hash_kernel(fingerprint, 833, 0, 0, 100,
                              0x412b7132U, 0x42c80000U, 0x4203797aU,
                              0, 0, 0x40a00000U, 0, 0, 1, 1, 0, 1);
    fingerprint = hash_kernel(fingerprint, 897, 1, 16, 100,
                              0, 0x44898000U, 0,
                              0, 0, 0, 0, 0, 1, 1, 0, 1);
    fingerprint = hash_bridge(fingerprint);

    printf("bullyObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
