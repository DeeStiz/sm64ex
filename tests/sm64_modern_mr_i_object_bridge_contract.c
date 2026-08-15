#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_eye(
    uint64_t hash,
    uint64_t effects,
    uint64_t action,
    uint64_t king,
    uint64_t home_x,
    uint64_t home_y,
    uint64_t home_z,
    uint64_t position_x,
    uint64_t position_y,
    uint64_t position_z,
    uint64_t move_yaw,
    uint64_t move_pitch,
    uint64_t angle_velocity_yaw,
    uint64_t turn_accum,
    uint64_t turn_direction,
    uint64_t turn_timer,
    uint64_t particle_timer,
    uint64_t particle_delay,
    uint64_t scale,
    uint64_t size,
    uint64_t timer,
    uint64_t tangible,
    uint64_t marked
) {
    const uint64_t values[] = {
        effects, action, king,
        home_x, home_y, home_z,
        position_x, position_y, position_z,
        move_yaw, move_pitch, angle_velocity_yaw,
        turn_accum, turn_direction, turn_timer,
        particle_timer, particle_delay, scale, size,
        timer, tangible, marked
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t hash_particle(
    uint64_t hash,
    uint64_t effects,
    uint64_t action,
    uint64_t position_x,
    uint64_t position_y,
    uint64_t position_z,
    uint64_t move_yaw,
    uint64_t forward_velocity,
    uint64_t velocity_y,
    uint64_t timer,
    uint64_t marked
) {
    const uint64_t values[] = {
        effects, action, position_x, position_y, position_z,
        move_yaw, forward_velocity, velocity_y, timer, marked
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t hash_body(
    uint64_t hash,
    uint64_t effects,
    uint64_t position_x,
    uint64_t position_y,
    uint64_t position_z,
    uint64_t scale,
    uint64_t relative_z,
    uint64_t animation_state,
    uint64_t timer,
    uint64_t marked
) {
    const uint64_t values[] = {
        effects, position_x, position_y, position_z,
        scale, relative_z, animation_state, timer, marked
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t hash_effect(
    uint64_t hash,
    uint64_t object_id,
    uint64_t kind,
    uint64_t action,
    uint64_t particle_action,
    uint64_t effects,
    uint64_t child_count,
    uint64_t child_id,
    uint64_t marked
) {
    const uint64_t values[] = {
        object_id, kind, action, particle_action,
        effects, child_count
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    if (child_count != 0) {
        hash = hash_u64(hash, child_id);
    }
    return hash_u64(hash, marked);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;

    fingerprint = hash_eye(
        fingerprint, 5, 0, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 256, 0, 0, 0, 30, 0,
        1065353216, 1065353216, 1, 0, 0
    );
    fingerprint = hash_eye(
        fingerprint, 12, 1, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 256, 0, 0, 0, 30, 0,
        1065353216, 1065353216, 2, 0, 0
    );
    fingerprint = hash_eye(
        fingerprint, 26, 2, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 65280, 0, 0, 0, 30, 3,
        1065353216, 1065353216, 1, 1, 0
    );
    fingerprint = hash_eye(
        fingerprint, 18, 2, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        3072, 0, 65280, 0, 255, 119, 1, 57,
        1065353216, 1065353216, 1, 1, 0
    );
    fingerprint = hash_eye(
        fingerprint, 3076, 3, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 256, 0, 0, 0, 30, 0,
        1058642330, 1058642330, 105, 0, 0
    );
    fingerprint = hash_eye(
        fingerprint, 78852, 3, 1,
        0, 0, 0, 0, 1120403456, 0,
        0, 0, 256, 0, 0, 0, 30, 0,
        1067030938, 1067030938, 105, 0, 1
    );
    fingerprint = hash_particle(
        fingerprint, 0, 0, 0, 1101004800, 1101004800,
        0, 1101004800, 1098907648, 1, 0
    );
    fingerprint = hash_particle(
        fingerprint, 114688, 1, 0, 1108344832, 1109393408,
        0, 1101004800, 1094713344, 3, 1
    );
    fingerprint = hash_body(
        fingerprint, 32, 0, 0, 0, 1073741824,
        1128792064, 0, 1, 0
    );
    fingerprint = hash_effect(fingerprint, 1, 0, 1, 255, 13, 0, 0, 0);
    fingerprint = hash_effect(fingerprint, 1, 0, 1, 255, 72, 1, 3, 0);

    printf("mrIObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
