#ifndef SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_IDENTITY_H
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * This route is bound to the source-authored wooden-door leaf used by the
 * far-range branch of the existing wooden_door_geo actor invocation.  The
 * scene-graph owner observes door_seg3_dl_03014F98 before it emits the raw
 * display-list command and copies only normalized fixed-width values.
 */
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_SHARD_ID UINT64_C(0x01b472aae4c4277d)
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_INPUT_SEED UINT64_C(0x192cd5d97bcd8e91)
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_SAVE_SEED UINT64_C(0x4e71a1f8ffe099ce)
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_SOURCE_ID UINT64_C(0x1b9a2dff3b0ba55f)
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_OWNER_ID UINT64_C(0x2e5648d8a494e1a1)
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_EVENT UINT64_C(0xd3)
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_WORD_CAPACITY 8u
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_FLAG_SCENE_GRAPH_OWNER UINT32_C(1)
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_FLAG_POINTERS_NORMALIZED UINT32_C(2)
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_LIGHT_RESOURCE_ID UINT32_C(0x03009CE0)
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_AMBIENT_RESOURCE_ID UINT32_C(0x03009CE8)
#define SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_VERTEX_RESOURCE_ID UINT32_C(0x03014DF0)

/*
 * Fixed-width, pointer-free receipt.  The source Gfx words are copied in C;
 * host pointers in MOVEMEM/VTX operands are replaced by their authored ROM
 * resource IDs before the receipt can reach Swift.
 */
typedef struct SM64ModernDisplayListDoorRoutePacketV1 {
    SM64ModernAbiHeader header;
    uint64_t source_identity;
    uint64_t owner_identity;
    uint64_t packet_fingerprint;
    uint32_t word_count;
    uint32_t drawing_layer;
    uint32_t triangle_count;
    uint32_t flags;
    uint32_t words[SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_WORD_CAPACITY * 2u];
    uint32_t resource_ids[SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_WORD_CAPACITY];
} SM64ModernDisplayListDoorRoutePacketV1;

void sm64_modern_display_list_door_route_reset(void);

/* Called only at the existing geo_append_display_list owner boundary. */
SM64ModernStatus sm64_modern_display_list_door_route_observe_scene_graph_append(
    const void *display_list,
    uint32_t drawing_layer);

uint32_t sm64_modern_display_list_door_route_invocations(void);
uint32_t sm64_modern_display_list_door_route_matches(void);
const SM64ModernDisplayListDoorRoutePacketV1 *
sm64_modern_display_list_door_route_last_packet(void);

#endif
