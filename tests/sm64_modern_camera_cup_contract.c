#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t hf(uint64_t h, float value) { uint32_t bits; memcpy(&bits, &value, sizeof(bits)); return h32(h, bits); }
static uint64_t hi16(uint64_t h, int16_t value) { return h16(h, (uint16_t)value); }

typedef struct { float x, y, z; } Vec3;
typedef struct {
    int active, exiting;
    int16_t pitch, yaw, head_pitch, head_yaw;
    Vec3 stored;
    float focus_offset;
} State;
typedef struct { int16_t pitch, yaw, head_pitch, head_yaw; } Head;
typedef struct { Vec3 focus, position; int16_t yaw; } Placement;
typedef struct { int16_t amplitude, decay, increment; int present; } Channel;
typedef struct { Channel pitch, yaw, roll, fov; int freezes, changes_speed; } Plan;

static uint64_t hash_vec(uint64_t h, Vec3 value) { h = hf(h, value.x); h = hf(h, value.y); return hf(h, value.z); }
static uint64_t hash_state(uint64_t h, State value) {
    h = h8(h, (uint8_t)value.active); h = h8(h, (uint8_t)value.exiting);
    h = hi16(h, value.pitch); h = hi16(h, value.yaw); h = hi16(h, value.head_pitch); h = hi16(h, value.head_yaw);
    h = hash_vec(h, value.stored); return hf(h, value.focus_offset);
}
static uint64_t hash_head(uint64_t h, Head value) { h = hi16(h, value.pitch); h = hi16(h, value.yaw); h = hi16(h, value.head_pitch); return hi16(h, value.head_yaw); }
static uint64_t hash_placement(uint64_t h, Placement value) { h = hash_vec(h, value.focus); h = hash_vec(h, value.position); return hi16(h, value.yaw); }
static uint64_t hash_channel(uint64_t h, Channel value) {
    h = h8(h, (uint8_t)value.present);
    if (value.present) { h = hi16(h, value.amplitude); h = hi16(h, value.decay); h = hi16(h, value.increment); }
    return h;
}
static uint64_t hash_plan(uint64_t h, Plan value) {
    h = hash_channel(h, value.pitch); h = hash_channel(h, value.yaw); h = hash_channel(h, value.roll); h = hash_channel(h, value.fov);
    h = h8(h, (uint8_t)value.freezes); return h8(h, (uint8_t)value.changes_speed);
}

static Channel channel(int16_t amplitude, int16_t decay, int16_t increment) {
    Channel value = { amplitude, decay, increment, 1 }; return value;
}
static Channel none(void) { Channel value = { 0, 0, 0, 0 }; return value; }

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    State entered = { 1, 0, 0, 0, 0, 0, { 10, 20, 30 }, 125 };
    fingerprint = hash_state(fingerprint, entered);
    Head head = { 0x38E3, 0x5555, (int16_t)((0x38E3 * 3) / 4), (int16_t)((0x5555 * 3) / 4) };
    fingerprint = hash_head(fingerprint, head);
    Placement placement = { { -100, 145, -200 }, { -100, 145, 50 }, 0 };
    fingerprint = hash_placement(fingerprint, placement);
    State exited = entered; exited.exiting = 1;
    fingerprint = hash_state(fingerprint, exited);
    Plan attack = { none(), none(), none(), none(), 1, 1 };
    fingerprint = hash_plan(fingerprint, attack);
    Plan small_water = {
        none(), channel(0x200, 0x10, 0x1000), channel(0x400, 0x20, 0x1000),
        channel(0x100, 0x30, (int16_t)0x8000), 0, 1
    };
    fingerprint = hash_plan(fingerprint, small_water);
    Channel fall = channel(0x60, 3, (int16_t)0x8000);
    Plan fall_damage = { fall, none(), fall, none(), 0, 0 };
    fingerprint = hash_plan(fingerprint, fall_damage);
    printf("cameraCUpFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
