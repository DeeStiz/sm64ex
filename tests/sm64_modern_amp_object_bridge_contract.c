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
    uint32_t scale_bits,
    uint32_t position_x_bits,
    uint32_t position_y_bits,
    uint32_t position_z_bits,
    uint16_t move_yaw,
    uint16_t face_yaw,
    uint16_t face_pitch,
    uint32_t forward_bits,
    uint32_t phase,
    uint32_t timer,
    uint8_t locked,
    uint8_t invisible,
    uint8_t tangible) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, kind);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, scale_bits);
    hash = hash_u64(hash, position_x_bits);
    hash = hash_u64(hash, position_y_bits);
    hash = hash_u64(hash, position_z_bits);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, face_yaw);
    hash = hash_u64(hash, face_pitch);
    hash = hash_u64(hash, forward_bits);
    hash = hash_u64(hash, phase);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, locked);
    hash = hash_u64(hash, invisible);
    return hash_u64(hash, tangible);
}

static uint64_t hash_record(
    uint64_t initial,
    uint8_t action,
    uint8_t previous_action,
    uint32_t timer,
    uint32_t position_x_bits,
    uint32_t position_y_bits,
    uint32_t position_z_bits,
    uint32_t scale_bits,
    uint32_t face_yaw,
    uint32_t face_pitch,
    uint32_t radius_bits,
    uint32_t down_bits,
    uint32_t graph_flags,
    uint32_t interaction_type) {
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, previous_action);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, position_x_bits);
    hash = hash_u64(hash, position_y_bits);
    hash = hash_u64(hash, position_z_bits);
    hash = hash_u64(hash, scale_bits);
    hash = hash_u64(hash, face_yaw);
    hash = hash_u64(hash, face_pitch);
    hash = hash_u64(hash, radius_bits);
    hash = hash_u64(hash, down_bits);
    hash = hash_u64(hash, graph_flags);
    return hash_u64(hash, interaction_type);
}

static uint64_t hash_bridge(
    uint64_t initial,
    uint64_t frame,
    uint16_t first_effects,
    uint8_t first_homing_action,
    uint16_t second_effects,
    uint8_t second_fixed_action,
    uint8_t first_homing_tangible,
    uint8_t first_homing_invisible,
    uint8_t second_fixed_tangible,
    uint8_t second_fixed_invisible,
    uint8_t first_record_action,
    uint8_t first_record_previous,
    uint32_t first_record_timer,
    uint32_t first_x,
    uint32_t first_y,
    uint32_t first_z,
    uint32_t first_scale,
    uint32_t first_yaw,
    uint32_t first_pitch,
    uint8_t second_record_action,
    uint8_t second_record_previous,
    uint32_t second_record_timer,
    uint32_t second_x,
    uint32_t second_y,
    uint32_t second_z,
    uint32_t second_scale,
    uint32_t second_yaw,
    uint32_t second_pitch) {
    static const uint64_t list_counts[13] = {
        1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0
    };
    uint64_t hash = hash_u64(initial, frame);
    for (unsigned index = 0; index < 13; ++index) {
        hash = hash_u64(hash, list_counts[index]);
    }
    hash = hash_u64(hash, 3); // player + two general actors
    hash = hash_u64(hash, 3); // updated IDs
    hash = hash_u64(hash, 3);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 2);
    hash = hash_u64(hash, 0); // no unloads
    hash = hash_u64(hash, 2); // two effect records
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 0); // homing kind
    hash = hash_u64(hash, first_effects);
    hash = hash_u64(hash, first_homing_action);
    hash = hash_u64(hash, first_homing_tangible);
    hash = hash_u64(hash, first_homing_invisible);
    hash = hash_u64(hash, 2); // fixed effect object ID
    hash = hash_u64(hash, 2); // fixed kind
    hash = hash_u64(hash, second_effects);
    hash = hash_u64(hash, second_fixed_action);
    hash = hash_u64(hash, second_fixed_tangible);
    hash = hash_u64(hash, second_fixed_invisible);
    hash = hash_record(
        hash,
        first_record_action,
        first_record_previous,
        first_record_timer,
        first_x,
        first_y,
        first_z,
        first_scale,
        first_yaw,
        first_pitch,
        0x42200000u,
        0x42200000u,
        32,
        1
    );
    return hash_record(
        hash,
        second_record_action,
        second_record_previous,
        second_record_timer,
        second_x,
        second_y,
        second_z,
        second_scale,
        second_yaw,
        second_pitch,
        0x42200000u,
        0x42200000u,
        32,
        1
    );
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_kernel(fingerprint, 3, 0, 1, 0x3dcccccdU,
                              0x41200000U, 0x41a00000U, 0x41f00000U,
                              0, 0, 0, 0, 1, 1, 0, 0, 1);
    fingerprint = hash_kernel(fingerprint, 1029, 0, 2, 0x3f800000U,
                              0x41200000U, 0x41a00000U, 0x41f00000U,
                              0, 0, 0, 0, 1, 92, 0, 0, 1);
    fingerprint = hash_kernel(fingerprint, 769, 0, 2, 0x3f800000U,
                              0x41200000U, 0x437bf5d9U, 0x42340000U,
                              0, 0, 0, 0x41700000U, 2, 1, 1, 0, 1);
    fingerprint = hash_kernel(fingerprint, 777, 0, 3, 0x3f800000U,
                              0x41200000U, 0x4373e6ddU, 0x42700000U,
                              0, 0, 0, 0x41700000U, 3, 1, 1, 0, 1);
    fingerprint = hash_kernel(fingerprint, 17, 0, 0, 0x3f800000U,
                              0x41200000U, 0x41a00000U, 0x41f00000U,
                              0, 0, 0, 0, 4, 152, 1, 1, 1);
    fingerprint = hash_kernel(fingerprint, 769, 1, 2, 0x3f800000U,
                              0x42c80000U, 0x43655214U, 0x44160000U,
                              0x400, 0x4400, 0, 0, 2, 1, 0, 0, 1);
    fingerprint = hash_kernel(fingerprint, 513, 2, 2, 0x3f800000U,
                              0, 0x42ef181aU, 0,
                              0, 0x1000, 0x1000, 0, 3, 1, 0, 0, 1);
    fingerprint = hash_kernel(fingerprint, 193, 1, 2, 0x3f800000U,
                              0x42c80000U, 0x43655214U, 0x44160000U,
                              0x400, 0x4400, 0, 0, 2, 92, 0, 0, 1);

    fingerprint = hash_bridge(
        fingerprint, 1, 3, 1, 513, 2, 1, 0, 1, 0,
        1, 0, 1, 0x41200000U, 0x41a00000U, 0x41f00000U, 0x3dcccccdU,
        0, 0, 2, 2, 1, 0x42c80000U, 0x435be359U, 0x43960000U,
        0x3f800000U, 0x1000, 0x1000
    );
    fingerprint = hash_bridge(
        fingerprint, 93, 801, 4, 545, 4, 1, 0, 1, 0,
        4, 2, 1, 0x41200000U, 0x4317f5d9U, 0x42340000U, 0x3f800000U,
        0, 0, 4, 2, 93, 0x42c80000U, 0x433658deU, 0x43960000U,
        0x3f800000U, 0, 0
    );

    printf("ampObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
