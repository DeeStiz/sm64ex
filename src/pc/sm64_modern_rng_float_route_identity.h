#ifndef SM64_MODERN_RNG_FLOAT_ROUTE_IDENTITY_H
#define SM64_MODERN_RNG_FLOAT_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * This identity is bound to the three source-authored random_float calls in
 * obj_return_and_displace_home.  The source and call-site IDs are fixed-width
 * values; no function pointer, object pointer, or host address crosses the
 * schema-4 boundary.
 */
#define SM64_MODERN_RNG_FLOAT_ROUTE_SHARD_ID UINT64_C(0x00a6e0786f09cff4)
#define SM64_MODERN_RNG_FLOAT_ROUTE_INPUT_SEED UINT64_C(0x375f01d92891d0cc)
#define SM64_MODERN_RNG_FLOAT_ROUTE_SAVE_SEED UINT64_C(0x877f73ecc62e0275)
#define SM64_MODERN_RNG_FLOAT_ROUTE_SOURCE_ID UINT64_C(0x6f626a5f726e6e66)
#define SM64_MODERN_RNG_FLOAT_ROUTE_CALLSITE_GATE UINT32_C(0x4f424647)
#define SM64_MODERN_RNG_FLOAT_ROUTE_CALLSITE_HOME_X UINT32_C(0x4f425858)
#define SM64_MODERN_RNG_FLOAT_ROUTE_CALLSITE_HOME_Z UINT32_C(0x4f42585a)

typedef struct SM64ModernRNGFloatRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t source_identity;
    uint32_t call_site;
    uint32_t float_bits;
    uint32_t raw_seed;
    uint32_t reserved;
    SM64ModernStatus observe_status;
} SM64ModernRNGFloatRouteReceiptV1;

void sm64_modern_rng_float_route_reset(void);
SM64ModernStatus sm64_modern_rng_float_route_observe(
    uint32_t call_site,
    float value,
    uint16_t raw_seed);
/*
 * Capture the source RNG seed at the PC-side observation boundary. The seed
 * is receipt metadata for the authored random_float call and must not become
 * a second source inventory row through a random_seed_get() read in src/game.
 */
SM64ModernStatus sm64_modern_rng_float_route_observe_current_seed(
    uint32_t call_site,
    float value);
uint64_t sm64_modern_rng_float_route_invocations(void);
uint32_t sm64_modern_rng_float_route_matches(void);
const SM64ModernRNGFloatRouteReceiptV1 *
sm64_modern_rng_float_route_last_receipt(void);

#endif
