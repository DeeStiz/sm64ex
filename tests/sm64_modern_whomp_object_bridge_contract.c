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
    uint64_t size,
    uint64_t action,
    uint64_t home_x,
    uint64_t home_y,
    uint64_t home_z,
    uint64_t position_x,
    uint64_t position_y,
    uint64_t position_z,
    uint64_t move_yaw,
    uint64_t face_pitch,
    uint64_t angle_velocity_pitch,
    uint64_t forward_velocity,
    uint64_t velocity_y,
    uint64_t health,
    uint64_t sub_action,
    uint64_t shake_value,
    uint64_t timer,
    uint64_t tangible,
    uint64_t hidden,
    uint64_t marked
) {
    const uint64_t values[] = {
        effects, size, action,
        home_x, home_y, home_z,
        position_x, position_y, position_z,
        move_yaw, face_pitch, angle_velocity_pitch,
        forward_velocity, velocity_y, health,
        sub_action, shake_value, timer,
        tangible, hidden, marked
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t hash_effect(
    uint64_t hash,
    uint64_t object_id,
    uint64_t size,
    uint64_t action,
    uint64_t effects,
    uint64_t health,
    uint64_t marked
) {
    const uint64_t values[] = { object_id, size, action, effects, health, marked };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;

    fingerprint = hash_state(
        fingerprint, 3, 0, 0,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0
    );
    fingerprint = hash_state(
        fingerprint, 35, 0, 1,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1106247680,
        0, 0, 0, 0, 0, 1, 0, 0, 2, 1, 0, 0
    );
    fingerprint = hash_state(
        fingerprint, 162, 0, 3,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1109131264,
        0, 0, 0, 1091567616, 0, 1, 0, 0, 1, 1, 0, 0
    );
    fingerprint = hash_state(
        fingerprint, 386, 0, 4,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1109131264,
        0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0
    );
    fingerprint = hash_state(
        fingerprint, 258, 0, 5,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1109131264,
        0, 16384, 0, 0, 3229614080, 1, 0, 0, 9, 1, 0, 0
    );
    fingerprint = hash_state(
        fingerprint, 1538, 0, 6,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1109131264,
        0, 16384, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0
    );
    fingerprint = hash_state(
        fingerprint, 4098, 0, 8,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1109131264,
        0, 16384, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0
    );
    fingerprint = hash_state(
        fingerprint, 1885186, 0, 8,
        1092616192, 1101004800, 1106247680,
        1092616192, 1101004800, 1109131264,
        0, 16384, 0, 0, 0, 1, 0, 0, 2, 0, 0, 1
    );
    fingerprint = hash_state(
        fingerprint, 15, 1, 2,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 3, 1, 0, 1, 1, 0, 0
    );
    fingerprint = hash_state(
        fingerprint, 116226, 1, 6,
        0, 0, 0, 0, 3238002688, 0,
        0, 0, 0, 0, 0, 1, 1, 1, 2, 1, 0, 0
    );
    fingerprint = hash_state(
        fingerprint, 517122, 1, 9,
        0, 0, 0, 0, 1119354880, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0
    );
    fingerprint = hash_effect(fingerprint, 1, 0, 1, 35, 1, 0);

    printf("whompObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
