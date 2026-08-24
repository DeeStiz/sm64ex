#include <string.h>

#include "sm64_modern_render_callback_route_identity.h"

static SM64ModernRenderCallbackRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;

void sm64_modern_render_callback_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
}

SM64ModernStatus sm64_modern_render_callback_route_observe(
    uint32_t commands_present) {
    sInvocations++;
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_simulation_tick() : 0u;
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.subject_id = SM64_MODERN_RENDER_CALLBACK_ROUTE_SUBJECT_ID;
    sLastReceipt.commands_present = commands_present != 0u ? 1u : 0u;
    sLastReceipt.source_identity = SM64_MODERN_RENDER_CALLBACK_ROUTE_SUBJECT_ID;

    if (!sm64_modern_oracle_trace_is_active()) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_OK;
        return SM64_MODERN_STATUS_OK;
    }

    const uint64_t values[4] = {
        sLastReceipt.invocation,
        sLastReceipt.commands_present,
        sLastReceipt.source_identity,
        sLastReceipt.simulation_tick,
    };
    SM64ModernStatus status = sm64_modern_oracle_trace_mark_coverage(
        SM64_MODERN_ORACLE_DOMAIN_RENDER,
        SM64_MODERN_ORACLE_RENDER_EVENT_CALLBACK);
    if (status == SM64_MODERN_STATUS_OK) {
        status = sm64_modern_oracle_trace_record(
            SM64_MODERN_ORACLE_DOMAIN_RENDER,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_RENDER_CALLBACK_ROUTE_SUBJECT_ID,
            SM64_MODERN_ORACLE_RENDER_EVENT_CALLBACK,
            SM64_MODERN_RENDER_CALLBACK_ROUTE_FLAG,
            values,
            4u);
    }
    sLastReceipt.observe_status = status;
    return status;
}

uint64_t sm64_modern_render_callback_route_invocations(void) {
    return sInvocations;
}

const SM64ModernRenderCallbackRouteReceiptV1 *
sm64_modern_render_callback_route_last_receipt(void) {
    return &sLastReceipt;
}
