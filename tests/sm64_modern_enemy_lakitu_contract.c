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

static uint64_t hash_result(uint64_t initial, uint8_t action, uint8_t sub_action,
                            uint32_t forward_bits, uint32_t velocity_bits,
                            int16_t face_yaw, int16_t move_yaw,
                            int16_t face_forward_countdown, int16_t cooldown,
                            uint8_t num_spinies, uint8_t previous_attached,
                            uint32_t timer, uint16_t effects) {
    uint64_t hash = hash_u64(initial, action);
    hash = hash_u64(hash, sub_action);
    hash = hash_u64(hash, forward_bits);
    hash = hash_u64(hash, velocity_bits);
    hash = hash_u64(hash, (uint16_t)face_yaw);
    hash = hash_u64(hash, (uint16_t)move_yaw);
    hash = hash_u64(hash, (uint16_t)face_forward_countdown);
    hash = hash_u64(hash, (uint16_t)cooldown);
    hash = hash_u64(hash, num_spinies);
    hash = hash_u64(hash, previous_attached);
    hash = hash_u64(hash, timer);
    return hash_u64(hash, effects);
}

static uint64_t hash_attack_table(uint64_t initial) {
    static const uint8_t handlers[7] = { 0, 2, 2, 0, 0, 2, 2 };
    uint64_t hash = initial;
    for (unsigned attack = 0; attack < 7; ++attack) {
        hash = hash_u64(hash, attack);
        hash = hash_u64(hash, handlers[attack]);
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    // far: timer 1, hidden/no-subaction transition, animate
    fingerprint = hash_result(fingerprint, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2);
    // reveal: timer 2, main/reveal+animate
    fingerprint = hash_result(fingerprint, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3);
    // spawn: timer 3, hold, forward 20, velocity .4, cooldown 30, count 1
    fingerprint = hash_result(fingerprint, 1, 1, 0x41a00000u, 0x3ecccccd,
                               0, 0, 0, 30, 1, 1, 3, 14);
    // begin throw: timer 4, throw, countdown 20, cooldown 0
    fingerprint = hash_result(fingerprint, 1, 2, 0x41800000u, 0x3f4ccccd,
                               0, 0, 20, 0, 1, 1, 4, 18);
    // clear previous: timer 5, throw, countdown 19, no previous link
    fingerprint = hash_result(fingerprint, 1, 2, 0x41a00000u, 0x3f99999au,
                               0, 0, 19, 0, 1, 0, 5, 98);
    // finish throw: timer 6, no-spiny, cooldown 150
    fingerprint = hash_result(fingerprint, 1, 0, 0x41a00000u, 0x3fcccccd,
                               0, 0, 18, 150, 1, 0, 6, 2);
    // capped: timer 7, no-spiny, three spinies, cooldown 0
    fingerprint = hash_result(fingerprint, 1, 0, 0x41800000u, 0x40000000u,
                               0, 0, 17, 0, 3, 0, 7, 2);
    fingerprint = hash_attack_table(fingerprint);
    printf("enemyLakituFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    return 0;
}
