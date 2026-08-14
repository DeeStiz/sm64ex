#include <stdint.h>
#include <stdio.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

#define ACT_IDLE UINT32_C(0x0c400201)
#define ACT_JUMP_LAND UINT32_C(0x04000470)
#define ACT_FREEFALL_LAND UINT32_C(0x04000471)
#define ACT_DOUBLE_JUMP_LAND UINT32_C(0x04000472)
#define ACT_SIDE_FLIP_LAND_STOP UINT32_C(0x0c000233)
#define ACT_QUICKSAND_JUMP_LAND UINT32_C(0x00000476)
#define ACT_HOLD_QUICKSAND_JUMP_LAND UINT32_C(0x00000477)
#define ACT_STEEP_JUMP UINT32_C(0x03000885)
#define ACT_JUMP UINT32_C(0x03000880)
#define ACT_DOUBLE_JUMP UINT32_C(0x03000881)
#define ACT_TRIPLE_JUMP UINT32_C(0x01000882)
#define ACT_FLYING_TRIPLE_JUMP UINT32_C(0x03000894)

struct input {
    float quicksand, forward;
    uint8_t held, steep, timer, squish, wing;
    uint32_t previous;
};
struct result {
    uint32_t action, argument;
    uint8_t reset, steep_physics, drop;
};

static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_result(uint64_t h, struct result r) {
    h = hash_u32(h, r.action); h = hash_u32(h, r.argument);
    h = hash_u8(h, r.reset); h = hash_u8(h, r.steep_physics); return hash_u8(h, r.drop);
}
static struct result run(struct input in) {
    uint32_t action;
    uint8_t steep_physics = 0, drop = 0;
    if (!isfinite(in.quicksand) || !isfinite(in.forward)) return (struct result){0};
    if (in.quicksand >= 11.0f) {
        action = in.held ? ACT_HOLD_QUICKSAND_JUMP_LAND : ACT_QUICKSAND_JUMP_LAND;
    } else if (in.steep) {
        action = ACT_STEEP_JUMP; steep_physics = 1; drop = 1;
    } else if (in.timer == 0 || in.squish) {
        action = ACT_JUMP;
    } else if (in.previous == ACT_JUMP_LAND || in.previous == ACT_FREEFALL_LAND
               || in.previous == ACT_SIDE_FLIP_LAND_STOP) {
        action = ACT_DOUBLE_JUMP;
    } else if (in.previous == ACT_DOUBLE_JUMP_LAND) {
        if (in.wing) action = ACT_FLYING_TRIPLE_JUMP;
        else if (in.forward > 20.0f) action = ACT_TRIPLE_JUMP;
        else action = ACT_JUMP;
    } else {
        action = ACT_JUMP;
    }
    return (struct result){action, 0, 1, steep_physics, drop};
}
static struct input in(float quicksand, uint8_t held, uint8_t steep, uint8_t timer,
                        uint8_t squish, uint32_t previous, uint8_t wing, float forward) {
    return (struct input){quicksand, forward, held, steep, timer, squish, wing, previous};
}
int main(void) {
    uint64_t h = FNV_OFFSET;
    h = hash_result(h, run(in(11, 0, 0, 1, 0, ACT_IDLE, 0, 10)));
    h = hash_result(h, run(in(12, 1, 0, 1, 0, ACT_IDLE, 0, 10)));
    h = hash_result(h, run(in(0, 0, 1, 1, 0, ACT_IDLE, 0, 10)));
    h = hash_result(h, run(in(0, 0, 0, 0, 0, ACT_IDLE, 0, 10)));
    h = hash_result(h, run(in(0, 0, 0, 1, 1, ACT_IDLE, 0, 10)));
    h = hash_result(h, run(in(0, 0, 0, 1, 0, ACT_JUMP_LAND, 0, 10)));
    h = hash_result(h, run(in(0, 0, 0, 1, 0, ACT_FREEFALL_LAND, 0, 10)));
    h = hash_result(h, run(in(0, 0, 0, 1, 0, ACT_SIDE_FLIP_LAND_STOP, 0, 10)));
    h = hash_result(h, run(in(0, 0, 0, 1, 0, ACT_DOUBLE_JUMP_LAND, 1, 10)));
    h = hash_result(h, run(in(0, 0, 0, 1, 0, ACT_DOUBLE_JUMP_LAND, 0, 20.1f)));
    h = hash_result(h, run(in(0, 0, 0, 1, 0, ACT_DOUBLE_JUMP_LAND, 0, 20)));
    h = hash_result(h, run(in(0, 0, 0, 1, 0, ACT_IDLE, 0, 10)));
    printf("marioLandingJumpFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
