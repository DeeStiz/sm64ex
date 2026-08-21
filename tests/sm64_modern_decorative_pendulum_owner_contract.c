#include <stdint.h>
#include <stdio.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_gameplay_parity.h"

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

int main(void) {
    static const uint64_t object_ids[] = {
        SM64_MODERN_FIELD_ACTOR_BEHAVIOR,
        SM64_MODERN_FIELD_ACTOR_ACTIVE_FLAGS,
        SM64_MODERN_FIELD_ACTOR_ACTION,
        SM64_MODERN_FIELD_ACTOR_SUB_ACTION,
        SM64_MODERN_FIELD_ACTOR_TIMER,
        SM64_MODERN_FIELD_ACTOR_POSITION,
        SM64_MODERN_FIELD_ACTOR_VELOCITY,
        SM64_MODERN_FIELD_ACTOR_MOVE_ANGLE,
        SM64_MODERN_FIELD_ACTOR_MOVE_FLAGS,
        SM64_MODERN_FIELD_ACTOR_INTERACTION_STATUS,
        SM64_MODERN_FIELD_ACTOR_HELD_STATE,
        SM64_MODERN_FIELD_ACTOR_FLAGS,
        SM64_MODERN_FIELD_ACTOR_FORWARD_VELOCITY,
        SM64_MODERN_FIELD_ACTOR_GRAPH_FLAGS,
    };
    if (SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION != 4u
        || SM64_MODERN_ORACLE_DOMAIN_OBJECT != 3u
        || SM64_MODERN_ORACLE_DOMAIN_SCRIPT != 6u
        || SM64_MODERN_ORACLE_DOMAIN_COLLISION != 7u
        || SM64_MODERN_ORACLE_DOMAIN_EFFECT != 12u
        || SM64_MODERN_ORACLE_RECORD_STATE != 1u
        || SM64_MODERN_ORACLE_RECORD_EVENT != 3u
        || SM64_MODERN_ORACLE_RECORD_EFFECT != 4u
        || SM64_MODERN_ORACLE_SCRIPT_EVENT_BEHAVIOR_COMMAND != 2u
        || SM64_MODERN_ORACLE_SCRIPT_EVENT_LIFECYCLE != 5u
        || SM64_MODERN_ORACLE_COLLISION_EVENT_FLOOR != 1u
        || SM64_MODERN_EFFECT_SOUND != 1u) {
        fprintf(stderr, "decorative pendulum owner schema constants changed\n");
        return 1;
    }
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    for (size_t index = 0; index < sizeof(object_ids) / sizeof(object_ids[0]); ++index) {
        if (object_ids[index] != UINT64_C(400) + index) {
            fprintf(stderr, "decorative pendulum object state ordering changed\n");
            return 1;
        }
        fingerprint = hash_u64(fingerprint, object_ids[index]);
    }
    fingerprint = hash_u64(fingerprint, SM64_MODERN_ORACLE_SCRIPT_EVENT_LIFECYCLE);
    fingerprint = hash_u64(fingerprint, SM64_MODERN_ORACLE_SCRIPT_EVENT_BEHAVIOR_COMMAND);
    fingerprint = hash_u64(fingerprint, SM64_MODERN_ORACLE_COLLISION_EVENT_FLOOR);
    fingerprint = hash_u64(fingerprint, SM64_MODERN_EFFECT_SOUND);
    printf("decorativePendulumOwnerSchemaFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern decorative pendulum owner C contract passed\n");
    return 0;
}
