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

static uint64_t hash_state(
    uint64_t hash,
    uint64_t effects,
    uint64_t action,
    uint64_t held,
    uint64_t home_x,
    uint64_t home_y,
    uint64_t home_z,
    uint64_t position_x,
    uint64_t position_y,
    uint64_t position_z,
    uint64_t move_yaw,
    uint64_t forward_velocity,
    uint64_t velocity_y,
    uint64_t animation_state,
    uint64_t throw_state,
    uint64_t collided_count,
    uint64_t animation_rate,
    uint64_t tangible,
    uint64_t hidden,
    uint64_t marked,
    uint64_t timer
) {
    const uint64_t values[] = {
        effects, action, held,
        home_x, home_y, home_z,
        position_x, position_y, position_z,
        move_yaw, forward_velocity, velocity_y,
        animation_state, throw_state, collided_count,
        animation_rate, tangible, hidden, marked, timer
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t hash_child(
    uint64_t hash,
    uint64_t effects,
    uint64_t position_x,
    uint64_t position_y,
    uint64_t position_z,
    uint64_t move_yaw,
    uint64_t consumed
) {
    const uint64_t values[] = { effects, position_x, position_y, position_z, move_yaw, consumed };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t hash_effect(
    uint64_t hash,
    uint64_t object_id,
    uint64_t kind,
    uint64_t effects,
    uint64_t action,
    uint64_t held,
    uint64_t consumed
) {
    const uint64_t values[] = { object_id, kind, effects, action, held, consumed };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;

    fingerprint = hash_state(
        fingerprint, 12, 0, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 0, 0, 0, 0, 1065353216, 0, 1, 0, 1
    );
    fingerprint = hash_state(
        fingerprint, 19, 1, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 0, 0, 0, 0, 1065353216, 1, 0, 0, 2
    );
    fingerprint = hash_state(
        fingerprint, 32, 2, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 1
    );
    fingerprint = hash_state(
        fingerprint, 256, 3, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 0, 2, 1, 0, 0, 1, 0, 0, 1
    );
    fingerprint = hash_state(
        fingerprint, 768, 3, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 0, 2, 2, 0, 0, 1, 0, 0, 1
    );
    fingerprint = hash_child(
        fingerprint, 1024, 1129447424, 3253731328, 1106247680, 0, 1
    );
    fingerprint = hash_state(
        fingerprint, 10496, 0, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 0, 1, 2, 20, 0, 0, 1, 0, 1
    );
    fingerprint = hash_effect(fingerprint, 1, 0, 19, 1, 0, 0);
    fingerprint = hash_effect(fingerprint, 2, 1, 0, 255, 255, 0);

    printf("heaveHoObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
