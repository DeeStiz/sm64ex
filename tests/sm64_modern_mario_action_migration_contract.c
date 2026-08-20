#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern_mario_action_migration.h"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

SM64ModernStatus sm64_modern_gameplay_get_authority(
    SM64ModernGameplaySubsystem subsystem,
    SM64ModernAuthority *out_authority) {
    (void) subsystem;
    if (!out_authority) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    *out_authority = SM64_MODERN_AUTHORITY_C;
    return SM64_MODERN_STATUS_OK;
}

static uint32_t float_bits(float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & 0xffu;
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_output(uint64_t hash, uint32_t requested,
                            const SM64ModernMarioActionOutputV1 *output) {
    hash = hash_u32(hash, requested);
    hash = hash_u32(hash, output->action);
    hash = hash_u32(hash, output->previous_action);
    hash = hash_u32(hash, output->action_argument);
    hash = hash_u32(hash, output->action_state);
    hash = hash_u32(hash, output->action_timer);
    hash = hash_u32(hash, output->flags);
    hash = hash_u32(hash, output->velocity_x_bits);
    hash = hash_u32(hash, output->velocity_y_bits);
    hash = hash_u32(hash, output->velocity_z_bits);
    hash = hash_u32(hash, output->forward_velocity_bits);
    hash = hash_u32(hash, (uint32_t) output->face_pitch);
    hash = hash_u32(hash, (uint32_t) output->face_yaw);
    hash = hash_u32(hash, (uint32_t) output->face_roll);
    hash = hash_u32(hash, output->wall_kick_timer);
    hash = hash_u32(hash, output->peak_height_bits);
    hash = hash_u32(hash, output->dropped_held_object);
    hash = hash_u32(hash, output->dropped_ridden_object);
    return hash_u32(hash, output->hurt_counter);
}

static SM64ModernMarioActionInputV1 seeded(uint32_t requested) {
    SM64ModernMarioActionInputV1 input = {
        { SM64_MODERN_ABI_VERSION_1, sizeof(SM64ModernMarioActionInputV1) },
        1, requested, 0, UINT32_C(0x0c400201),
        UINT32_C(0x00070000), 0, 0, 0, 0, 0,
        float_bits(0), float_bits(6), float_bits(2), 0x3000,
        0x111, 0x2000, (int32_t) -0x222,
        float_bits(3), float_bits(4), float_bits(5), float_bits(37),
        float_bits(11), 0, 0, 0,
    };
    return input;
}

int main(void) {
    const uint32_t actions[] = {
        UINT32_C(0x04000440), UINT32_C(0x00000050), UINT32_C(0x03000881),
        UINT32_C(0x01000883), UINT32_C(0x03000888), UINT32_C(0x01000887),
        UINT32_C(0x000044f8), UINT32_C(0x018008ac),
    };
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned index = 0; index < sizeof(actions) / sizeof(actions[0]); ++index) {
        SM64ModernMarioActionInputV1 input = seeded(actions[index]);
        if (actions[index] == UINT32_C(0x03000881)) input.forward_velocity_bits = float_bits(20);
        SM64ModernMarioActionOutputV1 output;
        if (sm64_modern_gameplay_reference_mario_action(&input, &output)
            != SM64_MODERN_STATUS_OK) return 1;
        fingerprint = hash_output(fingerprint, actions[index], &output);
    }
    printf("marioActionMigrationFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern Mario action migration C contract passed\n");
    return 0;
}
