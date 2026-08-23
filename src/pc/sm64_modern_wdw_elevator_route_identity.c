#include <string.h>

#include "game/area.h"
#include "level_table.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_wdw_elevator_route_identity.h"

static SM64ModernWdwElevatorRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;
static uint32_t sMatches;

static uint32_t float_bits(float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

void sm64_modern_wdw_elevator_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
    sMatches = 0;
}

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
    uint32_t sound_played) {
    sInvocations++;
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_simulation_tick()
        : 0u;
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.source_identity = SM64_MODERN_WDW_ELEVATOR_ROUTE_SOURCE_ID;
    sLastReceipt.owner_identity = SM64_MODERN_WDW_ELEVATOR_ROUTE_OWNER_ID;
    sLastReceipt.behavior_identity = SM64_MODERN_WDW_ELEVATOR_ROUTE_BEHAVIOR_ID;
    sLastReceipt.source_subject = source_subject;
    sLastReceipt.level = (uint32_t) gCurrLevelNum;
    sLastReceipt.area = gCurrentArea ? (uint32_t) gCurrentArea->index : 0u;
    sLastReceipt.action_before = action_before;
    sLastReceipt.action_after = action_after;
    sLastReceipt.timer = timer;
    sLastReceipt.position_y_before_bits = float_bits(position_y_before);
    sLastReceipt.position_y_after_bits = float_bits(position_y_after);
    sLastReceipt.home_y_bits = float_bits(home_y);
    sLastReceipt.velocity_y_before_bits = float_bits(velocity_y_before);
    sLastReceipt.velocity_y_after_bits = float_bits(velocity_y_after);
    sLastReceipt.mario_on_platform = mario_on_platform ? 1u : 0u;
    sLastReceipt.sound_played = sound_played ? 1u : 0u;
    sLastReceipt.flags = SM64_MODERN_WDW_ELEVATOR_ROUTE_FLAG_SOURCE_AUTHORED
        | SM64_MODERN_WDW_ELEVATOR_ROUTE_FLAG_POINTERS_NORMALIZED
        | SM64_MODERN_WDW_ELEVATOR_ROUTE_FLAG_DYNAMIC;

    if (!sm64_modern_oracle_trace_is_active()) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_OK;
        return SM64_MODERN_STATUS_OK;
    }

    /* The source observer is intentionally fail-closed outside the authored
     * WDW area-1 lifecycle.  The wrong static sibling never reaches this
     * function, and a direct/fixture invocation cannot become evidence. */
    if (sLastReceipt.level != LEVEL_WDW || sLastReceipt.area != 1u
        || source_subject == 0u) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_PARITY_DIVERGED;
        return sLastReceipt.observe_status;
    }

    const uint64_t values[8] = {
        source_subject,
        ((uint64_t) sLastReceipt.level)
            | ((uint64_t) sLastReceipt.area << 32),
        ((uint64_t) action_before)
            | ((uint64_t) action_after << 32),
        ((uint64_t) timer)
            | ((uint64_t) sLastReceipt.mario_on_platform << 32)
            | ((uint64_t) sLastReceipt.sound_played << 33),
        sLastReceipt.position_y_before_bits,
        sLastReceipt.position_y_after_bits,
        sLastReceipt.home_y_bits,
        ((uint64_t) sLastReceipt.velocity_y_before_bits)
            | ((uint64_t) sLastReceipt.velocity_y_after_bits << 32),
    };
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        SM64_MODERN_WDW_ELEVATOR_ROUTE_OWNER_ID,
        SM64_MODERN_WDW_ELEVATOR_ROUTE_SOURCE_ID,
        sLastReceipt.flags,
        values,
        8u);
    sLastReceipt.observe_status = status;
    if (status == SM64_MODERN_STATUS_OK) {
        sMatches++;
    }
    return status;
}

uint64_t sm64_modern_wdw_elevator_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_wdw_elevator_route_matches(void) {
    return sMatches;
}

const SM64ModernWdwElevatorRouteReceiptV1 *
sm64_modern_wdw_elevator_route_last_receipt(void) {
    return &sLastReceipt;
}
