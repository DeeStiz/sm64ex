#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#include "pc/sm64_modern_pokey_route_identity.h"

_Static_assert(SM64_MODERN_POKEY_ROUTE_LEVEL == 8u,
               "SSL level id changed");
_Static_assert(SM64_MODERN_POKEY_ROUTE_CHILD_COUNT == 5u,
               "Pokey child count changed");
_Static_assert(SM64_MODERN_POKEY_ROUTE_INITIAL_MASK == 0x1fu,
               "Pokey alive mask changed");

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned index = 0; index < 8u; ++index) {
        seed ^= (value >> (index * 8u)) & UINT64_C(0xff);
        seed *= UINT64_C(1099511628211);
    }
    return seed;
}

int main(void) {
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_u64(fingerprint,
                           SM64_MODERN_POKEY_ROUTE_PARENT_BEHAVIOR_ID);
    fingerprint = hash_u64(fingerprint,
                           SM64_MODERN_POKEY_ROUTE_CHILD_BEHAVIOR_ID);
    fingerprint = hash_u64(fingerprint, SM64_MODERN_POKEY_ROUTE_HITBOX_ID);
    for (uint32_t index = 0; index < 4u; ++index) {
        if (!sm64_modern_pokey_route_source_tuple(index)) {
            return 1;
        }
    }
    if (sm64_modern_pokey_route_source_tuple(4u)) {
        return 1;
    }
    printf("pokeyRouteFingerprint=0x%016" PRIx64 "\n", fingerprint);
    puts("SM64 Modern Pokey route C contract passed");
    return 0;
}
