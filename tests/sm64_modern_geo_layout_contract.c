#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static unsigned physical_offset(unsigned logical) {
    return (logical & 3u) | ((logical & ~3u) << 1u);
}

static uint8_t read_u8(const uint8_t *bytes, int command, unsigned logical) {
    return bytes[command + physical_offset(logical)];
}

static int16_t read_s16(const uint8_t *bytes, int command, unsigned logical) {
    unsigned base = command + physical_offset(logical);
    uint16_t value = (uint16_t) bytes[base] | ((uint16_t) bytes[base + 1u] << 8u);
    return (int16_t) value;
}

static uint32_t read_u32(const uint8_t *bytes, int command, unsigned logical) {
    unsigned base = command + physical_offset(logical);
    return (uint32_t) bytes[base]
        | ((uint32_t) bytes[base + 1u] << 8u)
        | ((uint32_t) bytes[base + 2u] << 16u)
        | ((uint32_t) bytes[base + 3u] << 24u);
}

static uint64_t read_u64(const uint8_t *bytes, int command, unsigned logical) {
    unsigned base = command + physical_offset(logical);
    uint64_t value = 0;
    for (unsigned byte = 0; byte < 8; ++byte) value |= (uint64_t) bytes[base + byte] << (byte * 8u);
    return value;
}

static int byte_length(uint8_t opcode, uint8_t parameter) {
    switch (opcode) {
        case 0x00: case 0x02: return 16;
        case 0x01: case 0x03: case 0x04: case 0x05: case 0x06: case 0x07:
        case 0x09: case 0x0b: case 0x0c: case 0x1b: case 0x17: case 0x20: return 8;
        case 0x08: return 24;
        case 0x0a: return parameter == 0 ? 16 : 24;
        case 0x0d: case 0x0e: return 16;
        case 0x0f: return 40;
        case 0x10: {
            unsigned layout = (parameter & 0x70u) >> 4u;
            unsigned base[] = { 32, 16, 16, 8 };
            return (int) base[layout > 3 ? 3 : layout] + ((parameter & 0x80u) ? 8 : 0);
        }
        case 0x11: case 0x12: case 0x14: return (parameter & 0x80u) ? 24 : 16;
        case 0x13: case 0x1c: return 24;
        case 0x15: case 0x16: case 0x18: case 0x19: return 16;
        case 0x1a: case 0x1e: return 16;
        case 0x1d: return (parameter & 0x80u) ? 24 : 16;
        case 0x1f: return 32;
        default: return 0;
    }
}

struct Node {
    uint16_t kind;
    int parent;
    int flags;
    int child_count;
    int children[8];
    int payload_kind;
    int64_t values[8];
    unsigned value_count;
    uint64_t pointer;
};

static int register_node(struct Node *nodes, int *node_count, int depth, int *at_depth,
                         uint16_t kind, int payload_kind, const int64_t *values, unsigned value_count,
                         uint64_t pointer) {
    int id = (*node_count)++;
    int parent = depth == 0 ? -1 : at_depth[depth - 1];
    nodes[id].kind = kind;
    nodes[id].parent = parent;
    nodes[id].flags = 0;
    nodes[id].child_count = 0;
    nodes[id].payload_kind = payload_kind;
    nodes[id].value_count = value_count;
    nodes[id].pointer = pointer;
    for (unsigned i = 0; i < value_count; ++i) nodes[id].values[i] = values[i];
    if (parent >= 0) nodes[parent].children[nodes[parent].child_count++] = id;
    at_depth[depth] = id;
    return id;
}

int main(void) {
    static const uint8_t program[] = {
        0x08,0x00,0x02,0x00,0,0,0,0, 0,0,0,0,0,0,0,0, 0x40,0x01,0xf0,0,0,0,0,0,
        0x04,0,0,0,0,0,0,0,
        0x0a,0,60,0,0,0,0,0, 100,0,0xe8,0x03,0,0,0,0,
        0x04,0,0,0,0,0,0,0,
        0x0f,0,1,0,0,0,0,0, 10,0,20,0,0,0,0,0, 30,0,0,0,0,0,0,0, 100,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
        0x05,0,0,0,0,0,0,0,
        0x10,0x03,0,0,0,0,0,0, 1,0,2,0,0,0,0,0, 3,0,4,0,0,0,0,0, 5,0,6,0,0,0,0,0,
        0x11,0x82,7,0,0,0,0,0, 8,0,9,0,0,0,0,0, 0x20,0x00,0x00,0x01,0,0,0,0,
        0x15,0x04,0,0,0,0,0,0, 0x30,0x00,0x00,0x01,0,0,0,0,
        0x1d,0x85,0,0,0,0,0,0, 0,0x80,0x01,0,0,0,0,0, 0x40,0x00,0x00,0x01,0,0,0,0,
        0x16,0,2,0,0,0,0,0, 200,0,64,0,0,0,0,0,
        0x05,0,0,0,0,0,0,0,
        0x07,1,0x34,0x12,0,0,0,0,
        0x06,0,0,0,0,0,0,0,
        0x01,0,0,0,0,0,0,0,
    };
    uint64_t command_hash = FNV_OFFSET;
    struct Node nodes[16] = { 0 };
    int at_depth[8] = { 0 };
    int depth = 0;
    int current = -1;
    int node_count = 0;
    int root = -1;
    int view0 = -1;
    for (int offset = 0; offset < (int) sizeof(program); ) {
        uint8_t opcode = program[offset];
        uint8_t parameter = program[offset + 1];
        int length = byte_length(opcode, parameter);
        if (length <= 0 || offset + length > (int) sizeof(program)) return 2;
        command_hash = hash_u64(command_hash, (uint64_t) offset);
        command_hash = hash_u64(command_hash, opcode);
        command_hash = hash_u64(command_hash, parameter);
        command_hash = hash_u64(command_hash, (uint64_t) length);
        int64_t values[8] = { 0 };
        uint64_t pointer = 0;
        int payload_kind = 0;
        switch (opcode) {
            case 0x08:
                values[0] = read_s16(program, offset, 2); values[1] = read_s16(program, offset, 4);
                values[2] = read_s16(program, offset, 6); values[3] = read_s16(program, offset, 8); values[4] = read_s16(program, offset, 10);
                payload_kind = 1; current = register_node(nodes, &node_count, depth, at_depth, 1, payload_kind, values, 5, 0); if (depth == 0) root = current; break;
            case 0x04: ++depth; at_depth[depth] = current; break;
            case 0x05: if (depth == 0) return 3; --depth; current = at_depth[depth]; break;
            case 0x0a:
                values[0] = read_s16(program, offset, 2); values[1] = read_s16(program, offset, 4); values[2] = read_s16(program, offset, 6); payload_kind = 2;
                current = register_node(nodes, &node_count, depth, at_depth, 3, payload_kind, values, 3, 0); break;
            case 0x0f:
                values[0] = read_s16(program, offset, 2); values[1] = read_s16(program, offset, 4); values[2] = read_s16(program, offset, 6); values[3] = read_s16(program, offset, 8);
                values[4] = read_s16(program, offset, 10); values[5] = read_s16(program, offset, 12); values[6] = read_s16(program, offset, 14); pointer = read_u64(program, offset, 16); payload_kind = 3;
                current = register_node(nodes, &node_count, depth, at_depth, 20, payload_kind, values, 7, pointer); break;
            case 0x10:
                values[0] = parameter & 0x0f; values[1] = read_s16(program, offset, 4); values[2] = read_s16(program, offset, 6); values[3] = read_s16(program, offset, 8);
                values[4] = read_s16(program, offset, 10); values[5] = read_s16(program, offset, 12); values[6] = read_s16(program, offset, 14); payload_kind = 4;
                current = register_node(nodes, &node_count, depth, at_depth, 21, payload_kind, values, 7, 0); break;
            case 0x11:
                values[0] = parameter & 0x0f; values[1] = read_s16(program, offset, 2); values[2] = read_s16(program, offset, 4); values[3] = read_s16(program, offset, 6); pointer = read_u64(program, offset, 8); payload_kind = 5;
                current = register_node(nodes, &node_count, depth, at_depth, 22, payload_kind, values, 4, pointer); break;
            case 0x15:
                values[0] = parameter; pointer = read_u64(program, offset, 4); payload_kind = 6;
                current = register_node(nodes, &node_count, depth, at_depth, 27, payload_kind, values, 1, pointer); break;
            case 0x1d:
                values[0] = parameter & 0x0f; values[1] = read_u32(program, offset, 4); pointer = read_u64(program, offset, 8); payload_kind = 7;
                current = register_node(nodes, &node_count, depth, at_depth, 28, payload_kind, values, 2, pointer); break;
            case 0x16:
                values[0] = (uint8_t) read_s16(program, offset, 2); values[1] = (uint8_t) read_s16(program, offset, 4); values[2] = read_s16(program, offset, 6); payload_kind = 8;
                current = register_node(nodes, &node_count, depth, at_depth, 40, payload_kind, values, 3, 0); break;
            case 0x07:
                if (current >= 0 && parameter == 1) nodes[current].flags |= read_s16(program, offset, 2);
                break;
            case 0x06: view0 = current; break;
            case 0x01: offset = (int) sizeof(program); continue;
            default: break;
        }
        offset += length;
    }

    uint64_t scene_hash = FNV_OFFSET;
    scene_hash = hash_u64(scene_hash, (uint64_t) root);
    for (int i = 0; i < node_count; ++i) {
        struct Node *node = &nodes[i];
        scene_hash = hash_u64(scene_hash, node->kind);
        scene_hash = hash_u64(scene_hash, node->parent < 0 ? UINT64_MAX : (uint64_t) node->parent);
        scene_hash = hash_u64(scene_hash, (uint64_t) (int64_t) node->flags);
        scene_hash = hash_u64(scene_hash, (uint64_t) node->child_count);
        for (int child = 0; child < node->child_count; ++child) scene_hash = hash_u64(scene_hash, (uint64_t) node->children[child]);
        scene_hash = hash_u64(scene_hash, (uint64_t) node->payload_kind);
        for (unsigned value = 0; value < node->value_count; ++value) scene_hash = hash_u64(scene_hash, (uint64_t) node->values[value]);
        if (node->payload_kind >= 2 && node->payload_kind <= 7) scene_hash = hash_u64(scene_hash, node->pointer);
    }
    scene_hash = hash_u64(scene_hash, (uint64_t) view0);
    printf("geoCommandFingerprint=0x%016llx\n", (unsigned long long) command_hash);
    printf("geoSceneFingerprint=0x%016llx\n", (unsigned long long) scene_hash);
    return 0;
}
