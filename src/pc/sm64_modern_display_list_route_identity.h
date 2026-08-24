#ifndef SM64_MODERN_DISPLAY_LIST_ROUTE_IDENTITY_H
#define SM64_MODERN_DISPLAY_LIST_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/*
 * This route is bound to the source-authored leaf that is referenced by the
 * wooden-door actor display list.  The scene-graph owner observes the parent
 * list before it emits the G_DL command; the observer immediately copies the
 * leaf into a pointer-free packet.  No Gfx pointer or host address is exposed
 * through this header.
 */
#define SM64_MODERN_DISPLAY_LIST_ROUTE_SHARD_ID UINT64_C(0x00cab93b5dd94425)
#define SM64_MODERN_DISPLAY_LIST_ROUTE_INPUT_SEED UINT64_C(0x101f5dd7c1ad86c9)
#define SM64_MODERN_DISPLAY_LIST_ROUTE_SAVE_SEED UINT64_C(0x2593834295e68816)
#define SM64_MODERN_DISPLAY_LIST_ROUTE_SOURCE_ID UINT64_C(0x3f4261ff4f871037)
#define SM64_MODERN_DISPLAY_LIST_ROUTE_OWNER_ID UINT64_C(0x9f2ee294c18a11b4)
#define SM64_MODERN_DISPLAY_LIST_ROUTE_EVENT UINT64_C(0xd1)
#define SM64_MODERN_DISPLAY_LIST_ROUTE_WORD_CAPACITY 8u
#define SM64_MODERN_DISPLAY_LIST_ROUTE_FLAG_SCENE_GRAPH_OWNER UINT32_C(1)
#define SM64_MODERN_DISPLAY_LIST_ROUTE_FLAG_POINTERS_NORMALIZED UINT32_C(2)
#define SM64_MODERN_DISPLAY_LIST_ROUTE_VERTEX_RESOURCE_ID UINT32_C(0x03014658)

/*
 * Fixed-width packet retained only inside the C route harness.  The words are
 * copied from the live Gfx array and pointer-bearing operands are replaced by
 * their stable source resource IDs before this value can be observed by
 * Swift.  It is intentionally bounded to the selected leaf's four commands.
 */
typedef struct SM64ModernDisplayListRoutePacketV1 {
    SM64ModernAbiHeader header;
    uint64_t source_identity;
    uint64_t owner_identity;
    uint64_t packet_fingerprint;
    uint32_t word_count;
    uint32_t drawing_layer;
    uint32_t triangle_count;
    uint32_t flags;
    uint32_t words[SM64_MODERN_DISPLAY_LIST_ROUTE_WORD_CAPACITY * 2u];
    uint32_t resource_ids[SM64_MODERN_DISPLAY_LIST_ROUTE_WORD_CAPACITY];
} SM64ModernDisplayListRoutePacketV1;

void sm64_modern_display_list_route_reset(void);

/*
 * Called from the scene-graph append owner.  `display_list` is borrowed only
 * for the duration of this C-side identity check and packet copy.
 */
SM64ModernStatus sm64_modern_display_list_route_observe_scene_graph_append(
    const void *display_list,
    uint32_t drawing_layer);

uint32_t sm64_modern_display_list_route_invocations(void);
uint32_t sm64_modern_display_list_route_matches(void);
const SM64ModernDisplayListRoutePacketV1 *
sm64_modern_display_list_route_last_packet(void);

#endif
