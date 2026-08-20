#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct output {
    float y, scale_x, scale_z;
    int32_t angle_x, angle_z, timer;
    int deactivate, delete, splash;
};
static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) { hash ^= (value >> (byte * 8u)) & UINT64_C(0xff); hash *= FNV_PRIME; }
    return hash;
}
static uint64_t hash_f32(uint64_t hash, float value) { uint32_t bits = 0; memcpy(&bits, &value, sizeof(bits)); return hash_u64(hash, bits); }
static struct output update(float y, float water, int32_t ax, int32_t az, int32_t avx, int32_t avz, int32_t timer, int interacted) {
    struct output output = { y + 7, 1, 1, ax, az, timer + 1, 0, interacted, 0 };
    output.scale_x = (float)sin((double)(int16_t)ax * 3.14159265358979323846 / 32768.0) * 0.2f + 1.0f;
    output.scale_z = (float)sin((double)(int16_t)az * 3.14159265358979323846 / 32768.0) * 0.2f + 1.0f;
    output.angle_x += avx; output.angle_z += avz;
    if (output.y > water) { output.y += 5; output.deactivate = 1; output.splash = 1; }
    if (timer >= 59) output.deactivate = 1;
    return output;
}
int main(void) {
    const struct output outputs[] = {
        update(0, 100, 0, 0, 0x400, 0x400, 0, 0),
        update(100, 50, 0, 0, 0x400, 0x400, 1, 0),
        update(0, 100, 0x4000, 0, 0x400, 0x400, 59, 1),
    };
    if (outputs[0].y != 7 || outputs[0].scale_x != 1 || outputs[0].scale_z != 1 ||
        outputs[0].timer != 1 || outputs[0].deactivate || outputs[1].y != 112 ||
        !outputs[1].deactivate || !outputs[1].splash || outputs[2].scale_x != 1.2f ||
        outputs[2].scale_z != 1 || !outputs[2].deactivate || !outputs[2].delete ||
        outputs[2].splash) return 1;
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned i = 0; i < 3; ++i) {
        fingerprint = hash_f32(fingerprint, outputs[i].y);
        fingerprint = hash_f32(fingerprint, outputs[i].scale_x);
        fingerprint = hash_f32(fingerprint, outputs[i].scale_z);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)outputs[i].angle_x);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)outputs[i].angle_z);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)outputs[i].timer);
        fingerprint = hash_u64(fingerprint, (uint64_t)outputs[i].deactivate);
        fingerprint = hash_u64(fingerprint, (uint64_t)outputs[i].delete);
        fingerprint = hash_u64(fingerprint, (uint64_t)outputs[i].splash);
    }
    printf("smallWaterWaveFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern small water wave C contract passed");
    return 0;
}
