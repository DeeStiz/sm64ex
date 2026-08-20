#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct output { int32_t sound_intent; int play_sound; };
static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) { hash ^= (value >> (byte * 8u)) & UINT64_C(0xff); hash *= FNV_PRIME; }
    return hash;
}
static struct output update(int kind, unsigned byte, int behind) {
    if (behind) return (struct output){-1, 0};
    if (kind == 1) return (struct output){3, 1};
    if (byte < 3) return (struct output){(int32_t)byte, 1};
    return (struct output){-1, 0};
}
int main(void) {
    const struct output outputs[] = {
        update(0, 0, 0), update(0, 2, 0), update(0, 3, 0),
        update(0, 0, 1), update(1, 0, 0), update(1, 0, 1),
    };
    const int32_t intents[] = {0, 2, -1, -1, 3, -1};
    const int plays[] = {1, 1, 0, 0, 1, 0};
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned i = 0; i < 6; ++i) {
        if (outputs[i].sound_intent != intents[i] || outputs[i].play_sound != plays[i]) return 1;
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)outputs[i].sound_intent);
        fingerprint = hash_u64(fingerprint, (uint64_t)outputs[i].play_sound);
    }
    printf("ambientSoundLoopFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern ambient sound loop C contract passed");
    return 0;
}
