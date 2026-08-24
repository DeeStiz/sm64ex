#include <string.h>

#include "sm64_modern_rng_route_identity.h"

#include "engine/behavior_script.h"
#include "pc/sm64_modern_gameplay_parity.h"

static SM64ModernRNGRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;
static uint32_t sMatches;

void sm64_modern_rng_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
    sMatches = 0;
}

SM64ModernStatus sm64_modern_rng_route_observe_u16(
    uint32_t call_site,
    uint16_t value,
    uint16_t seed) {
    sInvocations++;
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_simulation_tick() : 0u;
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.source_identity = SM64_MODERN_RNG_ROUTE_SOURCE_ID;
    sLastReceipt.call_site = call_site;
    sLastReceipt.value = value;
    sLastReceipt.seed = seed;

    if (!sm64_modern_oracle_trace_is_active()) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_OK;
        return SM64_MODERN_STATUS_OK;
    }
    if (call_site != SM64_MODERN_RNG_ROUTE_CALLSITE_MOVE_YAW
        && call_site != SM64_MODERN_RNG_ROUTE_CALLSITE_FACE_PITCH) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return sLastReceipt.observe_status;
    }

    const uint64_t values[2] = { value, seed };
    SM64ModernStatus status = sm64_modern_oracle_trace_mark_coverage(
        SM64_MODERN_ORACLE_DOMAIN_RNG,
        SM64_MODERN_ORACLE_RNG_EVENT_U16);
    if (status == SM64_MODERN_STATUS_OK) {
        status = sm64_modern_oracle_trace_record(
            SM64_MODERN_ORACLE_DOMAIN_RNG,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_RNG_ROUTE_SOURCE_ID,
            SM64_MODERN_ORACLE_RNG_EVENT_U16,
            call_site,
            values,
            2u);
    }
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    sLastReceipt.observe_status = status;
    return status;
}

SM64ModernStatus sm64_modern_rng_route_observe_u16_current_seed(
    uint32_t call_site,
    uint16_t value) {
    return sm64_modern_rng_route_observe_u16(call_site, value, random_seed_get());
}

uint64_t sm64_modern_rng_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_rng_route_matches(void) {
    return sMatches;
}

const SM64ModernRNGRouteReceiptV1 *sm64_modern_rng_route_last_receipt(void) {
    return &sLastReceipt;
}
