#ifndef SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_IDENTITY_H
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * Phase 85bk is bound to the source-authored castle interior leaf referenced
 * by inside_castle_seg7_dl_07028FD0.  The leaf remains a static source
 * object; the model translation unit exposes only this C-side accessor so
 * the route can copy normalized values before Swift sees them.
 */
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_SHARD_ID UINT64_C(0x00a5aebe36897ac4)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_INPUT_SEED UINT64_C(0x38ed06da4fa1b69c)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_SAVE_SEED UINT64_C(0x7684a9567f71ff45)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_SOURCE_ID UINT64_C(0xea260066b29ece0c)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_OWNER_ID UINT64_C(0xad524f68d4a58ea8)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_EVENT UINT64_C(0xd2)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_WORD_CAPACITY 8u
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_FLAG_SCENE_GRAPH_OWNER UINT32_C(1)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_FLAG_POINTERS_NORMALIZED UINT32_C(2)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_TEXTURE_RESOURCE_ID UINT32_C(0x09001000)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_LIGHT_RESOURCE_ID UINT32_C(0x07024020)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_AMBIENT_RESOURCE_ID UINT32_C(0x07024010)
#define SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_VERTEX_RESOURCE_ID UINT32_C(0x07026108)

typedef struct SM64ModernDisplayListNextRoutePacketV1 {
    SM64ModernAbiHeader header;
    uint64_t source_identity;
    uint64_t owner_identity;
    uint64_t packet_fingerprint;
    uint32_t word_count;
    uint32_t drawing_layer;
    uint32_t triangle_count;
    uint32_t flags;
    uint32_t words[SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_WORD_CAPACITY * 2u];
    uint32_t resource_ids[SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_WORD_CAPACITY];
} SM64ModernDisplayListNextRoutePacketV1;

void sm64_modern_display_list_next_route_reset(void);

SM64ModernStatus sm64_modern_display_list_next_route_observe_scene_graph_append(
    const void *display_list,
    uint32_t drawing_layer);

uint32_t sm64_modern_display_list_next_route_invocations(void);
uint32_t sm64_modern_display_list_next_route_matches(void);
const SM64ModernDisplayListNextRoutePacketV1 *
sm64_modern_display_list_next_route_last_packet(void);

#endif
