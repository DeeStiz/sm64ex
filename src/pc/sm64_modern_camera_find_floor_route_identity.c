#include <string.h>

#include "sm64_modern_camera_find_floor_route_identity.h"

#include "engine/surface_collision.h"
#include "pc/sm64_modern_gameplay_parity.h"

static SM64ModernCameraFindFloorRouteReceiptV1 sLastReceipt;
static uint64_t sInvocations;

static uint32_t float_bits(float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

void sm64_modern_camera_find_floor_route_reset(void) {
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sInvocations = 0;
}

SM64ModernStatus sm64_modern_camera_find_floor_route_observe(
    float x,
    float y,
    float z,
    float height,
    const struct Surface *surface) {
    sInvocations++;
    memset(&sLastReceipt, 0, sizeof(sLastReceipt));
    sLastReceipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sLastReceipt.header.struct_size = sizeof(sLastReceipt);
    sLastReceipt.simulation_tick = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_simulation_tick() : 0u;
    sLastReceipt.invocation = sInvocations;
    sLastReceipt.subject_id = SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_SUBJECT_ID;
    sLastReceipt.x_bits = float_bits(x);
    sLastReceipt.y_bits = float_bits(y);
    sLastReceipt.z_bits = float_bits(z);
    sLastReceipt.height_bits = float_bits(height);
    sLastReceipt.surface_present = surface != NULL ? 1u : 0u;
    sLastReceipt.surface_type = surface != NULL ? surface->type : UINT32_MAX;
    sLastReceipt.normal_y_bits = surface != NULL
        ? float_bits(surface->normal.y) : 0u;
    sLastReceipt.origin_offset_bits = surface != NULL
        ? float_bits(surface->originOffset) : 0u;
    sLastReceipt.source_identity = SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_SUBJECT_ID;

    if (!sm64_modern_oracle_trace_is_active()) {
        sLastReceipt.observe_status = SM64_MODERN_STATUS_OK;
        return SM64_MODERN_STATUS_OK;
    }

    const uint64_t values[8] = {
        sLastReceipt.x_bits,
        sLastReceipt.y_bits,
        sLastReceipt.z_bits,
        sLastReceipt.height_bits,
        sLastReceipt.surface_present,
        sLastReceipt.surface_type,
        sLastReceipt.normal_y_bits,
        sLastReceipt.origin_offset_bits,
    };
    SM64ModernStatus status = sm64_modern_oracle_trace_mark_coverage(
        SM64_MODERN_ORACLE_DOMAIN_COLLISION,
        SM64_MODERN_ORACLE_COLLISION_EVENT_FLOOR);
    if (status == SM64_MODERN_STATUS_OK) {
        status = sm64_modern_oracle_trace_record(
            SM64_MODERN_ORACLE_DOMAIN_COLLISION,
            SM64_MODERN_ORACLE_RECORD_EVENT,
            SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_SUBJECT_ID,
            SM64_MODERN_ORACLE_COLLISION_EVENT_FLOOR,
            SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_FLAG,
            values,
            8u);
    }
    sLastReceipt.observe_status = status;
    return status;
}

uint64_t sm64_modern_camera_find_floor_route_invocations(void) {
    return sInvocations;
}

const SM64ModernCameraFindFloorRouteReceiptV1 *
sm64_modern_camera_find_floor_route_last_receipt(void) {
    return &sLastReceipt;
}
