#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define ACT_IDLE UINT32_C(0x0c400201)
#define ACT_CROUCHING UINT32_C(0x0c008220)
#define ACT_START_CROUCHING UINT32_C(0x0c008221)
#define ACT_CROUCHING_NEXT ACT_CROUCHING
#define ACT_SHIVERING UINT32_C(0x0c40020b)
#define ACT_START_SLEEPING UINT32_C(0x0c400202)
#define ACT_PUNCHING UINT32_C(0x00800380)
#define ANIM_IDLE_LEFT 0xc3
#define ANIM_IDLE_WALL 0x7e
#define ANIM_CROUCHING 0x98
#define ANIM_START_CROUCHING 0x97

struct decision { uint32_t action, argument; uint8_t has_action, drop; };
struct input {
    uint32_t action, action_arg; uint16_t action_state, action_timer;
    struct decision cancel; uint8_t snow, at_end, past_end, floor_dynamic; float floor_delta;
};
struct result {
    uint32_t action, argument; uint16_t animation, action_state, action_timer;
    uint8_t has_action, has_animation, run_ground, drop;
};
static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) { for (unsigned i=0;i<2;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;} return h; }
static uint64_t hash_u32(uint64_t h, uint32_t v) { for (unsigned i=0;i<4;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;} return h; }
static uint64_t hash_result(uint64_t h, struct result r) {
    h = hash_u32(h, r.has_action ? r.action : UINT32_MAX); h = hash_u32(h, r.argument);
    h = hash_u16(h, r.has_animation ? r.animation : UINT16_MAX);
    h = hash_u16(h, r.action_state); h = hash_u16(h, r.action_timer);
    h = hash_u8(h, r.run_ground); return hash_u8(h, r.drop);
}
static struct result finish(uint32_t action, uint32_t argument, uint8_t has_action,
                            uint16_t animation, uint8_t has_animation, uint16_t state,
                            uint16_t timer, uint8_t run_ground, uint8_t drop) {
    return (struct result){action, argument, animation, state, timer, has_action, has_animation, run_ground, drop};
}
static struct result run(struct input in) {
    if (in.cancel.has_action) return finish(in.cancel.action, in.cancel.argument, 1, 0, 0, in.action_state, in.action_timer, 0, in.cancel.drop);
    if (in.action == ACT_IDLE) {
        if (in.action_state == 3) return finish(in.snow ? ACT_SHIVERING : ACT_START_SLEEPING, 0, 1, 0, 0, in.action_state, in.action_timer, 0, in.cancel.drop);
        uint16_t animation = (in.action_arg & 1) ? ANIM_IDLE_WALL : (uint16_t)(ANIM_IDLE_LEFT + in.action_state);
        uint16_t state = in.action_state, timer = in.action_timer;
        if (in.at_end && !(in.action_arg & 1)) {
            state++;
            if (state == 3) {
                if (in.floor_delta < -24 || in.floor_delta > 24 || in.floor_dynamic) state = 0;
                else { timer++; if (timer < 10) state = 0; }
            }
        }
        return finish(0, 0, 0, animation, 1, state, timer, 1, in.cancel.drop);
    }
    if (in.action == ACT_CROUCHING) return finish(0, 0, 0, ANIM_CROUCHING, 1, in.action_state, in.action_timer, 1, in.cancel.drop);
    if (in.action == ACT_START_CROUCHING) return finish(in.past_end ? ACT_CROUCHING_NEXT : 0, 0, in.past_end, ANIM_START_CROUCHING, 1, in.action_state, in.action_timer, 1, in.cancel.drop);
    return (struct result){0};
}
static struct input in(uint32_t action, uint32_t action_arg, uint16_t state, uint16_t timer,
                       struct decision cancel, uint8_t snow, uint8_t at_end, uint8_t past_end,
                       float floor_delta, uint8_t floor_dynamic) {
    return (struct input){action, action_arg, state, timer, cancel, snow, at_end, past_end, floor_dynamic, floor_delta};
}
static struct decision no_cancel(void) { return (struct decision){0,0,0,0}; }
static struct decision cancel(uint32_t action, uint32_t argument, uint8_t drop) { return (struct decision){action,argument,1,drop}; }
int main(void) {
    uint64_t h = FNV_OFFSET;
    h = hash_result(h, run(in(ACT_IDLE,0,0,0,no_cancel(),0,0,0,0,0)));
    h = hash_result(h, run(in(ACT_IDLE,1,2,0,no_cancel(),0,0,0,0,0)));
    h = hash_result(h, run(in(ACT_IDLE,0,2,9,no_cancel(),0,1,0,0,0)));
    h = hash_result(h, run(in(ACT_IDLE,0,2,0,no_cancel(),0,1,0,25,0)));
    h = hash_result(h, run(in(ACT_IDLE,0,3,0,no_cancel(),1,0,0,0,0)));
    h = hash_result(h, run(in(ACT_CROUCHING,0,0,0,(struct decision){0,0,0,1},0,0,0,0,0)));
    h = hash_result(h, run(in(ACT_START_CROUCHING,0,0,0,no_cancel(),0,0,1,0,0)));
    h = hash_result(h, run(in(ACT_IDLE,0,0,0,cancel(ACT_PUNCHING,0,1),0,0,0,0,0)));
    printf("marioStationaryActionFingerprint=0x%016llx\n", (unsigned long long)h); return 0;
}
