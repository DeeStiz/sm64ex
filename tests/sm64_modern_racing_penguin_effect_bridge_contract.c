#include <stdint.h>
#include <stdio.h>

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int byte = 0; byte < 4; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8)) & 0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (int byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_id(uint64_t hash, uint32_t slot, uint32_t generation) {
    hash = hash_u32(hash, slot);
    return hash_u32(hash, generation);
}

static uint64_t hash_intent(uint64_t hash, uint64_t sequence,
                            uint32_t slot, uint32_t generation,
                            uint32_t kind, int32_t value, int32_t auxiliary) {
    hash = hash_u64(hash, sequence);
    hash = hash_id(hash, slot, generation);
    hash = hash_u32(hash, kind);
    hash = hash_u32(hash, (uint32_t) value);
    return hash_u32(hash, (uint32_t) auxiliary);
}

static uint64_t hash_delivery(uint64_t hash, uint32_t delivered_count,
                              const uint64_t *delivered_sequences,
                              const uint32_t *delivered_slots,
                              const uint32_t *delivered_kinds,
                              const int32_t *delivered_values,
                              uint32_t presented_count,
                              const uint64_t *presented_sequences,
                              const uint32_t *presented_slots,
                              const uint32_t *presented_kinds,
                              const int32_t *presented_values,
                              uint32_t spawned_count, const uint32_t *spawned_slots,
                              uint32_t deleted_count, const uint32_t *deleted_slots) {
    hash = hash_u32(hash, delivered_count);
    for (uint32_t i = 0; i < delivered_count; ++i) {
        hash = hash_intent(hash, delivered_sequences[i], delivered_slots[i], 1,
                           delivered_kinds[i], delivered_values[i], 0);
    }
    hash = hash_u32(hash, presented_count);
    for (uint32_t i = 0; i < presented_count; ++i) {
        hash = hash_intent(hash, presented_sequences[i], presented_slots[i], 1,
                           presented_kinds[i], presented_values[i], 0);
    }
    hash = hash_u32(hash, spawned_count);
    for (uint32_t i = 0; i < spawned_count; ++i) {
        hash = hash_id(hash, spawned_slots[i], 1);
    }
    hash = hash_u32(hash, deleted_count);
    for (uint32_t i = 0; i < deleted_count; ++i) {
        hash = hash_id(hash, deleted_slots[i], 1);
    }
    return hash_u32(hash, 0);
}

int main(void) {
    /* The C fixture deliberately records the owner-thread event contract,
       not the Swift implementation. IDs are the first-generation slots from
       the fixed-capacity smoke route. */
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    const uint64_t smoke_delivered_sequence[] = { 1, 2 };
    const uint32_t smoke_delivered_slot[] = { 3, 0 };
    const uint32_t smoke_delivered_kind[] = { 6, 0 };
    const int32_t smoke_delivered_value[] = { 0, 1 };
    const uint64_t smoke_presented_sequence[] = { 2 };
    const uint32_t smoke_presented_slot[] = { 0 };
    const uint32_t smoke_presented_kind[] = { 0 };
    const int32_t smoke_presented_value[] = { 1 };
    const uint32_t smoke_deleted_slots[] = { 3 };
    fingerprint = hash_delivery(
        fingerprint, 2, smoke_delivered_sequence, smoke_delivered_slot,
        smoke_delivered_kind, smoke_delivered_value, 1,
        smoke_presented_sequence, smoke_presented_slot, smoke_presented_kind,
        smoke_presented_value, 0, NULL, 1, smoke_deleted_slots);

    const uint64_t pounding_sequences[] = { 3, 4 };
    const uint32_t pounding_slots[] = { 0, 0 };
    const uint32_t pounding_kinds[] = { 0, 2 };
    const int32_t pounding_values[] = { 3, 1 };
    fingerprint = hash_delivery(
        fingerprint, 2, pounding_sequences, pounding_slots, pounding_kinds,
        pounding_values, 2, pounding_sequences, pounding_slots, pounding_kinds,
        pounding_values, 0, NULL, 0, NULL);

    const uint32_t walking_slots[] = { 0 };
    const uint32_t walking_kinds[] = { 0 };
    const int32_t walking_values[] = { 2 };
    for (uint64_t sequence = 5; sequence <= 18; ++sequence) {
        const uint64_t current_sequence[] = { sequence };
        fingerprint = hash_delivery(
            fingerprint, 1, current_sequence, walking_slots, walking_kinds,
            walking_values, 1, current_sequence, walking_slots, walking_kinds,
            walking_values, 0, NULL, 0, NULL);
    }

    const uint64_t dialog_sequence[] = { 19 };
    const uint32_t dialog_slot[] = { 0 };
    const uint32_t dialog_kind[] = { 8 };
    const int32_t dialog_value[] = { 56 };
    fingerprint = hash_delivery(
        fingerprint, 1, dialog_sequence, dialog_slot, dialog_kind, dialog_value,
        1, dialog_sequence, dialog_slot, dialog_kind, dialog_value, 0, NULL, 0,
        NULL);

    const uint64_t star_sequence[] = { 20 };
    const uint32_t star_slot[] = { 0 };
    const uint32_t star_kind[] = { 9 };
    const int32_t star_value[] = { 0 };
    fingerprint = hash_delivery(
        fingerprint, 1, star_sequence, star_slot, star_kind, star_value, 1,
        star_sequence, star_slot, star_kind, star_value, 0, NULL, 0, NULL);

    printf("racingPenguinEffectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern racing penguin effect bridge C contract passed\n");
    return 0;
}
