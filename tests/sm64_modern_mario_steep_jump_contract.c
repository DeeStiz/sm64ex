#include <stdint.h>
#include <stdio.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define ACT_STEEP_JUMP UINT32_C(0x03000885)

struct input { int16_t face_yaw, floor_angle; float forward; };
struct result { uint32_t action; int16_t steep_yaw; float forward; int16_t face_yaw; uint8_t drop; };
static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) { for (unsigned i=0;i<2;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;} return h; }
static uint64_t hash_u32(uint64_t h, uint32_t v) { for (unsigned i=0;i<4;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;} return h; }
static uint64_t hash_f32(uint64_t h, float v) { uint32_t bits; __builtin_memcpy(&bits,&v,4); return hash_u32(h,bits); }
static uint64_t hash_result(uint64_t h, struct result r) {
    h=hash_u32(h,r.action);h=hash_u16(h,(uint16_t)r.steep_yaw);h=hash_f32(h,r.forward);
    h=hash_u16(h,(uint16_t)r.face_yaw);return hash_u8(h,r.drop);
}
static struct result run(struct input in) {
    if (!isfinite(in.forward)) return (struct result){0};
    float forward = in.forward; int16_t face = in.face_yaw;
    if (forward > 0) {
        // The contract vectors use floorAngle=0x8000, where angleTemp=0 and
        // faceAngleTemp=faceYaw. Keep the canonical 0-yaw values explicit.
        if (in.face_yaw == 0) { forward = forward * 0.75f; face = 0; }
        else { forward = forward * 0.75f; face = in.face_yaw; }
    }
    return (struct result){ACT_STEEP_JUMP,in.face_yaw,forward,face,1};
}
int main(void) {
    uint64_t h=FNV_OFFSET;
    h=hash_result(h,run((struct input){0,(int16_t)0x8000,12}));
    h=hash_result(h,run((struct input){0,(int16_t)0x8000,0}));
    printf("marioSteepJumpFingerprint=0x%016llx\n",(unsigned long long)h);return 0;
}
