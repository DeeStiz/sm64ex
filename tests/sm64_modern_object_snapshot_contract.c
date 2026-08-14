#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "object_fields.h"
#include "types.h"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t fingerprint(const uint64_t *values, size_t count) {
    uint64_t hash = FNV_OFFSET;
    for (size_t index = 0; index < count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t float_bits(float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static uint64_t signed32_value(int32_t value) {
    return (uint64_t)(int64_t)value;
}

int main(void) {
    struct Object actor;
    memset(&actor, 0, sizeof(actor));
    actor.activeFlags = 0x0101;
    actor.oAction = 7;
    actor.oSubAction = 3;
    actor.oTimer = -2;
    actor.oPosX = 1.5f;
    actor.oPosY = -2.25f;
    actor.oPosZ = 3.75f;
    actor.oVelX = -4.5f;
    actor.oVelY = 5.25f;
    actor.oVelZ = -6.125f;
    actor.oMoveAnglePitch = 0x1234;
    actor.oMoveAngleYaw = -32768;
    actor.oMoveAngleRoll = 0x7fff;
    actor.oMoveFlags = 0x12345678;
    actor.oInteractStatus = -9;
    actor.oHeldState = 2;
    actor.oFlags = 0x400;
    actor.oForwardVel = -1.25f;
    actor.header.gfx.node.flags = 0x00a5;

    const uint64_t actor_values[] = {
        UINT64_C(0x40),
        actor.activeFlags,
        signed32_value(actor.oAction),
        signed32_value(actor.oSubAction),
        signed32_value(actor.oTimer),
        float_bits(actor.oPosX),
        float_bits(actor.oPosY),
        float_bits(actor.oPosZ),
        float_bits(actor.oVelX),
        float_bits(actor.oVelY),
        float_bits(actor.oVelZ),
        (uint32_t) actor.oMoveAnglePitch,
        (uint32_t) actor.oMoveAngleYaw,
        (uint32_t) actor.oMoveAngleRoll,
        actor.oMoveFlags,
        signed32_value(actor.oInteractStatus),
        actor.oHeldState,
        actor.oFlags,
        float_bits(actor.oForwardVel),
        (uint16_t) actor.header.gfx.node.flags,
    };
    const uint64_t relation_values[] = { 1, 0, 1, 1, 0, 2, 0 };
    uint64_t combined_values[1 + sizeof(actor_values) / sizeof(actor_values[0])
                             + sizeof(relation_values) / sizeof(relation_values[0])];
    combined_values[0] = 2;
    memcpy(&combined_values[1], actor_values, sizeof(actor_values));
    memcpy(&combined_values[1 + sizeof(actor_values) / sizeof(actor_values[0])],
           relation_values, sizeof(relation_values));

    printf("actorFingerprint=0x%016llx\n", (unsigned long long) fingerprint(
        actor_values, sizeof(actor_values) / sizeof(actor_values[0])));
    printf("relationFingerprint=0x%016llx\n", (unsigned long long) fingerprint(
        relation_values, sizeof(relation_values) / sizeof(relation_values[0])));
    printf("combinedFingerprint=0x%016llx\n", (unsigned long long) fingerprint(
        combined_values, sizeof(combined_values) / sizeof(combined_values[0])));
    return 0;
}
