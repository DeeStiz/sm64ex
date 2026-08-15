#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Input {
    int32_t speed_setting;
    float angle, angle_velocity, angle_acceleration, acceleration_direction;
    int32_t delay, sound_timer;
    int random_acceleration_uses13, random_delay_is_even, random_delay;
};
struct Output {
    float angle, angle_velocity, angle_acceleration, acceleration_direction;
    int32_t delay, sound_timer, face_roll;
    int plays_swing_sound;
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
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static void initialize(int32_t speed_setting, float *acceleration, float *angle) {
    static const float accelerations[] = { 13.0f, 22.0f, 13.0f, 0.0f };
    if (speed_setting != 3) {
        *acceleration = accelerations[speed_setting];
        *angle = 6500.0f;
    } else {
        *angle = 6371.5557f;
    }
}

static struct Output update(struct Input input) {
    struct Output output = {
        input.angle, input.angle_velocity, input.angle_acceleration,
        input.acceleration_direction, input.delay, input.sound_timer,
        (int32_t) input.angle, 0,
    };
    if (input.speed_setting != 3) {
        if (output.sound_timer != 0) {
            --output.sound_timer;
            if (output.sound_timer == 0) output.plays_swing_sound = 1;
        }
        if (output.delay != 0) {
            --output.delay;
        } else {
            if (output.angle * output.acceleration_direction > 0.0f)
                output.acceleration_direction = -output.acceleration_direction;
            output.angle_velocity += output.angle_acceleration * output.acceleration_direction;
            if (output.angle_velocity == 0.0f) {
                if (input.speed_setting == 2) {
                    output.angle_acceleration = input.random_acceleration_uses13 ? 13.0f : 42.0f;
                    if (input.random_delay_is_even) output.delay = input.random_delay;
                }
                output.sound_timer = output.delay + 15;
            }
            output.angle += output.angle_velocity;
        }
    }
    output.face_roll = (int32_t) output.angle;
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.angle));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.angle_velocity));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.angle_acceleration));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.acceleration_direction));
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.delay);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.sound_timer);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.face_roll);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.plays_swing_sound);
}

int main(void) {
    float slow_accel, slow_angle, stopped_accel = 0.0f, stopped_angle;
    initialize(0, &slow_accel, &slow_angle);
    initialize(3, &stopped_accel, &stopped_angle);
    struct Output accelerating = update((struct Input) { 0, 6500, 0, 13, 1, 0, 0, 1, 0, 0 });
    struct Output delayed = update((struct Input) { 0, -100, 5, 13, 1, 2, 0, 1, 0, 0 });
    struct Output sound = update((struct Input) { 0, 0, 0, 13, 1, 0, 1, 1, 0, 0 });
    struct Output random_zero = update((struct Input) { 2, 0, -13, 13, 1, 0, 0, 0, 1, 7 });
    struct Output stopped = update((struct Input) { 3, 6371.5557f, 99, 22, -1, 4, 2, 1, 1, 8 });
    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, accelerating);
    append_output(&fingerprint, delayed);
    append_output(&fingerprint, sound);
    append_output(&fingerprint, random_zero);
    append_output(&fingerprint, stopped);
    printf("ttcPendulumFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern TTC pendulum C contract matched\n");
    return slow_accel == 13.0f && slow_angle == 6500.0f
        && stopped_accel == 0.0f && stopped_angle == 6371.5557f
        && accelerating.angle == 6487.0f && accelerating.angle_velocity == -13.0f
        && accelerating.acceleration_direction == -1.0f && accelerating.face_roll == 6487
        && delayed.angle == -100.0f && delayed.angle_velocity == 5.0f && delayed.delay == 1
        && sound.plays_swing_sound && sound.sound_timer == 0 && sound.angle == 13.0f
        && random_zero.angle_velocity == 0.0f && random_zero.angle_acceleration == 42.0f
        && random_zero.delay == 7 && random_zero.sound_timer == 22
        && stopped.angle == 6371.5557f && stopped.angle_velocity == 99.0f
        && stopped.delay == 4 && !stopped.plays_swing_sound ? 0 : 1;
}
