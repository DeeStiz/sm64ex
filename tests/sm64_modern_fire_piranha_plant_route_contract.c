#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#include "pc/sm64_modern_fire_piranha_plant_route_identity.h"

_Static_assert(SM64_MODERN_FIRE_PIRANHA_ROUTE_LEVEL == 13u,
               "THI level id is source-defined");
_Static_assert(SM64_MODERN_FIRE_PIRANHA_ROUTE_AREA == 1u,
               "THI route must use authored area 1");
_Static_assert(SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_FIRST == 4u,
               "first authored subject ordinal changed");
_Static_assert(SM64_MODERN_FIRE_PIRANHA_ROUTE_SOURCE_LAST == 8u,
               "last authored subject ordinal changed");
_Static_assert(SM64_MODERN_FIRE_PIRANHA_ROUTE_MODEL == 0x64u,
               "Piranha Plant model changed");
_Static_assert(SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_MODEL == 0xcbu,
               "red flame shadow model changed");
_Static_assert(SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_MODEL == 0x7au,
               "star reward model changed");
_Static_assert(sizeof(SM64ModernFirePiranhaPlantRouteInputV1) % 8u == 0u,
               "receipt input must remain 8-byte aligned");

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned index = 0; index < 8u; ++index) {
        seed ^= (value >> (index * 8u)) & UINT64_C(0xff);
        seed *= UINT64_C(1099511628211);
    }
    return seed;
}

int main(void) {
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_u64(
        fingerprint, SM64_MODERN_FIRE_PIRANHA_ROUTE_BEHAVIOR_ID);
    fingerprint = hash_u64(
        fingerprint, SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_BEHAVIOR_ID);
    fingerprint = hash_u64(
        fingerprint, SM64_MODERN_FIRE_PIRANHA_ROUTE_REWARD_BEHAVIOR_ID);
    fingerprint = hash_u64(
        fingerprint, SM64_MODERN_FIRE_PIRANHA_ROUTE_HITBOX_ID);
    fingerprint = hash_u64(
        fingerprint, SM64_MODERN_FIRE_PIRANHA_ROUTE_FLAME_HITBOX_ID);
    printf("firePiranhaPlantRouteFingerprint=0x%016" PRIx64 "\n",
           fingerprint);
    puts("SM64 Modern Fire Piranha Plant route C contract passed");
    return 0;
}
