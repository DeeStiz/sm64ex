#include <stdbool.h>
#include <string.h>

#ifndef _LANGUAGE_C
#define _LANGUAGE_C
#endif
#ifndef F3DEX_GBI_2E
#define F3DEX_GBI_2E
#endif
#include <PR/gbi.h>

#include "actors/common1.h"
#include "pc/sm64_modern_display_list_door_route_identity.h"

/*
 * The selected leaf is reached by the far-range branch of wooden_door_geo:
 * wooden_door_geo -> door_seg3_dl_03014F98 -> door_seg3_dl_03014EF0.
 * Keep this observer at the existing scene-graph owner boundary and never
 * expose the source display-list pointer to the Swift side.
 */
static SM64ModernDisplayListDoorRoutePacketV1 sLastPacket;
static uint32_t sInvocations;
static uint32_t sMatches;

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (uint32_t byte = 0; byte < 4u; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8u)) & 0xffu);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_words(const uint32_t *words, uint32_t word_count) {
    uint64_t hash = UINT64_C(1469598103934665603);
    for (uint32_t index = 0; index < word_count; ++index) {
        hash = hash_u32(hash, words[index]);
    }
    return hash;
}

static bool target_parent_is_authored(const void *display_list) {
    return display_list == (const void *) door_seg3_dl_03014F98;
}

static bool parent_references_target_leaf(const Gfx *parent) {
    const uint32_t target_address = (uint32_t) (uintptr_t) door_seg3_dl_03014EF0;
    for (uint32_t index = 0; index < 64u; ++index) {
        const uint32_t word0 = parent[index].words.w0;
        const uint32_t word1 = parent[index].words.w1;
        const uint8_t opcode = (uint8_t) (word0 >> 24);
        if (opcode == G_ENDDL) {
            return false;
        }
        if (opcode == G_DL && word1 == target_address) {
            return true;
        }
    }
    return false;
}

static SM64ModernStatus copy_target_leaf(
    SM64ModernDisplayListDoorRoutePacketV1 *packet,
    uint32_t drawing_layer) {
    const Gfx *leaf = door_seg3_dl_03014EF0;
    uint32_t normalized_words[
        SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_WORD_CAPACITY * 2u] = {0};
    uint32_t resource_ids[SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_WORD_CAPACITY] = {0};
    uint32_t word_count = 0;
    uint32_t triangle_count = 0;
    bool saw_end = false;

    for (uint32_t index = 0;
         index < SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_WORD_CAPACITY;
         ++index) {
        const uint32_t word0 = leaf[index].words.w0;
        const uint32_t word1 = leaf[index].words.w1;
        const uint8_t opcode = (uint8_t) (word0 >> 24);
        uint32_t normalized_word1 = word1;
        uint32_t resource_id = 0;

        switch (index) {
            case 0u:
                if (opcode != G_MOVEMEM) {
                    return SM64_MODERN_STATUS_PARITY_DIVERGED;
                }
                normalized_word1 = SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_LIGHT_RESOURCE_ID;
                resource_id = normalized_word1;
                break;
            case 1u:
                if (opcode != G_MOVEMEM) {
                    return SM64_MODERN_STATUS_PARITY_DIVERGED;
                }
                normalized_word1 = SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_AMBIENT_RESOURCE_ID;
                resource_id = normalized_word1;
                break;
            case 2u:
                if (opcode != G_VTX) {
                    return SM64_MODERN_STATUS_PARITY_DIVERGED;
                }
                normalized_word1 = SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_VERTEX_RESOURCE_ID;
                resource_id = normalized_word1;
                break;
            case 3u:
            case 4u:
                if (opcode != G_TRI2) {
                    return SM64_MODERN_STATUS_PARITY_DIVERGED;
                }
                triangle_count += 2u;
                break;
            case 5u:
                if (opcode != G_ENDDL) {
                    return SM64_MODERN_STATUS_PARITY_DIVERGED;
                }
                saw_end = true;
                word_count = index + 1u;
                normalized_words[index * 2u] = word0;
                normalized_words[index * 2u + 1u] = normalized_word1;
                resource_ids[index] = resource_id;
                break;
            default:
                return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }

        normalized_words[index * 2u] = word0;
        normalized_words[index * 2u + 1u] = normalized_word1;
        resource_ids[index] = resource_id;

        if (saw_end) {
            break;
        }
    }

    if (!saw_end || word_count != 6u || triangle_count != 4u) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    memset(packet, 0, sizeof(*packet));
    packet->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    packet->header.struct_size = sizeof(*packet);
    packet->source_identity = SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_SOURCE_ID;
    packet->owner_identity = SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_OWNER_ID;
    packet->word_count = word_count;
    packet->drawing_layer = drawing_layer;
    packet->triangle_count = triangle_count;
    packet->flags = SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_FLAG_SCENE_GRAPH_OWNER
        | SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_FLAG_POINTERS_NORMALIZED;
    memcpy(packet->words, normalized_words, sizeof(normalized_words));
    memcpy(packet->resource_ids, resource_ids, sizeof(resource_ids));
    packet->packet_fingerprint = hash_words(normalized_words, word_count * 2u);
    return SM64_MODERN_STATUS_OK;
}

static uint64_t resource_fingerprint(
    const SM64ModernDisplayListDoorRoutePacketV1 *packet) {
    return hash_words(packet->resource_ids, packet->word_count);
}

void sm64_modern_display_list_door_route_reset(void) {
    memset(&sLastPacket, 0, sizeof(sLastPacket));
    sInvocations = 0;
    sMatches = 0;
}

SM64ModernStatus sm64_modern_display_list_door_route_observe_scene_graph_append(
    const void *display_list,
    uint32_t drawing_layer) {
    sInvocations++;
    if (!target_parent_is_authored(display_list)) {
        return SM64_MODERN_STATUS_OK;
    }
    if (!parent_references_target_leaf((const Gfx *) display_list)) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    SM64ModernStatus status = copy_target_leaf(&sLastPacket, drawing_layer);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    sMatches++;

    if (!sm64_modern_oracle_trace_is_active()) {
        return SM64_MODERN_STATUS_OK;
    }

    const uint64_t values[8] = {
        sLastPacket.source_identity,
        sLastPacket.owner_identity,
        sLastPacket.packet_fingerprint,
        sLastPacket.word_count,
        sLastPacket.triangle_count,
        resource_fingerprint(&sLastPacket),
        sLastPacket.drawing_layer,
        sLastPacket.flags,
    };
    return sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_RENDER,
        SM64_MODERN_ORACLE_RECORD_RENDER_PACKET,
        SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_SHARD_ID,
        SM64_MODERN_DISPLAY_LIST_DOOR_ROUTE_EVENT,
        sLastPacket.flags,
        values,
        8u);
}

uint32_t sm64_modern_display_list_door_route_invocations(void) {
    return sInvocations;
}

uint32_t sm64_modern_display_list_door_route_matches(void) {
    return sMatches;
}

const SM64ModernDisplayListDoorRoutePacketV1 *
sm64_modern_display_list_door_route_last_packet(void) {
    return &sLastPacket;
}
