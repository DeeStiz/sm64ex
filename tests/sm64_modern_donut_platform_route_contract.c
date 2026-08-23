#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#include "pc/sm64_modern_donut_platform_route_identity.h"

_Static_assert(SM64_MODERN_DONUT_ROUTE_LEVEL == 15u,
               "RR level id changed");
_Static_assert(SM64_MODERN_DONUT_ROUTE_CHILD_COUNT == 31u,
               "source child count changed");
_Static_assert(SM64_MODERN_DONUT_ROUTE_ALL_CHILDREN_MASK == 0x7fffffffu,
               "source child mask changed");
_Static_assert(SM64_MODERN_DONUT_ROUTE_CHILD_MODEL == 0x3fu,
               "donut child model changed");

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
                           SM64_MODERN_DONUT_ROUTE_PARENT_BEHAVIOR_ID);
    fingerprint = hash_u64(fingerprint,
                           SM64_MODERN_DONUT_ROUTE_CHILD_BEHAVIOR_ID);
    fingerprint = hash_u64(fingerprint,
                           SM64_MODERN_DONUT_ROUTE_COLLISION_ID);
    for (uint32_t index = 0; index < SM64_MODERN_DONUT_ROUTE_CHILD_COUNT;
         ++index) {
        if (!sm64_modern_donut_platform_source_position(index)) {
            return 1;
        }
    }
    if (sm64_modern_donut_platform_source_position(31u)) {
        return 1;
    }
    printf("donutPlatformRouteFingerprint=0x%016" PRIx64 "\n",
           fingerprint);
    puts("SM64 Modern Donut Platform route C contract passed");
    return 0;
}
