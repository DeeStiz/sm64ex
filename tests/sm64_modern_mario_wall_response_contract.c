#include <stdint.h>
#include <stdio.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define UNKNOWN31 UINT32_C(0x80000000)
#define ANIM_PUSHING 0x6c
#define ANIM_LEFT 0x7f
#define ANIM_RIGHT 0x80

struct input {
    float sx, sz, x, z, vx, vy, vz, forward;
    int32_t face_yaw; int16_t frame, slope; uint8_t past1, past2, has_wall; float normal_x, normal_z;
};
struct result {
    float vx, vy, vz, forward; uint32_t flags; uint16_t animation; int32_t acceleration;
    uint8_t sound, dust; uint16_t action_state; uint32_t action_argument; int32_t gfx_yaw, gfx_roll;
};
static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) { for (unsigned i=0;i<2;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;} return h; }
static uint64_t hash_u32(uint64_t h, uint32_t v) { for (unsigned i=0;i<4;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;} return h; }
static uint64_t hash_f32(uint64_t h, float v) { uint32_t bits; __builtin_memcpy(&bits,&v,4); return hash_u32(h,bits); }
static uint64_t hash_result(uint64_t h, struct result r) {
    h=hash_f32(h,r.vx);h=hash_f32(h,r.vy);h=hash_f32(h,r.vz);h=hash_f32(h,r.forward);h=hash_u32(h,r.flags);
    h=hash_u16(h,r.animation);h=hash_u32(h,(uint32_t)r.acceleration);h=hash_u8(h,r.sound);h=hash_u8(h,r.dust);
    h=hash_u16(h,r.action_state);h=hash_u32(h,r.action_argument);h=hash_u32(h,(uint32_t)r.gfx_yaw);return hash_u32(h,(uint32_t)r.gfx_roll);
}
static struct result run(struct input in) {
    float vx=in.vx, vy=in.vy, vz=in.vz, forward=in.forward;
    if (forward > 6) { forward=6; vx=0; vz=6; }
    float dx=in.x-in.sx, dz=in.z-in.sz;
    int32_t acceleration=(int32_t)(sqrtf(dx*dx+dz*dz)*2.0f*65536.0f);
    if (!in.has_wall) return (struct result){vx,vy,vz,forward,UNKNOWN31,ANIM_PUSHING,acceleration,(in.past1||in.past2)?1:0,0,0,0,0};
    int32_t wall_angle = (in.normal_x == 0 && in.normal_z > 0) ? 0 : 0x4000;
    int32_t wall_dyaw=(int16_t)(wall_angle-(int16_t)in.face_yaw);
    if (wall_dyaw <= -0x71c8 || wall_dyaw >= 0x71c8)
        return (struct result){vx,vy,vz,forward,UNKNOWN31,ANIM_PUSHING,acceleration,(in.past1||in.past2)?1:0,0,0,0,0};
    int16_t facing=(int16_t)(wall_angle+0x8000);
    return (struct result){vx,vy,vz,forward,0,(wall_dyaw<0)?ANIM_RIGHT:ANIM_LEFT,acceleration,
        (in.frame<20)?2:0,(in.frame<20),1,(uint32_t)(wall_angle+0x8000),facing,in.slope};
}
int main(void) {
    uint64_t h=FNV_OFFSET;
    h=hash_result(h,run((struct input){0,0,3,4,9,2,-3,12,0,10,0x1234,1,0,0,0,0}));
    h=hash_result(h,run((struct input){0,0,3,4,9,2,-3,12,0,10,0x1234,0,0,1,0,1}));
    h=hash_result(h,run((struct input){0,0,3,4,9,2,-3,4,0x4000,25,0x1234,0,0,1,0,1}));
    printf("marioWallResponseFingerprint=0x%016llx\n",(unsigned long long)h);return 0;
}
