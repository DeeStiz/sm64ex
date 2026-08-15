#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Input {
    int32_t speed_setting, timer, change_direction_timer, direction;
    int16_t face_pitch;
    int32_t random_direction, random_change_direction_timer;
};
struct Output {
    int16_t angle_velocity_pitch;
    int32_t direction, change_direction_timer, timer;
    int16_t face_pitch;
};

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static struct Output update(struct Input input) {
    static const int16_t speeds[] = { 200, 600, 200, 0 };
    struct Output output = {
        speeds[input.speed_setting], input.direction, input.change_direction_timer,
        input.timer, input.face_pitch,
    };
    if (input.speed_setting == 2) {
        if (input.timer > input.change_direction_timer) {
            output.direction = input.random_direction;
            output.change_direction_timer = input.random_change_direction_timer;
            output.timer = 0;
        } else if (input.timer > 5) {
            output.angle_velocity_pitch *= output.direction;
        } else {
            output.angle_velocity_pitch = 0;
        }
    }
    output.face_pitch = (int16_t) ((uint16_t) output.face_pitch
                                   + (uint16_t) output.angle_velocity_pitch);
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, (uint16_t) output.angle_velocity_pitch);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.direction);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.change_direction_timer);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.timer);
    *fingerprint = hash_u32(*fingerprint, (uint16_t) output.face_pitch);
}

int main(void) {
    struct Output slow = update((struct Input) { 0, 0, 0, 1, 0x1000, -1, 20 });
    struct Output fast = update((struct Input) { 1, 0, 0, -1, 0x1000, 1, 20 });
    struct Output stopped = update((struct Input) { 3, 0, 0, 1, 0x1000, -1, 20 });
    struct Output random_pause = update((struct Input) { 2, 5, 20, -1, 0x1000, 1, 10 });
    struct Output random_move = update((struct Input) { 2, 6, 20, -1, 0x1000, 1, 10 });
    struct Output random_change = update((struct Input) { 2, 21, 20, -1, 0x7FFF, -1, 30 });
    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, slow);
    append_output(&fingerprint, fast);
    append_output(&fingerprint, stopped);
    append_output(&fingerprint, random_pause);
    append_output(&fingerprint, random_move);
    append_output(&fingerprint, random_change);
    printf("ttcSpinnerFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern TTC spinner C contract matched\n");
    return slow.angle_velocity_pitch == 200 && slow.face_pitch == 0x10C8
        && fast.angle_velocity_pitch == 600 && fast.face_pitch == 0x1258
        && stopped.angle_velocity_pitch == 0 && stopped.face_pitch == 0x1000
        && random_pause.angle_velocity_pitch == 0 && random_pause.face_pitch == 0x1000
        && random_move.angle_velocity_pitch == -200 && random_move.face_pitch == 0x0F38
        && random_change.angle_velocity_pitch == 200 && random_change.direction == -1
        && random_change.change_direction_timer == 30 && random_change.timer == 0
        && random_change.face_pitch == (int16_t) (0x7FFF + 200) ? 0 : 1;
}
