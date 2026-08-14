#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define STEP_LEFT_GROUND 0
#define STEP_NONE 1
#define STEP_HIT_WALL 2
#define STEP_CONTINUE 3

struct floor_probe { uint32_t id; float height; float normal_y; uint8_t present; };
struct wall_probe { uint32_t id; int16_t angle; uint8_t present; };
struct quarter { struct floor_probe floor; float ceiling; float water; struct wall_probe wall; };
struct result {
    float x, y, z;
    struct floor_probe floor;
    uint32_t wall_id;
    uint8_t wall_present;
    uint8_t step;
    uint8_t quarters;
    uint32_t terrain_sound;
};

static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_f32(uint64_t h, float value) {
    uint32_t bits; memcpy(&bits, &value, sizeof bits); return hash_u32(h, bits);
}
static uint64_t hash_result(uint64_t h, struct result r) {
    h = hash_f32(h, r.x); h = hash_f32(h, r.y); h = hash_f32(h, r.z);
    h = hash_u32(h, r.floor.present ? r.floor.id : 0);
    h = hash_f32(h, r.floor.height); h = hash_f32(h, r.floor.normal_y);
    h = hash_u32(h, r.wall_present ? r.wall_id : 0);
    h = hash_u8(h, r.step); h = hash_u8(h, r.quarters);
    return hash_u32(h, r.terrain_sound);
}

static struct result run(
    float px, float py, float pz, float vx, float vz,
    struct floor_probe initial_floor, int32_t face_yaw, uint8_t riding_shell,
    const struct quarter q[4]
) {
    float x = px, y = py, z = pz;
    struct floor_probe floor = initial_floor;
    uint32_t wall_id = 0; uint8_t wall_present = 0;
    uint8_t step = STEP_NONE; uint8_t quarters = 0;
    for (unsigned i = 0; i < 4; ++i) {
        float intended_x = x + floor.normal_y * (vx / 4.0f);
        float intended_z = z + floor.normal_y * (vz / 4.0f);
        quarters++;
        if (!q[i].floor.present) { step = STEP_CONTINUE; break; }
        struct floor_probe next_floor = q[i].floor;
        if (riding_shell && next_floor.height < q[i].water) {
            next_floor.present = 0; next_floor.id = 0; next_floor.height = q[i].water; next_floor.normal_y = 1.0f;
        }
        if (py > next_floor.height + 100.0f) {
            if (py + 160.0f >= q[i].ceiling) { step = STEP_CONTINUE; break; }
            x = intended_x; z = intended_z; floor = next_floor; step = STEP_LEFT_GROUND; break;
        }
        if (next_floor.height + 160.0f >= q[i].ceiling) { step = STEP_CONTINUE; break; }
        x = intended_x; y = next_floor.height; z = intended_z; floor = next_floor;
        if (!q[i].wall.present) { step = STEP_NONE; continue; }
        wall_id = q[i].wall.id; wall_present = 1;
        int32_t wall_dyaw = (int16_t)(q[i].wall.angle - (int16_t)face_yaw);
        if ((wall_dyaw >= 0x2aaa && wall_dyaw <= 0x5555)
            || (wall_dyaw <= -0x2aaa && wall_dyaw >= -0x5555)) {
            step = STEP_NONE; continue;
        }
        step = STEP_CONTINUE;
    }
    if (step == STEP_CONTINUE) step = STEP_HIT_WALL;
    return (struct result){x, y, z, floor, wall_id, wall_present, step, quarters, UINT32_C(0x30000)};
}

static struct floor_probe floor_probe(uint32_t id, float height, float normal_y, uint8_t present) {
    return (struct floor_probe){id, height, normal_y, present};
}
static struct quarter quarter(struct floor_probe floor, float ceiling, float water, uint32_t wall_id, int16_t wall_angle, uint8_t wall_present) {
    return (struct quarter){floor, ceiling, water, {wall_id, wall_angle, wall_present}};
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    struct quarter q[4];
    struct floor_probe initial = floor_probe(1, 0, 1, 1);

    for (unsigned i = 0; i < 4; ++i) q[i] = quarter(floor_probe(2, 0, 1, 1), 1000, -11000, 0, 0, 0);
    h = hash_result(h, run(0, 0, 0, 4, 0, initial, 0, 0, q));
    for (unsigned i = 0; i < 4; ++i) q[i] = quarter(floor_probe(3, -200, 1, 1), 1000, -11000, 0, 0, 0);
    h = hash_result(h, run(0, 0, 0, 4, 0, initial, 0, 0, q));
    for (unsigned i = 0; i < 4; ++i) q[i] = quarter(floor_probe(4, 0, 1, 1), 150, -11000, 0, 0, 0);
    h = hash_result(h, run(0, 0, 0, 4, 0, initial, 0, 0, q));
    for (unsigned i = 0; i < 4; ++i) q[i] = quarter(floor_probe(5, 0, 1, 1), 1000, -11000, 6, 0, 1);
    h = hash_result(h, run(0, 0, 0, 4, 0, initial, 0, 0, q));
    for (unsigned i = 0; i < 4; ++i) q[i] = quarter(floor_probe(7, 0, 1, 1), 1000, -11000, 8, 0x4000, 1);
    h = hash_result(h, run(0, 0, 0, 4, 0, initial, 0, 0, q));
    for (unsigned i = 0; i < 4; ++i) q[i] = quarter(floor_probe(10, -20, 1, 1), 1000, 30, 0, 0, 0);
    h = hash_result(h, run(0, 20, 0, 4, 0, floor_probe(9, 0, 1, 1), 0, 1, q));
    for (unsigned i = 0; i < 4; ++i) q[i] = quarter(floor_probe(0, 0, 1, 0), 1000, -11000, 0, 0, 0);
    h = hash_result(h, run(0, 0, 0, 4, 0, initial, 0, 0, q));

    printf("marioGroundStepFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
