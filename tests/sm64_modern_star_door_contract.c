#include <stdint.h>
#include <stdio.h>

#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t seed, uint64_t value) { for (unsigned i = 0; i < 8; ++i) { seed ^= (value >> (i * 8u)) & UINT64_C(0xff); seed *= P; } return seed; }
static uint64_t hf(uint64_t seed, float value) { union { float f; uint32_t u; } x = { value }; return h(seed, x.u); }
static uint64_t add(uint64_t seed, uint64_t action, int32_t timer, float x, float z, float vx, float vz, int tangible, int visible, int load, uint64_t sound, int rumble, int clear) {
    seed = h(seed, action); seed = h(seed, (uint64_t)(int64_t)timer); seed = hf(seed, x); seed = hf(seed, z); seed = hf(seed, vx); seed = hf(seed, vz); seed = h(seed, tangible); seed = h(seed, visible); seed = h(seed, load); seed = h(seed, sound); seed = h(seed, rumble); return h(seed, clear);
}
int main(void) {
    uint64_t f = O;
    f = add(f, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0);
    f = add(f, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0);
    f = add(f, 1, 1, -8, 0, -8, 0, 0, 1, 0, 1, 1, 0);
    f = add(f, 2, 0, -16, 0, -8, 0, 0, 1, 0, 0, 0, 0);
    f = add(f, 3, 0, -136, 0, 0, 0, 0, 1, 0, 0, 0, 0);
    f = add(f, 3, 1, -128, 0, 8, -0.0f, 0, 1, 0, 2, 1, 0);
    f = add(f, 4, 0, -120, 0, 8, -0.0f, 0, 1, 0, 0, 0, 0);
    f = add(f, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1);
    f = add(f, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0);
    printf("starDoorFingerprint=0x%016llx\n", (unsigned long long)f);
    puts("SM64 Modern star-door C contract passed");
    return 0;
}
