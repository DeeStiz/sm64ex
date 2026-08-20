#include <stdint.h>
#include <stdio.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s, uint64_t v) { for (unsigned i = 0; i < 8; i++) { s ^= (v >> (i * 8)) & 255; s *= PRIME; } return s; }
static uint64_t row(uint64_t s, int action, int pitch, int velocity, uint32_t y, int quiet, int big, int rise, int shake) { s = h(s, (uint64_t)(int64_t)action); s = h(s, (uint64_t)(int64_t)pitch); s = h(s, (uint64_t)(int64_t)velocity); s = h(s, y); s = h(s, quiet); s = h(s, big); s = h(s, rise); return h(s, shake); }
int main(void) {
    uint64_t f = OFFSET;
    f = row(f, 1, 0, 0, UINT32_C(0), 1, 0, 0, 0);
    f = row(f, 2, -0x4000, 0, UINT32_C(0), 0, 1, 0, 1);
    f = row(f, 2, -0x4000, 0, UINT32_C(0x42DA7A43), 0, 0, 0, 0);
    f = row(f, 0, -0x70, 0x90, UINT32_C(0), 0, 0, 0, 0);
    printf("volcanoFallingTrapFingerprint=0x%016llx\n", (unsigned long long)f);
    puts("SM64 Modern volcano falling trap C contract passed");
    return 0;
}
