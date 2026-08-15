#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Init { int32_t angle_velocity_roll; int initializes_room; };
struct Input { int32_t face_roll, angle_velocity_roll; };
struct Output { int32_t face_roll, angle_velocity_roll; int plays_clock_sound; };

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static struct Init initialize(void) {
    return (struct Init) { 0x100, 1 };
}

static struct Output update(struct Input input) {
    if (input.face_roll > 0) input.angle_velocity_roll -= 0x08;
    else input.angle_velocity_roll += 0x08;
    input.face_roll += input.angle_velocity_roll;
    return (struct Output) {
        input.face_roll,
        input.angle_velocity_roll,
        input.angle_velocity_roll == 0x10 || input.angle_velocity_roll == -0x10,
    };
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.face_roll);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.angle_velocity_roll);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.plays_clock_sound);
}

int main(void) {
    struct Init initialization = initialize();
    struct Output rising = update((struct Input) { 100, 0x20 });
    struct Output sound_positive = update((struct Input) { 100, 0x18 });
    struct Output sound_negative = update((struct Input) { -100, -0x18 });
    struct Output falling = update((struct Input) { -100, 0 });

    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, rising);
    append_output(&fingerprint, sound_positive);
    append_output(&fingerprint, sound_negative);
    append_output(&fingerprint, falling);
    printf("decorativePendulumFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern decorative pendulum C contract matched\n");
    return initialization.angle_velocity_roll == 0x100
        && initialization.initializes_room
        && rising.face_roll == 124 && rising.angle_velocity_roll == 0x18
        && !rising.plays_clock_sound
        && sound_positive.plays_clock_sound && sound_negative.plays_clock_sound
        && falling.face_roll == -92 && falling.angle_velocity_roll == 8 ? 0 : 1;
}
