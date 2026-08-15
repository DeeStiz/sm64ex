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

static uint64_t hash_snufit(
    uint64_t initial, uint64_t effects, uint64_t action,
    uint64_t position_x, uint64_t position_y, uint64_t position_z,
    uint64_t home_x, uint64_t home_y, uint64_t home_z,
    uint64_t move_yaw, uint64_t move_pitch, uint64_t face_pitch,
    uint64_t circular_period, uint64_t body_scale_period,
    uint64_t body_base_scale, uint64_t body_scale, uint64_t scale,
    uint64_t recoil, uint64_t bullets, uint64_t timer,
    uint64_t tangible, uint64_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, position_x);
    hash = hash_u64(hash, position_y);
    hash = hash_u64(hash, position_z);
    hash = hash_u64(hash, home_x);
    hash = hash_u64(hash, home_y);
    hash = hash_u64(hash, home_z);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, move_pitch);
    hash = hash_u64(hash, face_pitch);
    hash = hash_u64(hash, circular_period);
    hash = hash_u64(hash, body_scale_period);
    hash = hash_u64(hash, body_base_scale);
    hash = hash_u64(hash, body_scale);
    hash = hash_u64(hash, scale);
    hash = hash_u64(hash, recoil);
    hash = hash_u64(hash, bullets);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, tangible);
    return hash_u64(hash, marked);
}

static uint64_t hash_bullet(
    uint64_t initial, uint64_t effects, uint64_t action,
    uint64_t position_x, uint64_t position_y, uint64_t position_z,
    uint64_t move_yaw, uint64_t move_pitch, uint64_t forward_velocity,
    uint64_t velocity_y, uint64_t gravity, uint64_t timer,
    uint64_t intangible, uint64_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, position_x);
    hash = hash_u64(hash, position_y);
    hash = hash_u64(hash, position_z);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, move_pitch);
    hash = hash_u64(hash, forward_velocity);
    hash = hash_u64(hash, velocity_y);
    hash = hash_u64(hash, gravity);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, intangible);
    return hash_u64(hash, marked);
}

static uint64_t hash_effect(
    uint64_t initial, uint64_t object_id, uint64_t kind,
    uint64_t action, uint64_t bullet_action, uint64_t effects,
    uint64_t child_count, const uint64_t *children, uint64_t marked) {
    uint64_t hash = hash_u64(initial, object_id);
    hash = hash_u64(hash, kind);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, bullet_action);
    hash = hash_u64(hash, effects);
    hash = hash_u64(hash, child_count);
    for (uint64_t index = 0; index < child_count; ++index) {
        hash = hash_u64(hash, children[index]);
    }
    return hash_u64(hash, marked);
}

int main(void) {
    uint64_t hash = FNV_OFFSET;

    hash = hash_snufit(hash, 133, 0,
                       1121704539, 1102716261, 1107777031,
                       1092616192, 1101004800, 1106247680,
                       4296, 0, 0, 400, 0, 0, 666, 1065353216,
                       0, 0, 1, 1, 0);
    hash = hash_snufit(hash, 143, 1,
                       1121704539, 1105199104, 1107777031,
                       1092616192, 1101004800, 1106247680,
                       6296, 512, 512, 400, 0, 600, 1000, 1072617750,
                       0, 0, 1, 1, 0);
    hash = hash_snufit(hash, 251, 1,
                       1121704539, 1105199104, 1107777031,
                       1092616192, 1101004800, 1106247680,
                       8192, 0, 0, 400, 62536, 580, 1000, 1072080880,
                       65506, 1, 1, 1, 0);

    hash = hash_bullet(hash, 0, 0, 0, 0, 1109393408,
                       0, 0, 1109393408, 0, 0, 1, 0, 0);
    hash = hash_bullet(hash, 2560, 1, 0, 0, 1108869120,
                       32768, 0, 1073741824, 1106247680, 3229614080, 2, 1, 0);
    hash = hash_bullet(hash, 0, 1, 0, 1106247680, 1108344832,
                       32768, 0, 1073741824, 1104150528, 3229614080, 3, 1, 0);
    hash = hash_bullet(hash, 5120, 0, 0, 0, 1109393408,
                       0, 0, 1109393408, 0, 0, 1, 0, 1);

    hash = hash_effect(hash, 1, 0, 0, 255, 135, 0, NULL, 0);
    const uint64_t child[] = { 2 };
    hash = hash_effect(hash, 1, 0, 1, 255, 251, 1, child, 0);

    printf("snufitObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)hash);
    return 0;
}
