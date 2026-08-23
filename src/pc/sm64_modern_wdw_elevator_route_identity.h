#ifndef SM64_MODERN_WDW_ELEVATOR_ROUTE_IDENTITY_H
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * Phase 85f47 is bound to the source-authored dynamic WDW elevator row.  The
 * source and owner IDs are route metadata; the behavior IDs are the semantic
 * source-name identities used by the object snapshot boundary.  No linked
 * behavior pointer or Object pointer crosses this seam.
 */
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_SHARD_ID UINT64_C(0x6e6c6a0fc1b92a45)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_INPUT_SEED UINT64_C(0x42e8c17d93a5b601)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_SAVE_SEED UINT64_C(0x73f4b2c88e16d905)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_SOURCE_ID UINT64_C(0x73776902d63209e9)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_OWNER_ID UINT64_C(0x4490d0bf72a4dab6)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_STATIC_SOURCE_ID UINT64_C(0xd50f815812e49dd6)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_STATIC_OWNER_ID UINT64_C(0x57eea3c39811e29f)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_BEHAVIOR_ID UINT64_C(0xcba3488bb46b4d7f)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_STATIC_BEHAVIOR_ID UINT64_C(0xc623c007308bf7c0)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_EVENT UINT64_C(4)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_FLAG_SOURCE_AUTHORED UINT32_C(1u << 0)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_FLAG_POINTERS_NORMALIZED UINT32_C(1u << 1)
#define SM64_MODERN_WDW_ELEVATOR_ROUTE_FLAG_DYNAMIC UINT32_C(1u << 2)

/*
 * The route record uses eight 64-bit values.  Two 32-bit source values are
 * packed into one value where necessary; all floating-point values are copied
 * by bit pattern.  The receipt itself retains the unpacked values for the C
 * contract, but neither representation contains a host pointer.
 */
typedef struct SM64ModernWdwElevatorRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t source_identity;
    uint64_t owner_identity;
    uint64_t behavior_identity;
    uint32_t source_subject;
    uint32_t level;
    uint32_t area;
    uint32_t action_before;
    uint32_t action_after;
    uint32_t timer;
    uint32_t position_y_before_bits;
    uint32_t position_y_after_bits;
    uint32_t home_y_bits;
    uint32_t velocity_y_before_bits;
    uint32_t velocity_y_after_bits;
    uint32_t mario_on_platform;
    uint32_t sound_played;
    uint32_t flags;
    SM64ModernStatus observe_status;
} SM64ModernWdwElevatorRouteReceiptV1;

void sm64_modern_wdw_elevator_route_reset(void);

/* Called exactly once after the source reducer has completed. */
SM64ModernStatus sm64_modern_wdw_elevator_route_observe(
    uint32_t source_subject,
    uint32_t action_before,
    uint32_t action_after,
    uint32_t timer,
    float position_y_before,
    float position_y_after,
    float home_y,
    float velocity_y_before,
    float velocity_y_after,
    uint32_t mario_on_platform,
    uint32_t sound_played);

uint64_t sm64_modern_wdw_elevator_route_invocations(void);
uint32_t sm64_modern_wdw_elevator_route_matches(void);
const SM64ModernWdwElevatorRouteReceiptV1 *
sm64_modern_wdw_elevator_route_last_receipt(void);

#endif
