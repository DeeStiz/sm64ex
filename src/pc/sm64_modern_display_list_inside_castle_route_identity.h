#ifndef SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_IDENTITY_H
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * Phase 85bp is bound to the authored inside-castle area-2/3 leaf referenced
 * by inside_castle_seg7_dl_07043B48.  The scene-graph owner sees the parent;
 * this C-only seam copies the selected leaf and normalizes every pointer
 * operand before any value can be observed by Swift.
 */
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_SHARD_ID UINT64_C(0x009e431051dba428)
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_INPUT_SEED UINT64_C(0x14ecced311bcc690)
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_SAVE_SEED UINT64_C(0x2c483fa0516b9079)
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_SOURCE_ID UINT64_C(0x3362be6884c97a75)
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_OWNER_ID UINT64_C(0x12f674c2830304c8)
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_EVENT UINT64_C(0xd4)
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_WORD_CAPACITY 6u
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_FLAG_SCENE_GRAPH_OWNER UINT32_C(1)
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_FLAG_POINTERS_NORMALIZED UINT32_C(2)
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_TEXTURE_RESOURCE_ID UINT32_C(0x0900c800)
#define SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_VERTEX_RESOURCE_ID UINT32_C(0x070436c8)

typedef struct SM64ModernDisplayListInsideCastleRoutePacketV1 {
    SM64ModernAbiHeader header;
    uint64_t source_identity;
    uint64_t owner_identity;
    uint64_t packet_fingerprint;
    uint32_t word_count;
    uint32_t drawing_layer;
    uint32_t triangle_count;
    uint32_t flags;
    uint32_t words[SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_WORD_CAPACITY * 2u];
    uint32_t resource_ids[SM64_MODERN_DISPLAY_LIST_INSIDE_CASTLE_ROUTE_WORD_CAPACITY];
} SM64ModernDisplayListInsideCastleRoutePacketV1;

void sm64_modern_display_list_inside_castle_route_reset(void);

SM64ModernStatus sm64_modern_display_list_inside_castle_route_observe_scene_graph_append(
    const void *display_list,
    uint32_t drawing_layer);

uint32_t sm64_modern_display_list_inside_castle_route_invocations(void);
uint32_t sm64_modern_display_list_inside_castle_route_matches(void);
const SM64ModernDisplayListInsideCastleRoutePacketV1 *
sm64_modern_display_list_inside_castle_route_last_packet(void);

#endif
