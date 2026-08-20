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

struct Input { int32_t action, timer, face_yaw; };
struct Output { int32_t action, face_yaw, angle_velocity_yaw, sound; };

static struct Output update(struct Input input) {
    struct Output result = { input.action, input.face_yaw, 0, 0 };
    if (input.action == 0) {
        if (input.timer > 60) result.action = 1;
    } else {
        result.angle_velocity_yaw = 0x100;
        if (input.timer > 126) result.action = 0;
        result.sound = 1;
    }
    result.face_yaw += result.angle_velocity_yaw;
    return result;
}

static uint64_t append(uint64_t hash, struct Output value) {
    hash = hash_u32(hash, (uint32_t)value.action);
    hash = hash_u32(hash, (uint32_t)value.face_yaw);
    hash = hash_u32(hash, (uint32_t)value.angle_velocity_yaw);
    return hash_u32(hash, (uint32_t)value.sound);
}

int main(void) {
    struct Output waiting = update((struct Input){0, 60, 100});
    struct Output start = update((struct Input){0, 61, 100});
    struct Output spinning = update((struct Input){1, 10, 100});
    struct Output stop = update((struct Input){1, 127, 356});
    if (waiting.action != 0 || start.action != 1 || spinning.face_yaw != 356 ||
        spinning.sound != 1 || stop.action != 0 || stop.face_yaw != 612) return 2;
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = append(fingerprint, waiting);
    fingerprint = append(fingerprint, start);
    fingerprint = append(fingerprint, spinning);
    fingerprint = append(fingerprint, stop);
    printf("wfRotatingWoodenPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern WF rotating wooden platform C contract passed");
    return 0;
}
