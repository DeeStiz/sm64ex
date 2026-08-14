#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_result(uint64_t hash, uint64_t frame,
                            const uint64_t *counts, uint64_t object_counter,
                            const uint64_t *updated, uint64_t updated_count,
                            const uint64_t *skipped, uint64_t skipped_count,
                            const uint64_t *unloaded, uint64_t unloaded_count,
                            uint64_t was_active, uint64_t is_active) {
    hash = hash_u64(hash, frame);
    for (unsigned index = 0; index < 13; ++index) hash = hash_u64(hash, counts[index]);
    hash = hash_u64(hash, object_counter);
    hash = hash_u64(hash, updated_count);
    for (uint64_t index = 0; index < updated_count; ++index) hash = hash_u64(hash, updated[index]);
    hash = hash_u64(hash, skipped_count);
    for (uint64_t index = 0; index < skipped_count; ++index) hash = hash_u64(hash, skipped[index]);
    hash = hash_u64(hash, unloaded_count);
    for (uint64_t index = 0; index < unloaded_count; ++index) hash = hash_u64(hash, unloaded[index]);
    hash = hash_u64(hash, was_active);
    return hash_u64(hash, is_active);
}

int main(void) {
    const uint64_t first_counts[13] = { 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 1 };
    const uint64_t first_updated[] = { 1, 6, 2, 4, 3, 5 };
    const uint64_t first_unloaded[] = { 2 };
    const uint64_t second_counts[13] = { 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 2, 1 };
    const uint64_t second_updated[] = { 1, 6, 4, 3, 5 };
    const uint64_t third_counts[13] = { 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 2, 1 };
    const uint64_t third_updated[] = { 4, 5 };
    const uint64_t third_skipped[] = { 1, 6, 3 };
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_result(fingerprint, 1, first_counts, 4, first_updated, 6,
                              NULL, 0, first_unloaded, 1, 0, 0);
    fingerprint = hash_result(fingerprint, 2, second_counts, 3, second_updated, 5,
                              NULL, 0, NULL, 0, 0, 1);
    fingerprint = hash_result(fingerprint, 3, third_counts, 3, third_updated, 2,
                              third_skipped, 3, NULL, 0, 1, 1);
    printf("objectSchedulerFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
