#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_values(uint64_t hash, const uint64_t *values, size_t count) {
    for (size_t index = 0; index < count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t hash_effect(
    uint64_t hash,
    uint64_t object_id,
    uint64_t effects,
    uint64_t action,
    uint64_t opacity,
    uint64_t marked
) {
    const uint64_t values[] = { object_id, effects, action, opacity, marked };
    return hash_values(hash, values, sizeof(values) / sizeof(values[0]));
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;

    const uint64_t chase[] = {
        0x3, 1,
        1092616192, 1140457472, 1106247680,
        1092616192, 1140457472, 1106247680,
        0, 0, 0, 0, 0,
        0, 0, 0, 255, 255,
        1065353216, 1065353216, 1065353216, 1065353216,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1
    };
    fingerprint = hash_values(fingerprint, chase, sizeof(chase) / sizeof(chase[0]));

    const uint64_t visible[] = {
        0x17, 1,
        1092616192, 1140457472, 1106247680,
        1092616192, 1140457472, 1109393408,
        0, 0, 0, 0, 0,
        1092616192, 0, 0, 255, 255,
        1065353216, 1065353216, 1065353216, 1065353216,
        1024, 0, 0, 0, 0, 0, 1, 32768, 0, 2
    };
    fingerprint = hash_values(fingerprint, visible, sizeof(visible) / sizeof(visible[0]));

    const uint64_t vanish[] = {
        0x209, 1,
        1092616192, 1140457472, 1106247680,
        1092616192, 1140457472, 1109393408,
        0, 0, 0, 0, 0,
        0, 0, 0, 235, 40,
        1065353216, 1064826872, 1064826872, 1064826872,
        1024, 0, 0, 0, 0, 0, 0, 0, 0, 3
    };
    fingerprint = hash_values(fingerprint, vanish, sizeof(vanish) / sizeof(vanish[0]));

    const uint64_t bounced[] = {
        0x37, 2,
        1092616192, 1140457472, 1106247680,
        1092616192, 1140457472, 1112014848,
        0, 0, 0, 0, 0,
        1092616192, 0, 0, 215, 40,
        1065353216, 1064300528, 1064300528, 1064300528,
        1024, 0, 0, 2147483648, 0, 0, 1, 32768, 0, 1
    };
    fingerprint = hash_values(fingerprint, bounced, sizeof(bounced) / sizeof(bounced[0]));

    const uint64_t roll[] = {
        0x21, 2,
        1092616192, 1140457472, 1106247680,
        1092616192, 1140489610, 1104051961,
        0, 32768, 6047, 0, 6047,
        1103200519, 1065030846, 0, 195, 40,
        1065353216, 1063774184, 1063774184, 1063774184,
        1024, 32768, 0, 2147483648, 0, 0, 1, 32768, 0, 1
    };
    fingerprint = hash_values(fingerprint, roll, sizeof(roll) / sizeof(roll[0]));

    const uint64_t death[] = {
        0x1101, 3,
        1092616192, 1140457472, 1106247680,
        1092616192, 1140653450, 1070587680,
        0, 32768, 8095, 0, 8095,
        1103200519, 1084227584, 0, 175, 40,
        1065353216, 1063247840, 1063247840, 1063247840,
        1024, 32768, 0, 2147483648, 0, 2, 1, 32768, 1, 32
    };
    fingerprint = hash_values(fingerprint, death, sizeof(death) / sizeof(death[0]));

    fingerprint = hash_effect(fingerprint, 1, 0x3, 1, 255, 0);
    fingerprint = hash_effect(fingerprint, 1, 0x17, 1, 255, 0);

    printf("booObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
