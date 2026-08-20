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

struct Init { uint8_t collision; int32_t velocity; };
struct Input { int32_t face_yaw, velocity; };
struct Output { int32_t face_yaw, velocity; };

static struct Init initialize(uint8_t collision, uint8_t speed) {
    static const int32_t speeds[] = {300, -300, 600, -600};
    return (struct Init){collision, speeds[speed]};
}

static struct Output update(struct Input input) {
    return (struct Output){input.face_yaw + input.velocity, input.velocity};
}

static uint64_t append_init(uint64_t hash, struct Init value) {
    hash = hash_u32(hash, value.collision);
    return hash_u32(hash, (uint32_t)value.velocity);
}

static uint64_t append_output(uint64_t hash, struct Output value) {
    hash = hash_u32(hash, (uint32_t)value.face_yaw);
    return hash_u32(hash, (uint32_t)value.velocity);
}

int main(void) {
    struct Init slow = initialize(0, 0);
    struct Init reverse_fast = initialize(1, 3);
    struct Output clockwise = update((struct Input){0x1000, 300});
    struct Output counter = update((struct Input){0x1000, -600});
    if (slow.velocity != 300 || reverse_fast.velocity != -600 ||
        clockwise.face_yaw != 0x112c || counter.face_yaw != 0x0da8) return 2;
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = append_init(fingerprint, slow);
    fingerprint = append_init(fingerprint, reverse_fast);
    fingerprint = append_output(fingerprint, clockwise);
    fingerprint = append_output(fingerprint, counter);
    printf("rotatingOctagonalPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern rotating octagonal platform C contract passed");
    return 0;
}
