#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct input {
    int mario_on_platform;
    float object_x, object_z, mario_x, mario_z;
    int32_t move_yaw;
    float floor_height, water_level, platform_offset, float_y, velocity_y;
    int32_t oscillation_timer, face_pitch, face_roll;
};
struct output {
    int32_t action;
    int using_floor;
    float home_y, position_y, float_y, velocity_y;
    int32_t face_pitch, face_roll, oscillation_timer;
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}
static uint64_t hash_f32(uint64_t hash, float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return hash_u64(hash, bits);
}

static struct output update(struct input input) {
    const int using_floor = input.water_level <= input.floor_height + input.platform_offset;
    const float home_y = using_floor ? input.floor_height + input.platform_offset
                                     : input.water_level + input.platform_offset;
    struct output output = {
        using_floor ? 1 : 0, using_floor, home_y, home_y,
        input.float_y, input.velocity_y, input.face_pitch, input.face_roll,
        input.oscillation_timer,
    };
    if (!using_floor) {
        const int16_t yaw = (int16_t)(-input.move_yaw);
        const float c = (float)cos((double)yaw * 3.14159265358979323846 / 32768.0);
        const float s = (float)sin((double)yaw * 3.14159265358979323846 / 32768.0);
        const float local_roll = (input.mario_x - input.object_x) * c
                               + (input.mario_z - input.object_z) * s;
        const float local_pitch = (input.mario_z - input.object_z) * c
                                - (input.mario_x - input.object_x) * s;
        const int32_t sp6 = (int16_t)(int32_t)local_roll;
        const int32_t sp4 = (int16_t)(int32_t)local_pitch;
        if (input.mario_on_platform) {
            output.face_pitch = sp4 * 2;
            output.face_roll = -sp6 * 2;
            output.velocity_y -= 1.0f;
            if (output.velocity_y < 0) output.velocity_y = 0;
            output.float_y += output.velocity_y;
            if (output.float_y > 90) output.float_y = 90;
        } else {
            output.face_pitch /= 2;
            output.face_roll /= 2;
            output.float_y -= 5;
            if (output.float_y < 0) output.float_y = 0;
            output.velocity_y = 10;
        }
        const float sine = (float)sin((double)(int16_t)(input.oscillation_timer * 0x800)
                                      * 3.14159265358979323846 / 32768.0);
        output.position_y = home_y - input.platform_offset - output.float_y + sine * 10;
        output.oscillation_timer = input.oscillation_timer == 31
            ? 0 : input.oscillation_timer + 1;
    }
    return output;
}

int main(void) {
    const struct input cases[] = {
        {0, 0, 0, 100, 100, 0, 0, 200, 64, 0, 0, 0, 0, 0},
        {1, 0, 0, 10, 20, 0, 0, 200, 64, 10, 5, 0, 4, -6},
        {1, 0, 0, 0, 0, 0, 100, 0, 64, 40, 8, 12, 10, -10},
    };
    const struct output outputs[] = { update(cases[0]), update(cases[1]), update(cases[2]) };
    if (outputs[0].action != 0 || outputs[0].using_floor || outputs[0].home_y != 264 ||
        outputs[0].position_y != 200 || outputs[0].velocity_y != 10 ||
        outputs[0].oscillation_timer != 1 || outputs[1].face_pitch != 40 ||
        outputs[1].face_roll != -20 || outputs[1].velocity_y != 4 ||
        outputs[1].float_y != 14 || outputs[1].position_y != 186 ||
        outputs[1].oscillation_timer != 1 ||
        outputs[2].action != 1 || !outputs[2].using_floor || outputs[2].home_y != 164 ||
        outputs[2].position_y != 164) return 1;
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned i = 0; i < 3; ++i) {
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)outputs[i].action);
        fingerprint = hash_u64(fingerprint, (uint64_t)outputs[i].using_floor);
        fingerprint = hash_f32(fingerprint, outputs[i].home_y);
        fingerprint = hash_f32(fingerprint, outputs[i].position_y);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)outputs[i].face_pitch);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)outputs[i].face_roll);
        fingerprint = hash_f32(fingerprint, outputs[i].float_y);
        fingerprint = hash_f32(fingerprint, outputs[i].velocity_y);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)outputs[i].oscillation_timer);
    }
    printf("floatingPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern floating platform C contract passed");
    return 0;
}
