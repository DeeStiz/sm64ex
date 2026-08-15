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
    uint8_t kind,
    uint8_t action,
    uint32_t x,
    uint32_t y,
    uint32_t z,
    uint16_t yaw,
    uint16_t pitch,
    uint16_t roll,
    uint16_t target_yaw,
    uint16_t target_pitch,
    uint32_t speed,
    uint32_t forward,
    uint32_t velocity_y,
    uint32_t timer,
    uint8_t invisible,
    uint8_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, kind);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, x);
    hash = hash_u64(hash, y);
    hash = hash_u64(hash, z);
    hash = hash_u64(hash, yaw);
    hash = hash_u64(hash, pitch);
    hash = hash_u64(hash, roll);
    hash = hash_u64(hash, target_yaw);
    hash = hash_u64(hash, target_pitch);
    hash = hash_u64(hash, speed);
    hash = hash_u64(hash, forward);
    hash = hash_u64(hash, velocity_y);
    hash = hash_u64(hash, timer);
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
    uint32_t pitch,
    uint32_t roll,
    uint32_t graph_flags) {
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, previous_action);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, x);
    hash = hash_u64(hash, y);
    hash = hash_u64(hash, z);
    hash = hash_u64(hash, yaw);
    hash = hash_u64(hash, pitch);
    hash = hash_u64(hash, roll);
    return hash_u64(hash, graph_flags);
}

static uint64_t hash_bridge(
    uint64_t initial,
    uint64_t frame,
    int deleting,
    uint32_t record_timer,
    uint32_t record_x,
    uint32_t record_y,
    uint32_t record_z,
    uint32_t record_yaw,
    uint32_t record_pitch,
    uint32_t record_roll) {
    static const uint64_t list_counts[13] = {
        1, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0
    };
    uint64_t hash = hash_u64(initial, frame);
    for (unsigned index = 0; index < 13; ++index) {
        hash = hash_u64(hash, list_counts[index]);
    }
    hash = hash_u64(hash, 8); // player + seven general actors
    hash = hash_u64(hash, 8); // updated IDs
    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, 1);
    for (unsigned child = 3; child <= 8; ++child) {
        hash = hash_u64(hash, child);
    }
    hash = hash_u64(hash, deleting ? 6 : 0);
    if (deleting) {
        for (unsigned child = 3; child <= 8; ++child) {
            hash = hash_u64(hash, child);
        }
    }
    hash = hash_u64(hash, 7); // parent plus six children

    // Parent effect.
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 1); // spawner kind
    hash = hash_u64(hash, deleting ? 1 : 47);
    hash = hash_u64(hash, 1); // fly action
    hash = hash_u64(hash, deleting ? 0 : 6);
    if (!deleting) {
        for (unsigned child = 3; child <= 8; ++child) {
            hash = hash_u64(hash, child);
        }
    }
    hash = hash_u64(hash, 0);

    // Child effects.
    for (unsigned child = 3; child <= 8; ++child) {
        hash = hash_u64(hash, child);
        hash = hash_u64(hash, 0); // spawned kind
        hash = hash_u64(hash, deleting ? 17 : 35);
        hash = hash_u64(hash, 1);
        hash = hash_u64(hash, 0);
        hash = hash_u64(hash, deleting ? 1 : 0);
    }

    return hash_record(
        hash,
        1,
        deleting ? 1 : 0,
        record_timer,
        record_x,
        record_y,
        record_z,
        record_yaw,
        record_pitch,
        record_roll,
        32
    );
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_kernel(fingerprint, 1, 1, 0,
                              0x42c80000U, 0x43480000U, 0x43960000U,
                              0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0);
    fingerprint = hash_kernel(fingerprint, 47, 1, 1,
                              0x42c80000U, 0x43480000U, 0x43960000U,
                              0x1000, 2000, 0, 0x1000, 2000,
                              0x42200000U, 0, 0, 2, 0, 0);
    fingerprint = hash_kernel(fingerprint, 1, 1, 1,
                              0x42e067deU, 0x43406084U, 0x43a8a94cU,
                              0xce0, 0x744, 0x258, 0, 0xc066,
                              0x42200000U, 0x421d1150U, 0xc0f3ef89U, 3, 0, 0);
    fingerprint = hash_kernel(fingerprint, 35, 0, 1,
                              0, 0x43fa0000U, 0,
                              0x4000, 1000, 0, 0x4000, 1000,
                              0x42200000U, 0, 0, 1, 0, 0);
    fingerprint = hash_kernel(fingerprint, 17, 0, 1,
                              0x421f46e4U, 0x43f819c9U, 0,
                              0x4000, 1000, 0, 0x4000, 1000,
                              0x42200000U, 0x421f46e4U, 0xc0731b47U, 2, 0, 1);

    fingerprint = hash_bridge(
        fingerprint, 1, 0, 1,
        0x42c80000U, 0x43480000U, 0x43960000U,
        0x1000, 2000, 0
    );
    fingerprint = hash_bridge(
        fingerprint, 2, 1, 2,
        0x42e067deU, 0x43406084U, 0x43a8a94cU,
        0xce0, 0x744, 0x258
    );

    printf("birdObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
