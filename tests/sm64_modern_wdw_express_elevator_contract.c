#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) { hash ^= (value >> (byte * 8)) & 0xffu; hash *= FNV_PRIME; }
    return hash;
}
static uint64_t hash_f32(uint64_t hash, float value) { union { float f; uint32_t u; } bits = { value }; return hash_u32(hash, bits.u); }

struct Input { int32_t kind, action, timer, mario; float position, home; };
struct Output { int32_t action, sound; float position, velocity; };

static struct Output update(struct Input input) {
    struct Output result = {input.action, 0, input.position, 0};
    if (input.kind != 0) return result;
    if (input.action == 0) { if (input.mario) result.action = 1; }
    else if (input.action == 1) { result.velocity = -20; result.position -= 20; result.sound = 1; if (input.timer > 132) result.action = 2; }
    else if (input.action == 2) { if (input.timer > 110) result.action = 3; }
    else if (input.action == 3) { result.velocity = 10; result.position += 10; result.sound = 1; if (result.position >= input.home) { result.position = input.home; result.action++; } }
    else if (!input.mario) result.action = 0;
    return result;
}

static uint64_t append(uint64_t hash, struct Output value) {
    hash = hash_u32(hash, (uint32_t)value.action); hash = hash_f32(hash, value.position);
    hash = hash_f32(hash, value.velocity); return hash_u32(hash, (uint32_t)value.sound);
}

int main(void) {
    struct Output idle = update((struct Input){0,0,0,0,100,500});
    struct Output start = update((struct Input){0,0,0,1,100,500});
    struct Output down = update((struct Input){0,1,132,1,100,500});
    struct Output down_end = update((struct Input){0,1,133,1,100,500});
    struct Output wait_end = update((struct Input){0,2,111,1,100,500});
    struct Output up_end = update((struct Input){0,3,0,1,490,500});
    struct Output reset = update((struct Input){0,4,0,0,500,500});
    struct Output static_platform = update((struct Input){1,2,9,1,100,500});
    if (idle.action != 0 || start.action != 1 || down.position != 80 || down_end.action != 2 ||
        wait_end.action != 3 || up_end.action != 4 || up_end.position != 500 || reset.action != 0 || static_platform.action != 2) return 2;
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = append(fingerprint,idle); fingerprint = append(fingerprint,start); fingerprint = append(fingerprint,down);
    fingerprint = append(fingerprint,down_end); fingerprint = append(fingerprint,wait_end); fingerprint = append(fingerprint,up_end);
    fingerprint = append(fingerprint,reset); fingerprint = append(fingerprint,static_platform);
    printf("wdwExpressElevatorFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern WDW express elevator C contract passed");
    return 0;
}
