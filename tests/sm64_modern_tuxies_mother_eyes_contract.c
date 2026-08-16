#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_output(uint64_t hash, int32_t selected_case,
                            int32_t blinking_case, uint32_t angry) {
    hash = hash_u32(hash, (uint32_t) selected_case);
    hash = hash_u32(hash, (uint32_t) blinking_case);
    return hash_u32(hash, angry);
}

static void update(uint64_t *fingerprint, uint64_t timer, uint64_t object,
                   uint64_t mother, float forward, int32_t previous,
                   uint8_t run) {
    int32_t selected = previous;
    int32_t blinking = previous;
    uint32_t angry = 0;
    if (run) {
        int32_t phase = (int32_t) (timer % 50);
        if (phase < 43) blinking = 0;
        else if (phase < 45) blinking = 1;
        else if (phase < 47) blinking = 2;
        else blinking = 1;
        selected = blinking;
        if (object == mother && forward > 5.0f) {
            selected = 3;
            angry = 1;
        }
    }
    *fingerprint = hash_output(*fingerprint, selected, blinking, angry);
}

int main(void) {
    const uint64_t mother = UINT64_C(0x6268765f74786d);
    const uint64_t other = UINT64_C(0x6268765f6f7468);
    uint64_t fingerprint = FNV_OFFSET;

    update(&fingerprint, 0, 0, 0, 0, 4, 0);
    const int timers[] = { 0, 42, 43, 44, 45, 46, 47, 49 };
    for (unsigned index = 0; index < sizeof(timers) / sizeof(timers[0]); ++index)
        update(&fingerprint, (uint64_t) timers[index], 0, 0, 0, 0, 1);
    update(&fingerprint, 45, mother, mother, 5.01f, 0, 1);
    update(&fingerprint, 45, other, mother, 50, 0, 1);
    update(&fingerprint, 0, mother, mother, 5, 0, 1);

    printf("tuxiesMotherEyesFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern Tuxie's mother eyes C contract passed\n");
    return 0;
}
