#include <stdint.h>
#include <stdio.h>

#include "PR/ultratypes.h"

#define AVOID_UB 1
#include "trig_tables.inc.c"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Init {
    uint8_t collision_model_index;
    int has_distance_override;
    float collision_distance_override;
};

struct Input {
    int32_t face_pitch;
    float pitch_velocity;
    float distance_to_mario;
    int16_t angle_to_mario;
    int16_t move_angle_yaw;
    int mario_is_on_platform;
};

struct Output {
    int32_t face_pitch;
    float pitch_velocity;
    int plays_rocking_sound;
};

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint32_t bits_f32(float value) {
    uint32_t bits;
    __builtin_memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static struct Init initialize(uint8_t behavior_byte) {
    return (struct Init) {
        behavior_byte,
        behavior_byte == 2,
        behavior_byte == 2 ? 2000.0f : 0.0f,
    };
}

static int oscillate_toward(int32_t *value, float *velocity, int32_t target,
                            float velocity_close_to_zero, float acceleration,
                            float slowdown) {
    int32_t start_value = *value;
    *value += (int32_t) *velocity;
    if (*value == target
        || ((*value - target) * (start_value - target) < 0
            && *velocity > -velocity_close_to_zero
            && *velocity < velocity_close_to_zero)) {
        *value = target;
        *velocity = 0.0f;
        return 1;
    }
    if (*value >= target) acceleration = -acceleration;
    if (*velocity * acceleration < 0.0f) acceleration *= slowdown;
    *velocity += acceleration;
    return 0;
}

static struct Output update(struct Input input) {
    struct Output output = { input.face_pitch, input.pitch_velocity,
                             input.pitch_velocity > 10.0f
                                 || input.pitch_velocity < -10.0f };
    if (input.mario_is_on_platform) {
        int16_t angle_delta = (int16_t) ((int32_t) input.angle_to_mario
                                         - (int32_t) input.move_angle_yaw);
        float rotation = input.distance_to_mario
            * gSineTable[((uint16_t) (angle_delta + 0x4000)) >> 4];
        if (output.pitch_velocity * rotation < 0.0f) rotation *= 0.04f;
        else rotation *= 0.02f;
        output.pitch_velocity += rotation;
        if (output.pitch_velocity > 50.0f) output.pitch_velocity = 50.0f;
        if (output.pitch_velocity < -50.0f) output.pitch_velocity = -50.0f;
    } else {
        oscillate_toward(&output.face_pitch, &output.pitch_velocity, 0,
                         6.0f, 3.0f, 3.0f);
    }
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.face_pitch);
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.pitch_velocity));
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.plays_rocking_sound);
}

int main(void) {
    struct Init default_init = initialize(1);
    struct Init bits_init = initialize(2);
    struct Output accelerating = update((struct Input) {
        0, 0.0f, 100.0f, 0, 0, 1,
    });
    struct Output decelerating = update((struct Input) {
        0, 20.0f, 100.0f, (int16_t) 0x8000, 0, 1,
    });
    struct Output clamped = update((struct Input) {
        0, 49.0f, 1000.0f, 0, 0, 1,
    });
    struct Output returning = update((struct Input) {
        20, -4.0f, 0.0f, 0, 0, 0,
    });

    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, accelerating);
    append_output(&fingerprint, decelerating);
    append_output(&fingerprint, clamped);
    append_output(&fingerprint, returning);
    printf("seesawPlatformFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern seesaw platform C contract matched\n");
    return default_init.collision_model_index == 1
        && !default_init.has_distance_override
        && bits_init.collision_model_index == 2
        && bits_init.has_distance_override
        && bits_init.collision_distance_override == 2000.0f
        && accelerating.pitch_velocity == 2.0f
        && decelerating.pitch_velocity == 16.0f
        && clamped.pitch_velocity == 50.0f
        && returning.face_pitch == 16
        && returning.pitch_velocity == -7.0f ? 0 : 1;
}
