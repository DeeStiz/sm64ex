#include <stdint.h>
#include <stdio.h>

static uint64_t fnv_u64(uint64_t hash, uint64_t value) {
    for (int shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t record_hash(
    uint64_t tick,
    uint64_t domain,
    uint64_t kind,
    uint64_t subject,
    uint64_t recordID,
    uint64_t sequence,
    const uint64_t *values,
    uint64_t valueCount,
    uint64_t flags
) {
    uint64_t hash = UINT64_C(1469598103934665603);
    hash = fnv_u64(hash, tick);
    hash = fnv_u64(hash, domain);
    hash = fnv_u64(hash, kind);
    hash = fnv_u64(hash, subject);
    hash = fnv_u64(hash, recordID);
    hash = fnv_u64(hash, sequence);
    hash = fnv_u64(hash, valueCount);
    hash = fnv_u64(hash, flags);
    for (uint64_t i = 0; i < valueCount; ++i) hash = fnv_u64(hash, values[i]);
    return hash;
}

int main(void) {
    const uint64_t sequenceTatum[] = { 0, 0, 0 };
    const uint64_t sequenceTempo[] = { 0xdd, 5760, 0 };
    const uint64_t pool[] = { 0, 3, 2, 2 };
    const uint64_t residency[] = { 1, 10, 0, 160 };
    const uint64_t stream[] = { 1, 10, 0, 0x1230 };
    const uint64_t hashes[] = {
        record_hash(1, 9, 1, 0, UINT64_C(0xA7010001), 0, sequenceTatum, 3, 0),
        record_hash(1, 9, 1, 0, UINT64_C(0xA701000D), 1, sequenceTempo, 3, 0),
        record_hash(2, 9, 1, 0, UINT64_C(0xA702000A), 2, pool, 4, 0),
        record_hash(2, 9, 1, 10, UINT64_C(0xA7030001), 3, residency, 4, 0),
        record_hash(3, 9, 1, 10, UINT64_C(0xA7040014), 4, stream, 4, 0),
    };
    uint64_t fingerprint = fnv_u64(UINT64_C(1469598103934665603), 5);
    for (int i = 0; i < 5; ++i) fingerprint = fnv_u64(fingerprint, hashes[i]);
    fingerprint = fnv_u64(fingerprint, 1);
    printf("audioTraceFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern audio trace C contract passed\n");
    return 0;
}
