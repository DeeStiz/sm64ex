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
    int32_t mode, pitch, yaw, roll, velocity_pitch, velocity_yaw, velocity_roll;
    int32_t debug_pitch, debug_yaw, debug_roll;
    int32_t debug_velocity_pitch, debug_velocity_yaw, debug_velocity_roll;
};
struct Output { int32_t pitch, yaw, roll, velocity_pitch, velocity_yaw, velocity_roll; };

static struct Output update(struct Input input) {
    struct Output result = {
        input.pitch, input.yaw, input.roll,
        input.velocity_pitch, input.velocity_yaw, input.velocity_roll
    };
    if (input.mode == 1) {
        result.pitch = 0; result.yaw = 0; result.roll = 0;
        result.velocity_pitch = 0; result.velocity_yaw = 0; result.velocity_roll = 0;
    }
    if (input.mode == 2) {
        result.pitch = input.debug_pitch * 0x1000;
        result.yaw = input.debug_yaw * 0x1000;
        result.roll = input.debug_roll * 0x1000;
    }
    result.velocity_pitch = input.debug_velocity_pitch;
    result.velocity_yaw = input.debug_velocity_yaw;
    result.velocity_roll = input.debug_velocity_roll;
    if (input.mode == 3) {
        result.pitch += result.velocity_pitch;
        result.yaw += result.velocity_yaw;
        result.roll += result.velocity_roll;
    }
    return result;
}

static uint64_t append(uint64_t hash, struct Output value) {
    hash = hash_u32(hash, (uint32_t)value.pitch);
    hash = hash_u32(hash, (uint32_t)value.yaw);
    hash = hash_u32(hash, (uint32_t)value.roll);
    hash = hash_u32(hash, (uint32_t)value.velocity_pitch);
    hash = hash_u32(hash, (uint32_t)value.velocity_yaw);
    return hash_u32(hash, (uint32_t)value.velocity_roll);
}

int main(void) {
    struct Output free = update((struct Input){0, 100, 200, 300, 1, 2, 3, 9, 8, 7, -4, -5, -6});
    struct Output reset = update((struct Input){1, 100, 200, 300, 1, 2, 3, 9, 8, 7, 7, -8, 9});
    struct Output set = update((struct Input){2, 100, 200, 300, 1, 2, 3, 1, -2, 3, 10, 20, 30});
    struct Output rotate = update((struct Input){3, 100, 200, 300, 1, 2, 3, 9, 8, 7, 7, -8, 9});
    if (free.pitch != 100 || free.velocity_pitch != -4 || reset.pitch != 0 ||
        reset.velocity_yaw != -8 || set.pitch != 4096 || set.yaw != -8192 ||
        rotate.pitch != 107 || rotate.yaw != 192 || rotate.roll != 309) return 2;
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = append(fingerprint, free);
    fingerprint = append(fingerprint, reset);
    fingerprint = append(fingerprint, set);
    fingerprint = append(fingerprint, rotate);
    printf("staticCheckeredPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern static checkered platform C contract passed");
    return 0;
}
