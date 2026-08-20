#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct output {
    int32_t animation_state;
    float x, y, z;
    int deactivate;
    int clear_mario_flag;
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

static struct output update(int32_t animation_state, uint64_t global_timer) {
    struct output output = {
        animation_state + 1,
        0, 0, 0,
        global_timer % 16 == 0,
        0,
    };
    return output;
}
static struct output update_idle(int32_t animation_state, float x, float z,
                                 float water_level, uint32_t particle_flags) {
    struct output output = {
        animation_state + 1, x, water_level + 5, z,
        (particle_flags & UINT32_C(0x80)) == 0,
        (particle_flags & UINT32_C(0x80)) == 0,
    };
    return output;
}

int main(void) {
    const struct output cases[] = {
        update(0, 1), update(15, 16), update(31, 32), update(-1, 7),
    };
    const struct output idle_cases[] = {
        update_idle(0, 10, 30, 100, UINT32_C(0x80)),
        update_idle(1, -5, 7, -10, 0),
    };
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)cases[i].animation_state);
        fingerprint = hash_f32(fingerprint, cases[i].x);
        fingerprint = hash_f32(fingerprint, cases[i].y);
        fingerprint = hash_f32(fingerprint, cases[i].z);
        fingerprint = hash_u64(fingerprint, (uint64_t)cases[i].deactivate);
        fingerprint = hash_u64(fingerprint, (uint64_t)cases[i].clear_mario_flag);
    }
    for (unsigned i = 0; i < sizeof(idle_cases) / sizeof(idle_cases[0]); ++i) {
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)idle_cases[i].animation_state);
        fingerprint = hash_f32(fingerprint, idle_cases[i].x);
        fingerprint = hash_f32(fingerprint, idle_cases[i].y);
        fingerprint = hash_f32(fingerprint, idle_cases[i].z);
        fingerprint = hash_u64(fingerprint, (uint64_t)idle_cases[i].deactivate);
        fingerprint = hash_u64(fingerprint, (uint64_t)idle_cases[i].clear_mario_flag);
    }
    if (cases[0].animation_state != 1 || cases[1].animation_state != 16 ||
        cases[2].animation_state != 32 || cases[3].animation_state != 0 ||
        !cases[1].deactivate || !cases[2].deactivate || cases[0].deactivate ||
        cases[3].deactivate || idle_cases[0].animation_state != 1 ||
        idle_cases[0].x != 10 || idle_cases[0].y != 105 || idle_cases[0].z != 30 ||
        idle_cases[0].deactivate || idle_cases[0].clear_mario_flag ||
        idle_cases[1].animation_state != 2 || idle_cases[1].x != -5 ||
        idle_cases[1].y != -5 || idle_cases[1].z != 7 ||
        !idle_cases[1].deactivate || !idle_cases[1].clear_mario_flag) {
        return 1;
    }
    printf("idleWaterWaveFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern idle water wave C contract passed");
    return 0;
}
