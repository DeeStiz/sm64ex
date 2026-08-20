#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct output {
    int32_t action;
    int32_t face_roll;
    int lower_sound;
    int raise_sound;
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static struct output update(int32_t action, int32_t timer, uint64_t global_timer, int32_t face_roll) {
    struct output output = { action, (int16_t)face_roll, 0, 0 };
    if (action == 0) {
        output.face_roll = (int16_t)(output.face_roll + 0x100);
    } else if (action == 1) {
        output.face_roll = (int16_t)(output.face_roll - 0x100);
    }
    if ((int16_t)output.face_roll < -0x1FFD) {
        output.face_roll = (int16_t)0xDFFF;
        if (timer >= 51 && global_timer % 8 == 0) {
            output.action = 0;
            output.lower_sound = 1;
        }
    }
    if ((int16_t)output.face_roll >= 0) {
        output.face_roll = 0;
        if (timer >= 51 && global_timer % 8 == 0) {
            output.action = 1;
            output.raise_sound = 1;
        }
    }
    return output;
}

int main(void) {
    const struct output cases[] = {
        update(0, 0, 1, 0),
        update(0, 51, 8, 0),
        update(1, 51, 8, -0x1F00),
        update(1, 1, 2, 0),
    };
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)cases[i].action);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)cases[i].face_roll);
        fingerprint = hash_u64(fingerprint, (uint64_t)cases[i].lower_sound);
        fingerprint = hash_u64(fingerprint, (uint64_t)cases[i].raise_sound);
    }
    if (cases[0].face_roll != 0 || cases[1].action != 1 || cases[1].face_roll != 0 ||
        !cases[1].raise_sound || cases[2].action != 0 || cases[2].face_roll != -0x2001 ||
        !cases[2].lower_sound || cases[3].action != 1 || cases[3].face_roll != -0x100) {
        return 1;
    }
    printf("lllDrawbridgeFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern LLL drawbridge C contract passed");
    return 0;
}
