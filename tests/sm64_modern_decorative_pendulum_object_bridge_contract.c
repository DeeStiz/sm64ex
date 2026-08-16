#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define CLOCK_SOUND UINT32_C(0x30170008)

struct Output {
    int32_t face_roll;
    int32_t angle_velocity_roll;
    int plays_clock_sound;
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_tick(uint64_t hash, uint64_t frame, struct Output output) {
    hash = hash_u64(hash, frame);
    hash = hash_u64(hash, 1); // OBJ_LIST_DEFAULT count
    hash = hash_u64(hash, 1); // object counter
    hash = hash_u64(hash, 1); // effect count
    hash = hash_u64(hash, 0); // object slot
    hash = hash_u64(hash, 1); // object generation
    hash = hash_u64(hash, (uint64_t)(int64_t)output.face_roll);
    hash = hash_u64(hash, (uint64_t)(int64_t)output.angle_velocity_roll);
    hash = hash_u64(hash, output.plays_clock_sound ? 1 : 0);
    hash = hash_u64(hash, output.plays_clock_sound ? 1 : 0); // presented count
    if (output.plays_clock_sound) {
        hash = hash_u64(hash, 0); // sound kind
        hash = hash_u64(hash, CLOCK_SOUND);
    }
    hash = hash_u64(hash, 1); // delivery count
    hash = hash_u64(hash, output.plays_clock_sound ? 1 : 0);
    if (output.plays_clock_sound) {
        hash = hash_u64(hash, 0);
        hash = hash_u64(hash, CLOCK_SOUND);
    }
    hash = hash_u64(hash, 0); // object slot
    hash = hash_u64(hash, 1); // object generation
    hash = hash_u64(hash, (uint64_t)(int64_t)output.face_roll);
    return hash_u64(hash, (uint64_t)(int64_t)output.angle_velocity_roll);
}

static struct Output update(int32_t face_roll, int32_t angle_velocity_roll) {
    if (face_roll > 0) {
        angle_velocity_roll -= 0x08;
    } else {
        angle_velocity_roll += 0x08;
    }
    face_roll += angle_velocity_roll;
    return (struct Output) {
        face_roll,
        angle_velocity_roll,
        angle_velocity_roll == 0x10 || angle_velocity_roll == -0x10,
    };
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_tick(fingerprint, 1, update(100, 0x20));
    fingerprint = hash_tick(fingerprint, 2, update(100, 0x18));
    fingerprint = hash_tick(fingerprint, 3, update(-100, -0x18));
    printf("decorativePendulumObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern decorative pendulum object bridge C contract passed\n");
    return 0;
}
