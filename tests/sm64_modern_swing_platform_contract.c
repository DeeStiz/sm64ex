#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Input {
    float angle;
    float speed;
    int32_t face_roll;
};

struct Output {
    float angle;
    float speed;
    int32_t face_roll;
    int32_t angle_velocity_roll;
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
    __builtin_memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static struct Output update(struct Input input) {
    float speed = input.speed;
    if (input.face_roll < 0) {
        speed += 4.0f;
    } else {
        speed -= 4.0f;
    }
    float angle = input.angle + speed;
    int32_t face_roll = (int32_t) angle;
    return (struct Output) {
        angle,
        speed,
        face_roll,
        face_roll - input.face_roll,
    };
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.angle));
    *fingerprint = hash_u32(*fingerprint, bits_f32(output.speed));
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.face_roll);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.angle_velocity_roll);
}

int main(void) {
    struct Output clockwise = update((struct Input) { 8192.0f, 0.0f, 0 });
    struct Output counter_clockwise = update((struct Input) { -2.0f, 0.0f, -2 });
    struct Output fractional = update((struct Input) { 12.75f, 1.5f, 12 });
    struct Output negative_fractional = update((struct Input) { -12.75f, -1.5f, -12 });

    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, clockwise);
    append_output(&fingerprint, counter_clockwise);
    append_output(&fingerprint, fractional);
    append_output(&fingerprint, negative_fractional);
    printf("swingPlatformFingerprint=0x%016llx\n", (unsigned long long) fingerprint);

    return clockwise.speed == -4.0f && clockwise.face_roll == 8188
        && clockwise.angle_velocity_roll == 8188
        && counter_clockwise.speed == 4.0f && counter_clockwise.face_roll == 2
        && fractional.face_roll == 10 && fractional.angle_velocity_roll == -2
        && negative_fractional.face_roll == -10
        && negative_fractional.angle_velocity_roll == 2 ? 0 : 1;
}
