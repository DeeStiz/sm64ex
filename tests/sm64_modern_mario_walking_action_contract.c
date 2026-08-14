#include <stdint.h>
#include <stdio.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

#define INPUT_NONZERO_ANALOG UINT16_C(0x0001)
#define INPUT_A_PRESSED      UINT16_C(0x0002)
#define INPUT_ABOVE_SLIDE    UINT16_C(0x0008)
#define INPUT_FIRST_PERSON   UINT16_C(0x0010)
#define INPUT_UNKNOWN_5      UINT16_C(0x0020)
#define INPUT_B_PRESSED      UINT16_C(0x2000)
#define INPUT_Z_PRESSED      UINT16_C(0x8000)

#define ACT_STANDING_AGAINST_WALL UINT32_C(0x0c400209)
#define ACT_BRAKING               UINT32_C(0x04000445)
#define ACT_DECELERATING          UINT32_C(0x0400044a)
#define ACT_BEGIN_SLIDING         UINT32_C(0x00000050)
#define ACT_DIVE                  UINT32_C(0x0188088a)
#define ACT_MOVE_PUNCHING         UINT32_C(0x00800457)
#define ACT_TURNING_AROUND        UINT32_C(0x00000443)
#define ACT_CROUCH_SLIDE          UINT32_C(0x04808459)
#define ACT_FREEFALL              UINT32_C(0x0100088c)

struct input {
    uint16_t flags;
    uint8_t terrain_slide, downhill;
    uint16_t action_state;
    uint32_t action_argument;
    int16_t face_yaw, intended_yaw;
    float intended_magnitude, forward_velocity, stick_magnitude, floor_normal_y;
    uint8_t ground_mode;
};

struct result {
    uint8_t intent;
    uint32_t action, argument;
    int16_t face_yaw;
    float forward_velocity, vx, vy, vz;
    uint16_t action_state, action_timer, animation;
    int32_t acceleration;
    uint8_t walk_sound, wall_sound, dust, drop, ledge, tilt;
};

static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_u32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_f32(uint64_t h, float v) {
    uint32_t bits; __builtin_memcpy(&bits, &v, sizeof(bits)); return hash_u32(h, bits);
}
static uint64_t hash_result(uint64_t h, struct result r) {
    h = hash_u8(h, r.intent);
    h = hash_u32(h, r.action);
    h = hash_u32(h, r.argument);
    h = hash_u16(h, (uint16_t)r.face_yaw);
    h = hash_f32(h, r.forward_velocity);
    h = hash_f32(h, r.vx); h = hash_f32(h, r.vy); h = hash_f32(h, r.vz);
    h = hash_u16(h, r.action_state); h = hash_u16(h, r.action_timer);
    h = hash_u16(h, r.animation);
    h = hash_u32(h, (uint32_t)r.acceleration);
    h = hash_u8(h, r.walk_sound); h = hash_u8(h, r.wall_sound);
    h = hash_u8(h, r.dust); h = hash_u8(h, r.drop);
    h = hash_u8(h, r.ledge); return hash_u8(h, r.tilt);
}

static struct result transition(uint8_t intent, uint32_t action, uint32_t argument,
                                int16_t face_yaw, float forward, float vx, float vy, float vz) {
    return (struct result){intent, action, argument, face_yaw, forward, vx, vy, vz,
                           0, 0, UINT16_MAX, 0, 0, 0, 0, 1, 0, 0};
}

static struct result run(struct input in) {
    const float x = 0.0f, y = 0.0f, z = 6.0f;
    const uint32_t no_action = UINT32_MAX;
    if ((in.flags & INPUT_ABOVE_SLIDE)
        && (in.terrain_slide || in.forward_velocity <= -1.0f || in.downhill)) {
        return transition(1, ACT_BEGIN_SLIDING, 0, in.face_yaw, in.forward_velocity, x, y, z);
    }
    if (in.flags & INPUT_FIRST_PERSON) {
        if (in.action_state == 1) {
            return transition(2, ACT_STANDING_AGAINST_WALL, 0,
                              (int16_t)in.action_argument, in.forward_velocity, x, y, z);
        }
        if (in.forward_velocity >= 16.0f && in.floor_normal_y >= 0.17364818f) {
            return transition(3, ACT_BRAKING, 0, in.face_yaw, in.forward_velocity, x, y, z);
        }
        return transition(4, ACT_DECELERATING, 0, in.face_yaw, in.forward_velocity, x, y, z);
    }
    if (in.flags & INPUT_A_PRESSED) {
        return transition(5, no_action, 0, in.face_yaw, in.forward_velocity, x, y, z);
    }
    if (in.flags & INPUT_B_PRESSED) {
        if (in.forward_velocity >= 29.0f && in.stick_magnitude > 48.0f) {
            return transition(6, ACT_DIVE, 1, in.face_yaw, in.forward_velocity, x, 20.0f, z);
        }
        return transition(7, ACT_MOVE_PUNCHING, 0, in.face_yaw, in.forward_velocity, x, y, z);
    }
    if (in.flags & INPUT_UNKNOWN_5) {
        if (in.action_state == 1) {
            return transition(2, ACT_STANDING_AGAINST_WALL, 0,
                              (int16_t)in.action_argument, in.forward_velocity, x, y, z);
        }
        if (in.forward_velocity >= 16.0f && in.floor_normal_y >= 0.17364818f) {
            return transition(3, ACT_BRAKING, 0, in.face_yaw, in.forward_velocity, x, y, z);
        }
        return transition(4, ACT_DECELERATING, 0, in.face_yaw, in.forward_velocity, x, y, z);
    }
    int32_t d_yaw = (int16_t)((int32_t)in.intended_yaw - (int32_t)in.face_yaw);
    if ((d_yaw < -0x471c || d_yaw > 0x471c) && in.forward_velocity >= 16.0f) {
        return transition(8, ACT_TURNING_AROUND, 0, in.face_yaw, in.forward_velocity, x, y, z);
    }
    if (in.flags & INPUT_Z_PRESSED) {
        return transition(9, ACT_CROUCH_SLIDE, 0, in.face_yaw, in.forward_velocity, x, y, z);
    }

    float forward = in.forward_velocity;
    const float target = in.intended_magnitude < 32.0f ? in.intended_magnitude : 32.0f;
    if (forward <= 0.0f) forward += 1.1f;
    else if (forward <= target) forward += 1.1f - forward / 43.0f;
    else if (in.floor_normal_y >= 0.95f) forward -= 1.0f;
    if (forward > 48.0f) forward = 48.0f;

    if (in.ground_mode == 1) {
        return (struct result){10, ACT_FREEFALL, 0, in.face_yaw, forward, x, y, z,
                               0, 0, 0x56, 0, 0, 0, 0, 1, 1, 1};
    }
    if (in.ground_mode == 2) {
        const int32_t wall_angle = -0x2000;
        float capped_forward = forward;
        float vx = x, vz = z;
        if (capped_forward > 6.0f) { capped_forward = 6.0f; vx = 0.0f; vz = 6.0f; }
        const int16_t wall_dyaw = (int16_t)(wall_angle - (int16_t)in.face_yaw);
        const int32_t acceleration = (int32_t)(sqrtf(36.0f) * 2.0f * 65536.0f);
        if (wall_dyaw <= -0x71c8 || wall_dyaw >= 0x71c8) {
            return (struct result){0, no_action, 0, in.face_yaw, capped_forward, vx, y, vz,
                                   0, 0, 0xffff, acceleration, 1, 0, 0, 1, 1, 1};
        }
        return (struct result){0, no_action, UINT32_C(0x6000), in.face_yaw, capped_forward, vx, y, vz,
                               1, 0, 0x80, acceleration, 0, 2, 1, 1, 1, 1};
    }

    const float animation_speed = forward > in.intended_magnitude ? forward : in.intended_magnitude;
    const float speed = animation_speed < 4.0f ? 4.0f : animation_speed;
    const int32_t acceleration = (int32_t)((double)(speed / 4.0f) * 65536.0);
    return (struct result){0, no_action, 0, in.face_yaw, forward, x, y, z,
                           0, 2, 0x48, acceleration, 0, 0, 0, 1, 1, 1};
}

static struct input base(uint16_t flags) {
    return (struct input){flags, 0, 0, 0, 0, 0, 0, 20.0f, 12.0f, 0.0f, 1.0f, 0};
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    struct input in;
    in = base(INPUT_ABOVE_SLIDE); in.terrain_slide = 1; h = hash_result(h, run(in));
    in = base(INPUT_FIRST_PERSON); in.action_state = 1; in.action_argument = 0xbeef; h = hash_result(h, run(in));
    in = base(INPUT_FIRST_PERSON); in.forward_velocity = 20; h = hash_result(h, run(in));
    in = base(INPUT_FIRST_PERSON); in.forward_velocity = 10; h = hash_result(h, run(in));
    in = base(INPUT_A_PRESSED); h = hash_result(h, run(in));
    in = base(INPUT_B_PRESSED); in.forward_velocity = 30; in.stick_magnitude = 49; h = hash_result(h, run(in));
    in = base(INPUT_B_PRESSED); h = hash_result(h, run(in));
    in = base(INPUT_NONZERO_ANALOG); in.intended_yaw = 0x6000; in.forward_velocity = 20; h = hash_result(h, run(in));
    in = base(INPUT_Z_PRESSED); h = hash_result(h, run(in));
    in = base(0); in.forward_velocity = 4; h = hash_result(h, run(in));
    in = base(0); in.ground_mode = 1; h = hash_result(h, run(in));
    in = base(0); in.forward_velocity = 20; in.ground_mode = 2; h = hash_result(h, run(in));
    printf("marioWalkingActionFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
