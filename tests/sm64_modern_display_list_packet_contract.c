#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define COMMAND_CAPACITY 64u
#define TILE_CAPACITY 8u
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

enum command_kind {
    KIND_UNKNOWN = 0,
    KIND_NOOP = 1,
    KIND_VERTEX = 2,
    KIND_MODIFY_VERTEX = 3,
    KIND_CULL_DISPLAY_LIST = 4,
    KIND_BRANCH_Z = 5,
    KIND_TRIANGLE_1 = 6,
    KIND_TRIANGLE_2 = 7,
    KIND_QUAD = 8,
    KIND_LINE_3D = 9,
    KIND_SPECIAL_3 = 10,
    KIND_SPECIAL_2 = 11,
    KIND_SPECIAL_1 = 12,
    KIND_DMA_IO = 13,
    KIND_TEXTURE = 14,
    KIND_POP_MATRIX = 15,
    KIND_GEOMETRY_MODE = 16,
    KIND_MATRIX = 17,
    KIND_MOVE_WORD = 18,
    KIND_MOVE_MEMORY = 19,
    KIND_DISPLAY_LIST = 20,
    KIND_LOAD_UCODE = 21,
    KIND_SP_NOOP = 22,
    KIND_RDP_HALF_1 = 23,
    KIND_OTHER_MODE_LOW = 24,
    KIND_OTHER_MODE_HIGH = 25,
    KIND_END_DISPLAY_LIST = 26,
    KIND_RDP_HALF_2 = 27,
    KIND_SET_COLOR_IMAGE = 28,
    KIND_SET_DEPTH_IMAGE = 29,
    KIND_SET_TEXTURE_IMAGE = 30,
    KIND_SET_COMBINE = 31,
    KIND_SET_ENVIRONMENT_COLOR = 32,
    KIND_SET_PRIMITIVE_COLOR = 33,
    KIND_SET_BLEND_COLOR = 34,
    KIND_SET_FOG_COLOR = 35,
    KIND_SET_FILL_COLOR = 36,
    KIND_FILL_RECTANGLE = 37,
    KIND_SET_TILE = 38,
    KIND_LOAD_TILE = 39,
    KIND_LOAD_BLOCK = 40,
    KIND_SET_TILE_SIZE = 41,
    KIND_LOAD_TLUT = 42,
    KIND_RDP_SET_OTHER_MODE = 43,
    KIND_SET_PRIMITIVE_DEPTH = 44,
    KIND_SET_SCISSOR = 45,
    KIND_SET_CONVERT = 46,
    KIND_SET_KEY_R = 47,
    KIND_SET_KEY_GB = 48,
    KIND_FULL_SYNC = 49,
    KIND_TILE_SYNC = 50,
    KIND_PIPE_SYNC = 51,
    KIND_LOAD_SYNC = 52,
    KIND_TEXTURE_RECTANGLE_FLIP = 53,
    KIND_TEXTURE_RECTANGLE = 54,
    KIND_RENDER_LAYER = 55,
};

struct state {
    uint32_t geometry_mode;
    uint32_t texture_scale_s;
    uint32_t texture_scale_t;
    uint32_t texture_tile;
    uint32_t texture_level;
    uint32_t texture_enabled;
    uint32_t other_mode_high;
    uint32_t other_mode_low;
    uint32_t combine_high;
    uint32_t combine_low;
    uint32_t color_image_resource_id;
    uint32_t depth_image_resource_id;
    uint32_t texture_image_resource_id;
    uint32_t environment_color;
    uint32_t primitive_color;
    uint32_t blend_color;
    uint32_t fog_color;
    uint32_t fill_color;
    uint32_t scissor_x;
    uint32_t scissor_y;
    uint32_t scissor_lrx;
    uint32_t scissor_lry;
    uint32_t scissor_mode;
    uint32_t scissor_set;
    uint32_t viewport_resource_id;
    uint32_t viewport_offset;
    uint32_t light_count;
    uint32_t fog_mode;
    uint32_t render_layer;
    uint32_t matrix_depth;
    uint32_t vertex_resource_id;
    uint32_t tile_words0[TILE_CAPACITY];
    uint32_t tile_words1[TILE_CAPACITY];
};

struct command {
    uint32_t index;
    uint8_t opcode;
    uint8_t kind;
    uint32_t word0;
    uint32_t word1;
    uint32_t argument0;
    uint32_t argument1;
    uint32_t argument2;
    uint32_t resource_id;
    struct state state;
};

struct draw {
    uint32_t command_index;
    uint8_t primitive;
    uint32_t render_layer;
    uint32_t vertex_resource_id;
    uint32_t triangle_count;
    struct state state;
};

struct packet {
    uint64_t sequence;
    struct command commands[COMMAND_CAPACITY];
    uint32_t command_count;
    struct draw draws[COMMAND_CAPACITY];
    uint32_t draw_count;
    struct state state;
    uint32_t saw_end;
    uint32_t truncated;
    uint32_t unsupported_count;
};

struct words {
    uint32_t word0;
    uint32_t word1;
};

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (uint32_t shift = 0; shift <= 24; shift += 8) {
        hash ^= ((uint64_t)value >> shift) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_state(const struct state *state) {
    const uint32_t values[] = {
        state->geometry_mode,
        state->texture_scale_s,
        state->texture_scale_t,
        state->texture_tile,
        state->texture_level,
        state->texture_enabled,
        state->other_mode_high,
        state->other_mode_low,
        state->combine_high,
        state->combine_low,
        state->color_image_resource_id,
        state->depth_image_resource_id,
        state->texture_image_resource_id,
        state->environment_color,
        state->primitive_color,
        state->blend_color,
        state->fog_color,
        state->fill_color,
        state->scissor_x,
        state->scissor_y,
        state->scissor_lrx,
        state->scissor_lry,
        state->scissor_mode,
        state->scissor_set,
        state->viewport_resource_id,
        state->viewport_offset,
        state->light_count,
        state->fog_mode,
        state->render_layer,
        state->matrix_depth,
        state->vertex_resource_id,
    };
    uint64_t hash = FNV_OFFSET;
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u32(hash, values[index]);
    }
    for (size_t index = 0; index < TILE_CAPACITY; ++index) {
        hash = hash_u32(hash, state->tile_words0[index]);
    }
    for (size_t index = 0; index < TILE_CAPACITY; ++index) {
        hash = hash_u32(hash, state->tile_words1[index]);
    }
    return hash;
}

static uint8_t kind_for_opcode(uint8_t opcode) {
    switch (opcode) {
        case 0x00: return KIND_NOOP;
        case 0x01: return KIND_VERTEX;
        case 0x02: return KIND_MODIFY_VERTEX;
        case 0x03: return KIND_CULL_DISPLAY_LIST;
        case 0x04: return KIND_BRANCH_Z;
        case 0x05: return KIND_TRIANGLE_1;
        case 0x06: return KIND_TRIANGLE_2;
        case 0x07: return KIND_QUAD;
        case 0x08: return KIND_LINE_3D;
        case 0xd3: return KIND_SPECIAL_3;
        case 0xd4: return KIND_SPECIAL_2;
        case 0xd5: return KIND_SPECIAL_1;
        case 0xd6: return KIND_DMA_IO;
        case 0xd7: return KIND_TEXTURE;
        case 0xd8: return KIND_POP_MATRIX;
        case 0xd9: return KIND_GEOMETRY_MODE;
        case 0xda: return KIND_MATRIX;
        case 0xdb: return KIND_MOVE_WORD;
        case 0xdc: return KIND_MOVE_MEMORY;
        case 0xdd: return KIND_LOAD_UCODE;
        case 0xde: return KIND_DISPLAY_LIST;
        case 0xdf: return KIND_END_DISPLAY_LIST;
        case 0xe0: return KIND_SP_NOOP;
        case 0xe1: return KIND_RDP_HALF_1;
        case 0xe2: return KIND_OTHER_MODE_LOW;
        case 0xe3: return KIND_OTHER_MODE_HIGH;
        case 0xe4: return KIND_TEXTURE_RECTANGLE;
        case 0xe5: return KIND_TEXTURE_RECTANGLE_FLIP;
        case 0xe6: return KIND_LOAD_SYNC;
        case 0xe7: return KIND_PIPE_SYNC;
        case 0xe8: return KIND_TILE_SYNC;
        case 0xe9: return KIND_FULL_SYNC;
        case 0xea: return KIND_SET_KEY_GB;
        case 0xeb: return KIND_SET_KEY_R;
        case 0xec: return KIND_SET_CONVERT;
        case 0xed: return KIND_SET_SCISSOR;
        case 0xee: return KIND_SET_PRIMITIVE_DEPTH;
        case 0xef: return KIND_RDP_SET_OTHER_MODE;
        case 0xf0: return KIND_LOAD_TLUT;
        case 0xf1: return KIND_RDP_HALF_2;
        case 0xf2: return KIND_SET_TILE_SIZE;
        case 0xf3: return KIND_LOAD_BLOCK;
        case 0xf4: return KIND_LOAD_TILE;
        case 0xf5: return KIND_SET_TILE;
        case 0xf6: return KIND_FILL_RECTANGLE;
        case 0xf7: return KIND_SET_FILL_COLOR;
        case 0xf8: return KIND_SET_FOG_COLOR;
        case 0xf9: return KIND_SET_BLEND_COLOR;
        case 0xfa: return KIND_SET_PRIMITIVE_COLOR;
        case 0xfb: return KIND_SET_ENVIRONMENT_COLOR;
        case 0xfc: return KIND_SET_COMBINE;
        case 0xfd: return KIND_SET_TEXTURE_IMAGE;
        case 0xfe: return KIND_SET_DEPTH_IMAGE;
        case 0xff: return KIND_SET_COLOR_IMAGE;
        default: return KIND_UNKNOWN;
    }
}

static void append_command(struct packet *packet, uint8_t opcode, uint8_t kind,
                           uint32_t word0, uint32_t word1) {
    if (packet->command_count >= COMMAND_CAPACITY) {
        packet->truncated = 1;
        return;
    }

    struct command command;
    memset(&command, 0, sizeof(command));
    command.index = packet->command_count;
    command.opcode = opcode;
    command.kind = kind;
    command.word0 = word0;
    command.word1 = word1;

    switch (kind) {
        case KIND_GEOMETRY_MODE:
            packet->state.geometry_mode = (packet->state.geometry_mode & (word0 & UINT32_C(0x00ffffff))) | word1;
            command.argument0 = word0 & UINT32_C(0x00ffffff);
            command.argument1 = word1;
            break;
        case KIND_TEXTURE:
            packet->state.texture_scale_s = word1 >> 16;
            packet->state.texture_scale_t = word1 & UINT32_C(0xffff);
            packet->state.texture_tile = (word0 >> 8) & UINT32_C(0x7);
            packet->state.texture_level = (word0 >> 11) & UINT32_C(0x7);
            packet->state.texture_enabled = (word0 >> 1) & UINT32_C(0x7f);
            command.argument0 = packet->state.texture_tile;
            command.argument1 = packet->state.texture_level;
            command.argument2 = packet->state.texture_enabled;
            break;
        case KIND_MATRIX:
            command.resource_id = word1;
            command.argument0 = (word0 >> 19) & UINT32_C(0x1f);
            if ((word0 & UINT32_C(0xff)) & UINT32_C(0x1)) packet->state.matrix_depth += 1;
            break;
        case KIND_POP_MATRIX: {
            uint32_t count = (word0 >> 19) & UINT32_C(0x1f);
            command.argument0 = count > 1 ? count : 1;
            packet->state.matrix_depth = packet->state.matrix_depth >= command.argument0
                ? packet->state.matrix_depth - command.argument0 : 0;
            break;
        }
        case KIND_MOVE_MEMORY: {
            const uint32_t index = word0 & UINT32_C(0xff);
            const uint32_t offset = (word0 >> 8) & UINT32_C(0xff);
            command.argument0 = index;
            command.argument1 = offset;
            command.resource_id = word1;
            if (index == 8) {
                packet->state.viewport_resource_id = word1;
                packet->state.viewport_offset = offset;
            } else if (index == 10) {
                const uint32_t count = offset / 24;
                if (count > packet->state.light_count) packet->state.light_count = count;
            }
            break;
        }
        case KIND_MOVE_WORD: {
            const uint32_t index = (word0 >> 16) & UINT32_C(0xff);
            const uint32_t offset = word0 & UINT32_C(0xffff);
            command.argument0 = index;
            command.argument1 = offset;
            command.argument2 = word1;
            if (index == 2) packet->state.light_count = word1;
            if (index == 8) packet->state.fog_mode = word1;
            break;
        }
        case KIND_VERTEX:
            command.resource_id = word1;
            command.argument0 = (word0 >> 12) & UINT32_C(0xff);
            command.argument1 = (word0 >> 1) & UINT32_C(0x7f);
            packet->state.vertex_resource_id = word1;
            break;
        case KIND_DISPLAY_LIST:
            command.resource_id = word1;
            command.argument0 = word0 & UINT32_C(0xff);
            break;
        case KIND_BRANCH_Z:
            command.resource_id = word1;
            command.argument0 = (word0 >> 12) & UINT32_C(0xfff);
            command.argument1 = word0 & UINT32_C(0xfff);
            command.argument2 = word1;
            break;
        case KIND_TRIANGLE_1:
            command.argument0 = (word1 >> 16) & UINT32_C(0xff);
            command.argument1 = (word1 >> 8) & UINT32_C(0xff);
            command.argument2 = word1 & UINT32_C(0xff);
            break;
        case KIND_TRIANGLE_2:
            command.argument0 = (word0 >> 16) & UINT32_C(0xff);
            command.argument1 = (word0 >> 8) & UINT32_C(0xff);
            command.argument2 = word1;
            break;
        case KIND_OTHER_MODE_HIGH:
            packet->state.other_mode_high = word1;
            command.argument0 = (word0 >> 8) & UINT32_C(0xff);
            command.argument1 = word1;
            break;
        case KIND_OTHER_MODE_LOW:
        case KIND_RDP_SET_OTHER_MODE:
            packet->state.other_mode_low = word1;
            packet->state.render_layer = (word1 >> 16) & UINT32_C(0xff);
            command.argument0 = (word0 >> 8) & UINT32_C(0xff);
            command.argument1 = word1;
            break;
        case KIND_SET_COLOR_IMAGE:
            packet->state.color_image_resource_id = word1;
            command.resource_id = word1;
            break;
        case KIND_SET_DEPTH_IMAGE:
            packet->state.depth_image_resource_id = word1;
            command.resource_id = word1;
            break;
        case KIND_SET_TEXTURE_IMAGE:
            packet->state.texture_image_resource_id = word1;
            command.resource_id = word1;
            break;
        case KIND_SET_COMBINE:
            packet->state.combine_high = word0 & UINT32_C(0x00ffffff);
            packet->state.combine_low = word1;
            command.argument0 = word0 & UINT32_C(0x00ffffff);
            command.argument1 = word1;
            break;
        case KIND_SET_ENVIRONMENT_COLOR: packet->state.environment_color = word1; break;
        case KIND_SET_PRIMITIVE_COLOR: packet->state.primitive_color = word1; break;
        case KIND_SET_BLEND_COLOR: packet->state.blend_color = word1; break;
        case KIND_SET_FOG_COLOR: packet->state.fog_color = word1; break;
        case KIND_SET_FILL_COLOR: packet->state.fill_color = word1; break;
        case KIND_SET_SCISSOR:
            packet->state.scissor_x = (word0 >> 12) & UINT32_C(0xfff);
            packet->state.scissor_y = word0 & UINT32_C(0xfff);
            packet->state.scissor_lrx = (word1 >> 12) & UINT32_C(0xfff);
            packet->state.scissor_lry = word1 & UINT32_C(0xfff);
            packet->state.scissor_mode = (word1 >> 24) & UINT32_C(0x3);
            packet->state.scissor_set = 1;
            break;
        case KIND_SET_TILE:
        case KIND_LOAD_TILE:
        case KIND_LOAD_BLOCK:
        case KIND_SET_TILE_SIZE: {
            const uint32_t tile = (word1 >> 24) & UINT32_C(0x7);
            command.argument0 = tile;
            if (tile < TILE_CAPACITY) {
                packet->state.tile_words0[tile] = word0;
                packet->state.tile_words1[tile] = word1;
            }
            break;
        }
        case KIND_RENDER_LAYER:
            packet->state.render_layer = word0;
            command.argument0 = word0;
            break;
        case KIND_END_DISPLAY_LIST:
            packet->saw_end = 1;
            break;
        case KIND_FILL_RECTANGLE:
        case KIND_TEXTURE_RECTANGLE:
        case KIND_TEXTURE_RECTANGLE_FLIP:
            command.argument0 = word0 & UINT32_C(0x00ffffff);
            command.argument1 = word1;
            break;
        case KIND_UNKNOWN:
            packet->unsupported_count += 1;
            break;
        default:
            break;
    }

    command.state = packet->state;
    packet->commands[packet->command_count++] = command;

    uint32_t triangle_count = 0;
    if (kind == KIND_TRIANGLE_1 || kind == KIND_LINE_3D || kind == KIND_TEXTURE_RECTANGLE
        || kind == KIND_TEXTURE_RECTANGLE_FLIP || kind == KIND_FILL_RECTANGLE) {
        triangle_count = 1;
    } else if (kind == KIND_TRIANGLE_2 || kind == KIND_QUAD) {
        triangle_count = 2;
    }
    if (triangle_count > 0 && packet->draw_count < COMMAND_CAPACITY) {
        struct draw draw;
        memset(&draw, 0, sizeof(draw));
        draw.command_index = command.index;
        draw.primitive = kind;
        draw.render_layer = packet->state.render_layer;
        draw.vertex_resource_id = packet->state.vertex_resource_id;
        draw.triangle_count = triangle_count;
        draw.state = packet->state;
        packet->draws[packet->draw_count++] = draw;
    }
}

static uint64_t hash_packet(const struct packet *packet) {
    uint64_t hash = hash_u64(FNV_OFFSET, packet->sequence);
    hash = hash_u32(hash, packet->command_count);
    for (uint32_t index = 0; index < packet->command_count; ++index) {
        const struct command *command = &packet->commands[index];
        hash = hash_u32(hash, command->index);
        hash = hash_u32(hash, command->opcode);
        hash = hash_u32(hash, command->kind);
        hash = hash_u32(hash, command->word0);
        hash = hash_u32(hash, command->word1);
        hash = hash_u32(hash, command->argument0);
        hash = hash_u32(hash, command->argument1);
        hash = hash_u32(hash, command->argument2);
        hash = hash_u32(hash, command->resource_id);
        hash = hash_u64(hash, hash_state(&command->state));
    }
    hash = hash_u32(hash, packet->draw_count);
    for (uint32_t index = 0; index < packet->draw_count; ++index) {
        const struct draw *draw = &packet->draws[index];
        hash = hash_u32(hash, draw->command_index);
        hash = hash_u32(hash, draw->primitive);
        hash = hash_u32(hash, draw->render_layer);
        hash = hash_u32(hash, draw->vertex_resource_id);
        hash = hash_u32(hash, draw->triangle_count);
        hash = hash_u64(hash, hash_state(&draw->state));
    }
    hash = hash_u64(hash, hash_state(&packet->state));
    hash = hash_u32(hash, packet->saw_end && !packet->truncated ? 1 : 0);
    hash = hash_u32(hash, packet->truncated ? 1 : 0);
    return hash_u32(hash, packet->unsupported_count);
}

static const struct words fixture[] = {
    { UINT32_C(0xda000001), UINT32_C(0x00001000) },
    { UINT32_C(0xd9ffffff), UINT32_C(0x00000400) },
    { UINT32_C(0xd7ab1234), UINT32_C(0x10002000) },
    { UINT32_C(0xdb020000), UINT32_C(0x00000003) },
    { UINT32_C(0xdb080000), UINT32_C(0x00000099) },
    { UINT32_C(0xdc000808), UINT32_C(0x00002040) },
    { UINT32_C(0xdc00300a), UINT32_C(0x00003050) },
    { UINT32_C(0xfc123456), UINT32_C(0x789abcde) },
    { UINT32_C(0xed001002), UINT32_C(0x01003004) },
    { UINT32_C(0xff000000), UINT32_C(0x00001111) },
    { UINT32_C(0xfe000000), UINT32_C(0x00002222) },
    { UINT32_C(0xfd000000), UINT32_C(0x00003333) },
    { UINT32_C(0xf5000000), UINT32_C(0x02001234) },
    { UINT32_C(0xf2000000), UINT32_C(0x02005678) },
    { UINT32_C(0xfb000000), UINT32_C(0x01020304) },
    { UINT32_C(0xfa000000), UINT32_C(0x11223344) },
    { UINT32_C(0xf9000000), UINT32_C(0x55667788) },
    { UINT32_C(0xf8000000), UINT32_C(0x99aabbcc) },
    { UINT32_C(0xf7000000), UINT32_C(0xddeeff00) },
    { UINT32_C(0xe3000010), UINT32_C(0x01020304) },
    { UINT32_C(0xe2000018), UINT32_C(0x00070000) },
    { UINT32_C(0x01123456), UINT32_C(0x00004444) },
    { UINT32_C(0x05000000), UINT32_C(0x000a141e) },
    { UINT32_C(0x060a141e), UINT32_C(0x0028323c) },
    { UINT32_C(0x08000000), UINT32_C(0x00010203) },
    { UINT32_C(0xf6000000), UINT32_C(0x00040506) },
    { UINT32_C(0xe4000000), UINT32_C(0x00070809) },
    { UINT32_C(0xe5000000), UINT32_C(0x000a0b0c) },
    { UINT32_C(0xde000001), UINT32_C(0x00005555) },
    { UINT32_C(0x04100203), UINT32_C(0x00006666) },
    { UINT32_C(0xaa000000), UINT32_C(0x00007777) },
    { UINT32_C(0xdf000000), UINT32_C(0x00000000) },
};

int main(void) {
    struct packet packet;
    memset(&packet, 0, sizeof(packet));
    packet.sequence = 7;
    for (size_t index = 0; index < sizeof(fixture) / sizeof(fixture[0]); ++index) {
        append_command(&packet, (uint8_t)(fixture[index].word0 >> 24),
                       kind_for_opcode((uint8_t)(fixture[index].word0 >> 24)),
                       fixture[index].word0, fixture[index].word1);
    }
    append_command(&packet, 0, KIND_RENDER_LAYER, 9, 0);

    if (packet.command_count != 33 || packet.draw_count != 6 || !packet.saw_end
        || packet.truncated || packet.unsupported_count != 1
        || packet.state.render_layer != 9 || packet.state.light_count != 3
        || packet.state.fog_mode != 0x99 || packet.state.viewport_resource_id != 0x2040
        || packet.state.texture_image_resource_id != 0x3333) {
        fprintf(stderr, "display-list C fixture state mismatch\n");
        return 1;
    }

    printf("displayListPacketFingerprint=0x%llx\n",
           (unsigned long long)hash_packet(&packet));
    printf("SM64 Modern display-list packet C contract passed\n");
    return 0;
}
