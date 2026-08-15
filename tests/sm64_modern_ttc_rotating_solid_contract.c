#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Input {
    int32_t speed_setting, timer, rotation_delay, sound_timer;
    float vertical_velocity, position_y, home_y;
    int32_t number_of_turns, number_of_sides;
    int16_t face_roll;
    int32_t random_rotation_delay;
};
struct Output {
    int32_t timer, rotation_delay, sound_timer;
    float vertical_velocity, position_y;
    int32_t number_of_turns;
    int16_t face_roll, angle_velocity_roll;
    int played_alert_sound, played_click_sound;
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

static int16_t approach_s16(int16_t value, int16_t target, int16_t increment) {
    int32_t distance = (int32_t) target - value;
    if (distance >= 0) return distance > increment ? value + increment : target;
    return distance < -increment ? value - increment : target;
}

static struct Output update(struct Input input) {
    struct Output output = {
        input.timer, input.rotation_delay, input.sound_timer,
        input.vertical_velocity, input.position_y, input.number_of_turns,
        input.face_roll, 0, 0, 0,
    };
    if (input.speed_setting != 3 && input.timer > input.rotation_delay) {
        if (output.sound_timer != 0) {
            --output.sound_timer;
            if (output.sound_timer == 0) output.played_alert_sound = 1;
        } else if (output.vertical_velocity > 0.0f && output.position_y >= input.home_y) {
            int16_t target_roll = (int16_t) ((float) output.number_of_turns
                                             / input.number_of_sides * 0x10000);
            int16_t start_roll = output.face_roll;
            output.face_roll = approach_s16(output.face_roll, target_roll, 0x4B0);
            output.angle_velocity_roll = output.face_roll - start_roll;
            if (output.angle_velocity_roll == 0) {
                output.played_click_sound = 1;
                output.number_of_turns = (output.number_of_turns + 1) % input.number_of_sides;
                output.timer = 0;
                if (input.speed_setting == 2) output.rotation_delay = input.random_rotation_delay;
            }
        } else {
            output.vertical_velocity += 0.5f;
            output.position_y += output.vertical_velocity;
            if (output.position_y >= input.home_y) {
                output.position_y = input.home_y;
                output.sound_timer = 6;
            }
        }
    } else {
        output.vertical_velocity = -5.0f;
    }
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.timer);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.rotation_delay);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.sound_timer);
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.vertical_velocity));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.position_y));
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.number_of_turns);
    *fingerprint = hash_u32(*fingerprint, (uint16_t) output.face_roll);
    *fingerprint = hash_u32(*fingerprint, (uint16_t) output.angle_velocity_roll);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.played_alert_sound);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.played_click_sound);
}

int main(void) {
    struct Output waiting = update((struct Input) { 1, 40, 40, 0, 0, 100, 100, 0, 4, 0, 7 });
    struct Output dipping = update((struct Input) { 1, 41, 40, 0, -5, 100, 100, 0, 4, 0, 7 });
    struct Output landing = update((struct Input) { 1, 41, 40, 0, 0.5f, 99.8f, 100, 0, 4, 0, 7 });
    struct Output alert = update((struct Input) { 1, 41, 40, 1, 1, 100, 100, 0, 4, 0, 7 });
    struct Output rotate = update((struct Input) { 1, 41, 40, 0, 1, 100, 100, 1, 4, 0, 7 });
    struct Output click = update((struct Input) { 2, 41, 40, 0, 1, 100, 100, 0, 4, 0, 9 });
    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, waiting);
    append_output(&fingerprint, dipping);
    append_output(&fingerprint, landing);
    append_output(&fingerprint, alert);
    append_output(&fingerprint, rotate);
    append_output(&fingerprint, click);
    printf("ttcRotatingSolidFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern TTC rotating-solid C contract matched\n");
    return waiting.vertical_velocity == -5.0f
        && dipping.vertical_velocity == -4.5f && dipping.position_y == 95.5f
        && landing.position_y == 100.0f && landing.sound_timer == 6
        && alert.played_alert_sound && alert.sound_timer == 0
        && rotate.face_roll == 1200 && rotate.angle_velocity_roll == 1200
        && !rotate.played_click_sound
        && click.played_click_sound && click.number_of_turns == 1 && click.timer == 0
        && click.rotation_delay == 9 ? 0 : 1;
}
