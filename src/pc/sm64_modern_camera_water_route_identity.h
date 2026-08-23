#ifndef SM64_MODERN_CAMERA_WATER_ROUTE_IDENTITY_H
#define SM64_MODERN_CAMERA_WATER_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/* Private helper declaration; the public ABI remains unchanged by this route. */
uint32_t sm64_modern_oracle_trace_next_sequence(
    SM64ModernOracleTraceDomain domain);

/*
 * This identity belongs to the source-owned camera callback boundary.  The
 * shared find_water_level collision observer remains generic and is not
 * relabelled by this route.
 */
#define SM64_MODERN_CAMERA_WATER_ROUTE_IDENTITY \
    "src/game/camera.c:2471:sm64_modern_camera_evaluate_callback:find_water_level"
#define SM64_MODERN_CAMERA_WATER_ROUTE_SUBJECT_ID \
    UINT64_C(0x340565d4295ea359)
#define SM64_MODERN_CAMERA_WATER_ROUTE_FLAG UINT32_C(0x43414d57)
#define SM64_MODERN_CAMERA_WATER_ROUTE_FLAG_QUERY_EXECUTED UINT32_C(1u << 0)
#define SM64_MODERN_CAMERA_WATER_ROUTE_FLAG_HAS_HEIGHT UINT32_C(1u << 1)

/*
 * The receipt is an internal diagnostic copy of the exact fixed-width values
 * sent to schema 4.  It deliberately contains no pointers or public ABI
 * fields beyond the ordinary v1 header.
 */
typedef struct SM64ModernCameraWaterRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t sequence;
    uint32_t mode_bits;
    uint32_t level_bits;
    uint32_t area_bits;
    uint32_t camera_x_bits;
    uint32_t camera_y_bits;
    uint32_t camera_z_bits;
    uint32_t mario_x_bits;
    uint32_t mario_y_bits;
    uint32_t mario_z_bits;
    uint32_t query_x_bits;
    uint32_t query_z_bits;
    uint32_t water_height_bits;
    uint32_t result_flags;
    uint64_t subject_id;
    uint64_t values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY];
    uint64_t canonical_hash;
    SM64ModernStatus observe_status;
} SM64ModernCameraWaterRouteReceiptV1;

void sm64_modern_camera_water_route_reset(void);
SM64ModernStatus sm64_modern_camera_water_route_observe(
    int16_t mode,
    int16_t level,
    int16_t area,
    float camera_x,
    float camera_y,
    float camera_z,
    float mario_x,
    float mario_y,
    float mario_z,
    float query_x,
    float query_z,
    float water_height,
    uint32_t result_flags);
uint64_t sm64_modern_camera_water_route_invocations(void);
const SM64ModernCameraWaterRouteReceiptV1 *
sm64_modern_camera_water_route_last_receipt(void);

#endif
