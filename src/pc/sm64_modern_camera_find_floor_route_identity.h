#ifndef SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_IDENTITY_H
#define SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

struct Surface;

/*
 * This identity is bound to the source-authored find_floor call in
 * set_camera_height, not to the shared surface-collision implementation.
 * The call-site observer is deliberately internal to the native route probe;
 * it does not provide a synthetic query or a fallback answer.
 */
#define SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_IDENTITY \
    "src/game/camera.c:788:set_camera_height:find_floor"
#define SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_SHARD_ID UINT64_C(0x1e3500f9eb2b95d4)
#define SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_INPUT_SEED UINT64_C(0xe5c3d109a64f58ac)
#define SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_SAVE_SEED UINT64_C(0xb647ca9016af2cd5)
#define SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_SUBJECT_ID UINT64_C(0x6d4214ffe9a98a9a)
#define SM64_MODERN_CAMERA_FIND_FLOOR_ROUTE_FLAG UINT32_C(0x43414d37)

typedef struct SM64ModernCameraFindFloorRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t subject_id;
    uint32_t x_bits;
    uint32_t y_bits;
    uint32_t z_bits;
    uint32_t height_bits;
    uint32_t surface_present;
    uint32_t surface_type;
    uint32_t normal_y_bits;
    uint32_t origin_offset_bits;
    uint64_t source_identity;
    SM64ModernStatus observe_status;
} SM64ModernCameraFindFloorRouteReceiptV1;

void sm64_modern_camera_find_floor_route_reset(void);
SM64ModernStatus sm64_modern_camera_find_floor_route_observe(
    float x,
    float y,
    float z,
    float height,
    const struct Surface *surface);
uint64_t sm64_modern_camera_find_floor_route_invocations(void);
const SM64ModernCameraFindFloorRouteReceiptV1 *
sm64_modern_camera_find_floor_route_last_receipt(void);

#endif
