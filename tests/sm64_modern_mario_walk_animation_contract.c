#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

enum { ANIM_WALKING = 0x48, ANIM_RUNNING = 0x72, ANIM_TIPTOE = 0x92,
       ANIM_START_TIPTOE = 0xca, ANIM_QUICKSAND = 0x78 };
enum { SOUND_NONE, SOUND_TERRAIN, SOUND_TERRAIN_TIPTOE, SOUND_QUICKSAND,
       SOUND_METAL, SOUND_METAL_TIPTOE };

struct input {
    float intended, forward, quicksand;
    uint16_t timer;
    uint8_t past23, past1, past2, metal;
    int16_t pitch, running_pitch;
};
struct result {
    uint16_t animation; int32_t accel; uint16_t timer; int16_t pitch;
    uint8_t sound; int16_t frame1, frame2;
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
static uint64_t hash_result(uint64_t h, struct result r) {
    h = hash_u16(h, r.animation); h = hash_u32(h, (uint32_t)r.accel);
    h = hash_u16(h, r.timer); h = hash_u16(h, (uint16_t)r.pitch);
    h = hash_u8(h, r.sound); h = hash_u16(h, (uint16_t)r.frame1);
    return hash_u16(h, (uint16_t)r.frame2);
}
static int32_t fixed(float value) { return (int32_t)(value * 65536.0f); }
static int32_t approach(int32_t current, int32_t target) {
    if (current < target) { int32_t next = current + 0x800; return next > target ? target : next; }
    int32_t next = current - 0x800; return next < target ? target : next;
}
static struct result finish(struct input in, uint16_t animation, int32_t accel,
                            uint16_t timer, int32_t target_pitch, int16_t frame1, int16_t frame2) {
    uint8_t sound = SOUND_NONE;
    if (in.past1 || in.past2) {
        if (in.metal) sound = animation == ANIM_TIPTOE ? SOUND_METAL_TIPTOE : SOUND_METAL;
        else if (in.quicksand > 50) sound = SOUND_QUICKSAND;
        else sound = animation == ANIM_TIPTOE ? SOUND_TERRAIN_TIPTOE : SOUND_TERRAIN;
    }
    return (struct result){animation, accel, timer, (int16_t)approach(in.pitch, target_pitch), sound, frame1, frame2};
}
static struct result run(struct input in) {
    float speed = in.intended > in.forward ? in.intended : in.forward;
    if (speed < 4) speed = 4;
    uint16_t timer = in.timer;
    if (in.quicksand > 50) return finish(in, ANIM_QUICKSAND, fixed(speed / 4), 0, 0, 19, 93);
    for (;;) {
        switch (timer) {
            case 0:
                if (speed > 8) timer = 2;
                else return finish(in, ANIM_START_TIPTOE, fixed(speed / 4) < 0x1000 ? 0x1000 : fixed(speed / 4), in.past23 ? 2 : timer, 0, 7, 22);
                break;
            case 1:
                if (speed > 8) timer = 2;
                else return finish(in, ANIM_TIPTOE, fixed(speed) < 0x1000 ? 0x1000 : fixed(speed), timer, 0, 14, 72);
                break;
            case 2:
                if (speed < 5) timer = 1;
                else if (speed > 22) timer = 3;
                else return finish(in, ANIM_WALKING, fixed(speed / 4), timer, 0, 10, 49);
                break;
            case 3:
                if (speed < 18) timer = 2;
                else return finish(in, ANIM_RUNNING, fixed(speed / 4), timer, in.running_pitch, 9, 45);
                break;
            default: return (struct result){0};
        }
    }
}
static struct input in(float intended, float forward, float quicksand, uint16_t timer,
                        uint8_t past23, uint8_t past1, uint8_t past2, uint8_t metal,
                        int16_t pitch, int16_t running_pitch) {
    return (struct input){intended, forward, quicksand, timer, past23, past1, past2, metal, pitch, running_pitch};
}
int main(void) {
    uint64_t h = FNV_OFFSET;
    h = hash_result(h, run(in(2, 0, 0, 0, 0, 1, 0, 0, 0, 0x1800)));
    h = hash_result(h, run(in(10, 0, 0, 0, 0, 0, 0, 0, 0, 0x1800)));
    h = hash_result(h, run(in(12, 10, 0, 2, 0, 1, 0, 0, 0, 0x1800)));
    h = hash_result(h, run(in(24, 20, 0, 2, 0, 0, 1, 0, -0x1000, 0x1800)));
    h = hash_result(h, run(in(3, 2, 0, 1, 0, 1, 0, 1, 0, 0x1800)));
    h = hash_result(h, run(in(16, 8, 60, 0, 0, 1, 0, 0, 0, 0x1800)));
    h = hash_result(h, run(in(2, 0, 0, 0, 1, 0, 0, 0, 0, 0x1800)));
    printf("marioWalkAnimationFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
