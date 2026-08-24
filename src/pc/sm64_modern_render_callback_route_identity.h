#ifndef SM64_MODERN_RENDER_CALLBACK_ROUTE_IDENTITY_H
#define SM64_MODERN_RENDER_CALLBACK_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * This identity is bound to the source-owned gfx_run entry point.  The
 * observer receives only a value-level presence bit; the display-list pointer
 * never crosses the schema-4 boundary.
 */
#define SM64_MODERN_RENDER_CALLBACK_ROUTE_IDENTITY \
    "src/pc/gfx/gfx_pc.c:1783:gfx_run"
#define SM64_MODERN_RENDER_CALLBACK_ROUTE_SHARD_ID UINT64_C(0xd5a43d537c37e833)
#define SM64_MODERN_RENDER_CALLBACK_ROUTE_INPUT_SEED UINT64_C(0xff2793527bb5fb03)
#define SM64_MODERN_RENDER_CALLBACK_ROUTE_SAVE_SEED UINT64_C(0xc57d3aed08300d60)
#define SM64_MODERN_RENDER_CALLBACK_ROUTE_SUBJECT_ID UINT64_C(0x52434c4247465855)
#define SM64_MODERN_RENDER_CALLBACK_ROUTE_FLAG UINT32_C(0x52434c42)
#define SM64_MODERN_ORACLE_RENDER_EVENT_CALLBACK UINT64_C(6)

typedef struct SM64ModernRenderCallbackRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t subject_id;
    uint32_t commands_present;
    uint32_t reserved;
    uint64_t source_identity;
    SM64ModernStatus observe_status;
} SM64ModernRenderCallbackRouteReceiptV1;

void sm64_modern_render_callback_route_reset(void);
SM64ModernStatus sm64_modern_render_callback_route_observe(
    uint32_t commands_present);
uint64_t sm64_modern_render_callback_route_invocations(void);
const SM64ModernRenderCallbackRouteReceiptV1 *
sm64_modern_render_callback_route_last_receipt(void);

#endif
