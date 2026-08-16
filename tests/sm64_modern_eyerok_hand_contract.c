#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u32(uint64_t initial, uint32_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_i32(uint64_t initial, int32_t value) {
    return hash_u32(initial, (uint32_t) value);
}

static uint64_t hash_result(
    uint64_t initial,
    int32_t side,
    uint32_t action,
    uint32_t position_x,
    uint32_t position_y,
    uint32_t position_z,
    int32_t face_yaw,
    int32_t move_yaw,
    uint32_t forward_velocity,
    uint32_t velocity_y,
    uint32_t gravity,
    int32_t health,
    int32_t wake_up_timer,
    int32_t hand_timer,
    int32_t eye_timer,
    int32_t anim_state,
    uint32_t move_flags,
    int32_t collision_mode,
    uint32_t render_scale,
    int32_t timer,
    uint32_t effects,
    int32_t parent_num_hands,
    int32_t parent_active_hand,
    int32_t parent_busy_hand) {
    uint64_t hash = hash_i32(initial, side);
    hash = hash_u32(hash, action);
    hash = hash_u32(hash, position_x);
    hash = hash_u32(hash, position_y);
    hash = hash_u32(hash, position_z);
    hash = hash_i32(hash, face_yaw);
    hash = hash_i32(hash, move_yaw);
    hash = hash_u32(hash, forward_velocity);
    hash = hash_u32(hash, velocity_y);
    hash = hash_u32(hash, gravity);
    hash = hash_i32(hash, health);
    hash = hash_i32(hash, wake_up_timer);
    hash = hash_i32(hash, hand_timer);
    hash = hash_i32(hash, eye_timer);
    hash = hash_i32(hash, anim_state);
    hash = hash_u32(hash, move_flags);
    hash = hash_i32(hash, collision_mode);
    hash = hash_u32(hash, render_scale);
    hash = hash_i32(hash, timer);
    hash = hash_u32(hash, effects);
    hash = hash_i32(hash, parent_num_hands);
    hash = hash_i32(hash, parent_active_hand);
    return hash_i32(hash, parent_busy_hand);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_result(fingerprint, -1, 0, UINT32_C(0xc41c0000), UINT32_C(0x42480000), UINT32_C(0x43480000), 0, 0, 0, 0, UINT32_C(0xc0800000), 4, 0, 0, 0, 0, 0, 1, UINT32_C(0xbfc00000), 1, 0, 2, 0, 0);
    fingerprint = hash_result(fingerprint, -1, 1, UINT32_C(0xc41c0000), UINT32_C(0x42480000), UINT32_C(0x43480000), 0, 0, 0, 0, UINT32_C(0xc0800000), 4, 4, 0, 0, 0, 0, 0, UINT32_C(0xbfc00000), 2, 0, 3, 0, 0);
    fingerprint = hash_result(fingerprint, -1, 6, 0, 0, 0, 0, 512, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, UINT32_C(0xbfc00000), 1, 256, 2, -1, 0);
    fingerprint = hash_result(fingerprint, 1, 2, 0, 0, 0, 0, 0, 0, 0, UINT32_C(0xc0800000), 4, 0, 0, 0, 0, 0, 0, UINT32_C(0x3fc00000), 1, 256, 2, -1, 0);
    fingerprint = hash_result(fingerprint, 1, 3, 0, 0, 0, 0, 0x3000, UINT32_C(0x42480000), 0, UINT32_C(0xc0800000), 4, 0, 2, 60, 0, 0, 3, UINT32_C(0x3fc00000), 2, 512, 1, 0, 1);
    fingerprint = hash_result(fingerprint, 1, 12, 0, 0, 0, 0, -32768, UINT32_C(0x41200000), UINT32_C(0x41f00000), UINT32_C(0xc0800000), 3, 0, 2, 60, 3, 0, 3, UINT32_C(0x3fc00000), 3, 1027, 1, 0, 1);
    fingerprint = hash_result(fingerprint, 1, 13, 0, 0, 0, 0, -32768, 0, UINT32_C(0x41f00000), UINT32_C(0xc0800000), 3, 0, 2, 60, 3, 0, 0, UINT32_C(0x3fc00000), 4, 4096, 2, 0, 0);
    fingerprint = hash_result(fingerprint, 1, 14, 0, 0, 0, 0, -32768, 0, UINT32_C(0x41f00000), UINT32_C(0xc0800000), 3, 0, 2, 60, 3, 0, 0, UINT32_C(0x3fc00000), 5, 8192, 1, 0, 0);
    fingerprint = hash_result(fingerprint, 1, 5, 0, 0, 0, 0, -32768, 0, UINT32_C(0x41f00000), UINT32_C(0xc0800000), 3, 0, 2, 60, 3, 0, 0, UINT32_C(0x3fc00000), 6, 0, 1, 1, 0);
    fingerprint = hash_result(fingerprint, 1, 1, 0, 0, 0, 0, -32768, 0, UINT32_C(0x41f00000), UINT32_C(0xc0800000), 3, 0, 2, 60, 3, 0, 0, UINT32_C(0x3fc00000), 7, 0, 1, 0, 0);
    fingerprint = hash_result(fingerprint, -1, 10, 0, 0, 0, 256, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, UINT32_C(0xbfc00000), 1, 256, 2, 0, 0);
    fingerprint = hash_result(fingerprint, -1, 11, 0, 0, 0, 256, 16640, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, UINT32_C(0xbfc00000), 2, 0, 2, -1, 0);
    fingerprint = hash_result(fingerprint, -1, 11, 0, 0, 0, 256, 16640, UINT32_C(0x41f00000), UINT32_C(0x42c80000), 0, 4, 0, 0, 0, 0, 0, 0, UINT32_C(0xbfc00000), 3, 0, 2, -1, 0);
    fingerprint = hash_result(fingerprint, 1, 7, 0, UINT32_C(0x439b0000), 0, 0, 0, 0, 0, UINT32_C(0xc0800000), 4, 0, 0, 0, 0, 0, 0, UINT32_C(0x3fc00000), 1, 0, 2, 0, 0);
    fingerprint = hash_result(fingerprint, 1, 7, 0, UINT32_C(0x439b0000), 0, 0, 0, 0, 0, UINT32_C(0xc0800000), 4, 0, 0, 0, 0, 0, 0, UINT32_C(0x3fc00000), 22, 28, 2, 0, 0);
    fingerprint = hash_result(fingerprint, 1, 15, 0, 0, 0, 0, -32768, 0, UINT32_C(0x42480000), UINT32_C(0xc0800000), 0, 0, 0, 0, 3, 0, 0, UINT32_C(0x3fc00000), 1, 1027, 1, 0, 0);
    fingerprint = hash_result(fingerprint, 1, 15, 0, 0, 0, 0, -32768, 0, UINT32_C(0x42480000), UINT32_C(0xc0800000), 0, 0, 0, 0, 3, 0, 0, UINT32_C(0x3fc00000), 2, 16608, 2, 0, 0);
    printf("eyerokHandFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern Eyerok hand C contract passed\n");
    return 0;
}
