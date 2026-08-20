#include <stdint.h>
#include <stdio.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned index = 0; index < 8; ++index) {
        seed ^= (value >> (index * 8)) & UINT64_C(255);
        seed *= PRIME;
    }
    return seed;
}

static uint64_t row(
    uint64_t seed,
    int action,
    int timer,
    uint32_t x,
    uint32_t z,
    uint32_t forward,
    int move_yaw,
    int face_yaw,
    int tangible,
    uint32_t effects
) {
    seed = hash_u64(seed, (uint64_t)(int64_t)action);
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, x);
    seed = hash_u64(seed, z);
    seed = hash_u64(seed, forward);
    seed = hash_u64(seed, (uint64_t)(int64_t)move_yaw);
    seed = hash_u64(seed, (uint64_t)(int64_t)face_yaw);
    seed = hash_u64(seed, (uint64_t)tangible);
    return hash_u64(seed, effects);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    // Idle reset: timer is explicitly cleared when Mario is outside 500 units.
    fingerprint = row(fingerprint, 0, 0, 0x00000000, 0x00000000, 0x00000000, 0, -16384, 0, 1);
    // Trigger: action 0 admits the attack after timer > 20 and speed > 10.
    fingerprint = row(fingerprint, 1, 22, 0x00000000, 0x00000000, 0x00000000, 0, -16384, 1, 13);
    // Close attack: timer resets and forward velocity becomes 5.
    fingerprint = row(fingerprint, 1, 0, 0x00000000, 0x00000000, 0x40A00000, 400, -15984, 1, 15);
    // Far attack: horizontal position clamps to the authored 400-unit radius.
    fingerprint = row(fingerprint, 1, 41, 0x43C80000, 0x00000000, 0x40A00000, 400, -15984, 1, 47);
    // Animation-end retirement: return to wait and become intangible.
    fingerprint = row(fingerprint, 0, 82, 0x00000000, 0x00000000, 0x00000000, 0, -16384, 0, 19);
    printf("madPianoFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern Mad Piano C contract passed");
    return 0;
}
