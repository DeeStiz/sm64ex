#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define INPUT_NONZERO_ANALOG 0x0001
#define INPUT_A_PRESSED 0x0002
#define INPUT_OFF_FLOOR 0x0004
#define INPUT_ABOVE_SLIDE 0x0008
#define INPUT_FIRST_PERSON 0x0010
#define INPUT_UNKNOWN_5 0x0020
#define INPUT_A_DOWN 0x0080
#define INPUT_IN_POISON_GAS 0x0100
#define INPUT_UNKNOWN_10 0x0400
#define INPUT_B_PRESSED 0x2000
#define INPUT_Z_DOWN 0x4000

#define ACT_IN_QUICKSAND UINT32_C(0x0002020d)
#define ACT_START_CROUCHING UINT32_C(0x0c008221)
#define ACT_WALKING UINT32_C(0x04000440)
#define ACT_START_CRAWLING UINT32_C(0x0c008223)
#define ACT_SHOCKWAVE_BOUNCE UINT32_C(0x00020226)
#define ACT_FIRST_PERSON UINT32_C(0x0c000227)
#define ACT_FREEFALL UINT32_C(0x0100088c)
#define ACT_PUNCHING UINT32_C(0x00800380)
#define ACT_JUMP UINT32_C(0x03000880)
#define ACT_BEGIN_SLIDING UINT32_C(0x50)
#define ACT_PANTING UINT32_C(0x0c400205)
#define ACT_COUGHING UINT32_C(0x0c40020a)
#define ACT_SHIVERING UINT32_C(0x0c40020b)
#define ACT_START_SLEEPING UINT32_C(0x0c400202)
#define ACT_BACKFLIP UINT32_C(0x01000883)
#define ACT_STOP_CROUCHING UINT32_C(0x0c008222)

struct state { uint16_t input; int16_t health; float quicksand; uint32_t action_arg; uint16_t action_state; int16_t intended_yaw; };
struct decision { uint32_t action; uint32_t argument; int16_t face_yaw; uint8_t has_action, has_face, drop; };

static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) { for (unsigned i=0;i<2;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;} return h; }
static uint64_t hash_u32(uint64_t h, uint32_t v) { for (unsigned i=0;i<4;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;} return h; }
static uint64_t hash_decision(uint64_t h, struct decision d) {
    h = hash_u32(h, d.has_action ? d.action : UINT32_MAX); h = hash_u32(h, d.argument);
    h = hash_u16(h, d.has_face ? (uint16_t)d.face_yaw : (uint16_t)INT16_MIN);
    return hash_u8(h, d.drop);
}
static struct decision transition(uint32_t action, uint8_t drop) { return (struct decision){action,0,0,1,0,drop}; }
static struct decision common_idle(struct state s, float floor_normal, uint8_t held) {
    if (floor_normal < 0.29237169f) return transition(ACT_FREEFALL, held);
    if (s.input & INPUT_UNKNOWN_10) return transition(ACT_SHOCKWAVE_BOUNCE, held);
    if (s.input & INPUT_A_PRESSED) return transition(ACT_JUMP, held);
    if (s.input & INPUT_OFF_FLOOR) return transition(ACT_FREEFALL, held);
    if (s.input & INPUT_ABOVE_SLIDE) return transition(ACT_BEGIN_SLIDING, held);
    if (s.input & INPUT_FIRST_PERSON) return transition(ACT_FIRST_PERSON, held);
    if (s.input & INPUT_NONZERO_ANALOG) return (struct decision){ACT_WALKING,0,s.intended_yaw,1,1,held};
    if (s.input & INPUT_B_PRESSED) return transition(ACT_PUNCHING, held);
    if (s.input & INPUT_Z_DOWN) return transition(ACT_START_CROUCHING, held);
    return (struct decision){0,0,0,0,0,held};
}
static struct decision idle(struct state s, uint8_t snow, uint8_t held) {
    if (s.quicksand > 30) return transition(ACT_IN_QUICKSAND, held);
    if (s.input & INPUT_IN_POISON_GAS) return transition(ACT_COUGHING, held);
    if (!(s.action_arg & 1) && s.health < 0x300) return transition(ACT_PANTING, held);
    struct decision d = common_idle(s, 1, held);
    if (d.has_action) return d;
    if (s.action_state == 3) return transition(snow ? ACT_SHIVERING : ACT_START_SLEEPING, held);
    return d;
}
static struct decision crouching(struct state s, uint8_t held) {
    if (s.input & INPUT_UNKNOWN_10) return transition(ACT_SHOCKWAVE_BOUNCE, held);
    if (s.input & INPUT_A_PRESSED) return transition(ACT_BACKFLIP, held);
    if (s.input & INPUT_OFF_FLOOR) return transition(ACT_FREEFALL, held);
    if (s.input & INPUT_ABOVE_SLIDE) return transition(ACT_BEGIN_SLIDING, held);
    if ((s.input & INPUT_FIRST_PERSON) || !(s.input & INPUT_Z_DOWN)) return transition(ACT_STOP_CROUCHING, held);
    if (s.input & INPUT_NONZERO_ANALOG) return transition(ACT_START_CRAWLING, held);
    if (s.input & INPUT_B_PRESSED) return (struct decision){ACT_PUNCHING,9,0,1,0,held};
    return (struct decision){0,0,0,0,0,held};
}
static struct decision start_crouching(struct state s, uint8_t held) {
    if (s.input & INPUT_UNKNOWN_10) return transition(ACT_SHOCKWAVE_BOUNCE, held);
    if (s.input & INPUT_OFF_FLOOR) return transition(ACT_FREEFALL, held);
    if (s.input & INPUT_A_PRESSED) return transition(ACT_BACKFLIP, held);
    if (s.input & INPUT_ABOVE_SLIDE) return transition(ACT_BEGIN_SLIDING, held);
    return (struct decision){0,0,0,0,0,held};
}
int main(void) {
    uint64_t h=FNV_OFFSET; struct state s;
    s=(struct state){0,0x880,31,0,0,0}; h=hash_decision(h,idle(s,0,1));
    s=(struct state){INPUT_IN_POISON_GAS|INPUT_A_PRESSED,0x880,0,0,0,0}; h=hash_decision(h,idle(s,0,1));
    s=(struct state){INPUT_UNKNOWN_10|INPUT_A_PRESSED,0x880,0,0,0,0}; h=hash_decision(h,common_idle(s,1,1));
    s=(struct state){INPUT_NONZERO_ANALOG,0x880,0,0,0,0x1234}; h=hash_decision(h,common_idle(s,1,1));
    s=(struct state){INPUT_B_PRESSED,0x880,0,0,0,0}; h=hash_decision(h,common_idle(s,1,1));
    s=(struct state){INPUT_Z_DOWN,0x880,0,0,0,0}; h=hash_decision(h,common_idle(s,1,1));
    s=(struct state){0,0x2ff,0,0,0,0}; h=hash_decision(h,idle(s,0,1));
    s=(struct state){0,0x880,0,0,3,0}; h=hash_decision(h,idle(s,1,0));
    s=(struct state){0,0x880,0,0,3,0}; h=hash_decision(h,idle(s,0,0));
    s=(struct state){INPUT_Z_DOWN|INPUT_NONZERO_ANALOG,0x880,0,0,0,0}; h=hash_decision(h,crouching(s,1));
    s=(struct state){INPUT_Z_DOWN|INPUT_B_PRESSED,0x880,0,0,0,0}; h=hash_decision(h,crouching(s,1));
    s=(struct state){INPUT_A_PRESSED,0x880,0,0,0,0}; h=hash_decision(h,start_crouching(s,1));
    printf("marioActionCancelsFingerprint=0x%016llx\n",(unsigned long long)h); return 0;
}
