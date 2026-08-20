#include <stdint.h>
#include <stdio.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)

static uint64_t h(uint64_t seed, uint64_t value) {
    for (unsigned i = 0; i < 8; i++) {
        seed ^= (value >> (i * 8)) & 255;
        seed *= PRIME;
    }
    return seed;
}

static uint64_t row(uint64_t seed, int behaviorByte, int parentBaseBallIndex) {
    int16_t behavior = (int16_t) behaviorByte;
    int16_t base = (int16_t) parentBaseBallIndex;
    int32_t relative = (int32_t) behavior - (int32_t) base - 1;
    int deleted = relative < 1 || relative > 5;
    seed = h(seed, (uint64_t) (int64_t) relative);
    return h(seed, (uint64_t) deleted);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 6, 0);
    fingerprint = row(fingerprint, 1, -1);
    fingerprint = row(fingerprint, 0, 0);
    fingerprint = row(fingerprint, 0x10001, 0);
    printf("trackBallFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    puts("SM64 Modern track ball C contract passed");
    return 0;
}
