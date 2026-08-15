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
    for (size_t index = 0; index < count; ++index) hash = hash_u64(hash, values[index]);
    return hash;
}

static uint64_t hash_effect(uint64_t hash, uint64_t object_id, uint64_t kind, uint64_t index, uint64_t effects, uint64_t action, uint64_t marked) {
    const uint64_t values[] = { object_id, kind, index, effects, action, marked };
    return hash_values(hash, values, sizeof(values) / sizeof(values[0]));
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;

    const uint64_t far[] = {
        0x1, 0, 0, 0,
        1092616192, 1128792064, 1106247680,
        1092616192, 1128792064, 1106247680,
        1092616192, 1128792064, 1106247680,
        0, 0, 0, 0, 3229614080, 1125515264, 1125515264, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    };
    fingerprint = hash_values(fingerprint, far, sizeof(far) / sizeof(far[0]));

    const uint64_t allocate[] = {
        0x7, 1, 0, 0,
        1092616192, 1128792064, 1106247680,
        1092616192, 1128792064, 1106247680,
        1092616192, 1128792064, 1106247680,
        0, 0, 0, 3229614080, 3229614080, 1125515264, 1125515264, 0, 0, 0, 0, 0, 0, 0, 1, 0, 2,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    };
    fingerprint = hash_values(fingerprint, allocate, sizeof(allocate) / sizeof(allocate[0]));

    const uint64_t lunge[] = {
        0xd, 1, 1, 0,
        1092616192, 1128792064, 1106247680,
        1092616192, 1130102784, 1126825984,
        1092616192, 1128792064, 1106247680,
        0, 0, 1124859904, 1101004800, 0, 1127481344, 1125515264, 1124953054, 14907, 0, 0, 0, 0, 0, 1, 0, 42,
        0, 1101004800, 1124859904, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    };
    fingerprint = hash_values(fingerprint, lunge, sizeof(lunge) / sizeof(lunge[0]));

    const uint64_t attack[] = {
        0x19, 1, 1, 0,
        1092616192, 1128792064, 1106247680,
        1092616192, 1131413504, 1134231552,
        1092616192, 1128792064, 1106247680,
        0, 1024, 0, 1133903872, 3229614080, 1127481344, 1127481344, 1133341662, 53248, 0, 0, 0, 0, 0, 1, 0, 1,
        0, 1109393408, 1133248512, 0, 1097381084, 1120640576, 0, 0, 0, 0, 0, 0, 0, 0, 0
    };
    fingerprint = hash_values(fingerprint, attack, sizeof(attack) / sizeof(attack[0]));

    const uint64_t unload[] = {
        0x101, 2, 1, 0,
        1092616192, 1128792064, 1106247680,
        1092616192, 1131413504, 1134231552,
        1092616192, 1128792064, 1106247680,
        0, 1024, 0, 0, 3229614080, 1127481344, 1127481344, 1133341662, 53248, 0, 0, 0, 0, 0, 1, 0, 2,
        0, 1109393408, 1133248512, 0, 1097381084, 1120640576, 0, 0, 0, 0, 0, 0, 0, 0, 0
    };
    fingerprint = hash_values(fingerprint, unload, sizeof(unload) / sizeof(unload[0]));

    fingerprint = hash_effect(fingerprint, 1, 0, 255, 0x7, 1, 0);
    fingerprint = hash_effect(fingerprint, 2, 1, 0, 0x1, 255, 0);
    fingerprint = hash_effect(fingerprint, 3, 1, 1, 0x1, 255, 0);
    fingerprint = hash_effect(fingerprint, 4, 1, 2, 0x1, 255, 0);
    fingerprint = hash_effect(fingerprint, 5, 1, 3, 0x1, 255, 0);
    fingerprint = hash_effect(fingerprint, 6, 1, 4, 0x1, 255, 0);

    printf("chainChompObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
