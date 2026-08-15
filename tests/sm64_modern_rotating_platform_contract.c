#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Input { int32_t action, timer; int8_t speed_byte; int16_t face_yaw; };
struct Output { int32_t action; int16_t angle_velocity_yaw, face_yaw; int plays_loop_sound; };

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static struct Output update(struct Input input) {
    struct Output output = { input.action, 0, input.face_yaw, 0 };
    if (input.action == 0) {
        if (input.timer > 60) output.action++;
    } else {
        output.angle_velocity_yaw = (int16_t)((int32_t) input.speed_byte << 4);
        if (input.timer > 126) output.action = 0;
        output.plays_loop_sound = 1;
    }
    output.face_yaw = (int16_t)((uint16_t) output.face_yaw + (uint16_t) output.angle_velocity_yaw);
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.action);
    *fingerprint = hash_u32(*fingerprint, (uint16_t) output.angle_velocity_yaw);
    *fingerprint = hash_u32(*fingerprint, (uint16_t) output.face_yaw);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.plays_loop_sound);
}

int main(void) {
    struct Output waiting = update((struct Input) { 0, 60, 0x08, 0x1000 });
    struct Output starts = update((struct Input) { 0, 61, 0x08, 0x1000 });
    struct Output spinning = update((struct Input) { 1, 10, -8, 0x1000 });
    struct Output stops = update((struct Input) { 1, 127, 0x08, 0x1000 });
    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, waiting);
    append_output(&fingerprint, starts);
    append_output(&fingerprint, spinning);
    append_output(&fingerprint, stops);
    printf("rotatingPlatformFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return waiting.action == 0 && waiting.angle_velocity_yaw == 0
        && starts.action == 1 && starts.angle_velocity_yaw == 0
        && spinning.angle_velocity_yaw == -0x80 && spinning.face_yaw == 0x0F80
        && spinning.plays_loop_sound && stops.action == 0 ? 0 : 1;
}
