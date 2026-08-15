#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Input {
    int32_t speed_setting, timer, time_until_switch;
    float speed, target_speed;
    int is_master, no_master_exists;
    int32_t random_time_until_switch, random_direction;
};
struct Output {
    float speed, target_speed;
    int32_t time_until_switch, timer;
    float forward_velocity;
    int became_master, plays_elevator_sound;
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

static int approach(float *value, float target, float delta) {
    if (*value > target) delta = -delta;
    *value += delta;
    if ((*value - target) * delta >= 0) {
        *value = target;
        return 1;
    }
    return 0;
}

static struct Output update(struct Input input) {
    struct Output output = {
        input.speed, input.target_speed, input.time_until_switch, input.timer,
        0.0f, 0, 0,
    };
    if (input.is_master || input.no_master_exists) {
        output.became_master = !input.is_master && input.no_master_exists;
        output.plays_elevator_sound = 1;
        if (input.speed_setting == 2) {
            if (input.timer > input.time_until_switch) {
                if (approach(&output.speed, 0.0f, 10.0f)) {
                    output.time_until_switch = input.random_time_until_switch;
                    output.target_speed = input.random_direction * 50.0f;
                    output.timer = 0;
                }
            } else if (input.timer > 5) {
                approach(&output.speed, output.target_speed, 10.0f);
            }
        }
    }
    output.forward_velocity = 0.084f * output.speed;
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.speed));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.target_speed));
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.time_until_switch);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.timer);
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.forward_velocity));
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.became_master);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.plays_elevator_sound);
}

int main(void) {
    struct Output non_master = update((struct Input) { 0, 10, 0, 50, 0, 0, 0, 20, -1 });
    struct Output random_pause = update((struct Input) { 2, 5, 10, 0, 50, 1, 0, 20, -1 });
    struct Output random_approach = update((struct Input) { 2, 6, 10, 0, 50, 1, 0, 20, -1 });
    struct Output random_switch = update((struct Input) { 2, 11, 10, 8, 50, 1, 0, 20, -1 });
    struct Output elected = update((struct Input) { 0, 0, 0, 50, 0, 0, 1, 20, 1 });
    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, non_master);
    append_output(&fingerprint, random_pause);
    append_output(&fingerprint, random_approach);
    append_output(&fingerprint, random_switch);
    append_output(&fingerprint, elected);
    printf("ttcTreadmillFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern TTC treadmill C contract matched\n");
    return non_master.speed == 50.0f && non_master.forward_velocity == 4.2f
        && !non_master.plays_elevator_sound
        && random_pause.speed == 0.0f && random_pause.forward_velocity == 0.0f
        && random_pause.plays_elevator_sound
        && random_approach.speed == 10.0f && random_approach.forward_velocity == 0.84f
        && random_switch.speed == 0.0f && random_switch.target_speed == -50.0f
        && random_switch.time_until_switch == 20 && random_switch.timer == 0
        && elected.became_master && elected.plays_elevator_sound ? 0 : 1;
}
