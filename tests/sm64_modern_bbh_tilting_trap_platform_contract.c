#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & 0xffu;
        hash *= FNV_PRIME;
    }
    return hash;
}

struct Input {
    int32_t timer, previous_action, face_pitch, angle_velocity_pitch;
    float distance;
    int32_t angle;
    int32_t mario_on;
};
struct Output { int32_t action, face_pitch, angle_velocity_pitch; };

static struct Output update(struct Input input) {
    struct Output result = {
        input.mario_on ? 0 : 1,
        input.face_pitch,
        input.angle_velocity_pitch
    };
    if (input.mario_on) {
        result.angle_velocity_pitch = (int32_t)(input.distance * 1.0f);
        result.face_pitch += result.angle_velocity_pitch;
    } else {
        if ((input.face_pitch < 3000 && input.face_pitch > -3000) || input.timer >= 16) {
            result.angle_velocity_pitch = 0;
            if (result.face_pitch > 0) {
                if (result.face_pitch < 200) result.face_pitch = 0;
                else result.angle_velocity_pitch = -200;
            } else if (result.face_pitch > -200) {
                result.face_pitch = 0;
            } else {
                result.angle_velocity_pitch = 200;
            }
        }
        result.face_pitch += result.angle_velocity_pitch;
    }
    return result;
}

static uint64_t append(uint64_t hash, struct Output value) {
    hash = hash_u32(hash, (uint32_t)value.action);
    hash = hash_u32(hash, (uint32_t)value.face_pitch);
    return hash_u32(hash, (uint32_t)value.angle_velocity_pitch);
}

int main(void) {
    struct Output mario_on = update((struct Input){0, 0, 100, 0, 500, 0, 1});
    struct Output returning = update((struct Input){0, 0, 150, -200, 0, 0, 0});
    struct Output grace = update((struct Input){0, 0, 5000, -200, 0, 0, 0});
    struct Output released = update((struct Input){16, 0, 5000, -200, 0, 0, 0});
    struct Output negative = update((struct Input){0, 0, -5000, 200, 0, 0, 0});
    if (mario_on.action != 0 || mario_on.face_pitch != 600 ||
        mario_on.angle_velocity_pitch != 500 || returning.face_pitch != 0 ||
        grace.face_pitch != 4800 || released.face_pitch != 4800 ||
        negative.face_pitch != -4800) return 2;
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = append(fingerprint, mario_on);
    fingerprint = append(fingerprint, returning);
    fingerprint = append(fingerprint, grace);
    fingerprint = append(fingerprint, released);
    fingerprint = append(fingerprint, negative);
    printf("bbhTiltingTrapPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern BBH tilting trap platform C contract passed");
    return 0;
}
