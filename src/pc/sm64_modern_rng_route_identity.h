#ifndef SM64_MODERN_RNG_ROUTE_IDENTITY_H
#define SM64_MODERN_RNG_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * This identity is bound to the source-authored random_u16 call sites in
 * break_particles.inc.c. The subject ID carries the stable source identity;
 * flags carry the fixed-width call-site identity. No pointer or host address
 * crosses the schema-4 boundary.
 */
#define SM64_MODERN_RNG_ROUTE_SHARD_ID UINT64_C(0x00576356a427dbc2)
#define SM64_MODERN_RNG_ROUTE_INPUT_SEED UINT64_C(0x7f289fd41270636e)
#define SM64_MODERN_RNG_ROUTE_SAVE_SEED UINT64_C(0x3e05c8a6a9f41727)
#define SM64_MODERN_RNG_ROUTE_SOURCE_ID UINT64_C(0xcb90922e394c3a9b)
#define SM64_MODERN_RNG_ROUTE_CALLSITE_MOVE_YAW UINT32_C(0xf2f930d7)
#define SM64_MODERN_RNG_ROUTE_CALLSITE_FACE_PITCH UINT32_C(0x4648c6c9)

typedef struct SM64ModernRNGRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t source_identity;
    uint32_t call_site;
    uint32_t reserved;
    uint64_t value;
    uint64_t seed;
    SM64ModernStatus observe_status;
} SM64ModernRNGRouteReceiptV1;

void sm64_modern_rng_route_reset(void);
SM64ModernStatus sm64_modern_rng_route_observe_u16(
    uint32_t call_site,
    uint16_t value,
    uint16_t seed);
/*
 * Capture the source RNG seed at the PC-side observation boundary. Keeping
 * this read out of the source behavior include preserves the route inventory:
 * random_seed_get() is instrumentation metadata, not a second authored RNG
 * call site.
 */
SM64ModernStatus sm64_modern_rng_route_observe_u16_current_seed(
    uint32_t call_site,
    uint16_t value);
uint64_t sm64_modern_rng_route_invocations(void);
uint32_t sm64_modern_rng_route_matches(void);
const SM64ModernRNGRouteReceiptV1 *sm64_modern_rng_route_last_receipt(void);

#endif
