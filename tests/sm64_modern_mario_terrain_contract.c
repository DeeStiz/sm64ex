#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct state {
    float position[3];
    uint32_t floor_id, ceiling_id, wall_id;
    uint8_t has_floor, has_ceiling, has_wall;
    float floor_height, ceiling_height, water_level;
    int16_t floor_angle;
    uint32_t terrain_sound;
    uint16_t input;
};
struct mutation {
    struct state state;
    uint8_t floor_changed, ceiling_changed, water_changed;
};

static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_u32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_f32(uint64_t h, float value) {
    uint32_t bits; __builtin_memcpy(&bits, &value, sizeof bits); return hash_u32(h, bits);
}
static uint64_t hash_optional(uint64_t h, uint8_t present, uint32_t value) {
    return hash_u32(h, present ? value : UINT32_MAX);
}
static uint64_t hash_mutation(uint64_t h, struct mutation m) {
    h = hash_f32(h, m.state.position[0]); h = hash_f32(h, m.state.position[1]);
    h = hash_f32(h, m.state.position[2]);
    h = hash_optional(h, m.state.has_floor, m.state.floor_id);
    h = hash_optional(h, m.state.has_ceiling, m.state.ceiling_id);
    h = hash_optional(h, m.state.has_wall, m.state.wall_id);
    h = hash_f32(h, m.state.floor_height); h = hash_f32(h, m.state.ceiling_height);
    h = hash_u16(h, (uint16_t)m.state.floor_angle); h = hash_f32(h, m.state.water_level);
    h = hash_u32(h, m.state.terrain_sound); h = hash_u16(h, m.state.input);
    h = hash_u8(h, m.floor_changed); h = hash_u8(h, m.ceiling_changed);
    return hash_u8(h, m.water_changed);
}

static struct mutation apply(
    struct state *s, float x, float y, float z,
    uint8_t floor, uint32_t floor_id, float floor_height,
    uint8_t ceiling, uint32_t ceiling_id, float ceiling_height,
    uint8_t wall, uint32_t wall_id, int16_t angle, float water,
    uint32_t sound, uint16_t geometry_input
) {
    struct mutation m = {0};
    m.floor_changed = s->has_floor != floor || (floor && s->floor_id != floor_id);
    m.ceiling_changed = s->has_ceiling != ceiling || (ceiling && s->ceiling_id != ceiling_id);
    m.water_changed = s->water_level != water;
    s->position[0] = x; s->position[1] = y; s->position[2] = z;
    s->has_floor = floor; s->floor_id = floor_id; s->floor_height = floor_height;
    s->has_ceiling = ceiling; s->ceiling_id = ceiling_id; s->ceiling_height = ceiling_height;
    s->has_wall = wall; s->wall_id = wall_id; s->floor_angle = angle;
    s->water_level = water; s->terrain_sound = sound; s->input |= geometry_input;
    m.state = *s; return m;
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    struct state first = {0}; first.input = UINT16_C(0x0080);
    h = hash_mutation(h, apply(&first, 10, 20, 30, 1, 7, 12, 1, 8, 160,
                               1, 12, 0x1234, 100, UINT32_C(2 << 16),
                               UINT16_C(0x0208)));
    struct state second = {0};
    second.has_floor = 1; second.floor_id = 7; second.has_ceiling = 1;
    second.ceiling_id = 8; second.water_level = 100;
    h = hash_mutation(h, apply(&second, -4, 50, 8, 1, 15, -20, 0, 0, -11000,
                               0, 0, (int16_t)-0x2222, 240, UINT32_C(7 << 16),
                               UINT16_C(0x0104)));
    printf("marioTerrainFingerprint=0x%016llx\n", (unsigned long long) h);
    return 0;
}
