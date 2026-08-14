#include <stdint.h>
#include <stdio.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define ACT_IDLE UINT32_C(0x0c400201)
#define ACT_SOFT_BACKWARD UINT32_C(0x00020464)
#define ACT_SOFT_FORWARD UINT32_C(0x00020465)

struct input {
    int16_t floor_class, floor_angle, face_yaw;
    uint8_t terrain_slide;
    float nx, ny, nz, forward;
    uint32_t action;
};
struct result {
    uint8_t downhill, slope, steep;
    float forward, slide_x, slide_z, velocity_y;
    int16_t slide_yaw;
    uint8_t sand, wind;
};
static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) { for (unsigned i=0;i<2;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;} return h; }
static uint64_t hash_u32(uint64_t h, uint32_t v) { for (unsigned i=0;i<4;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;} return h; }
static uint64_t hash_f32(uint64_t h, float v) { uint32_t bits; __builtin_memcpy(&bits,&v,4); return hash_u32(h,bits); }
static uint64_t hash_result(uint64_t h, struct result r) {
    h=hash_u8(h,r.downhill);h=hash_u8(h,r.slope);h=hash_u8(h,r.steep);h=hash_f32(h,r.forward);
    h=hash_u16(h,(uint16_t)r.slide_yaw);h=hash_f32(h,r.slide_x);h=hash_f32(h,r.slide_z);h=hash_f32(h,r.velocity_y);
    h=hash_u8(h,r.sand);return hash_u8(h,r.wind);
}
static struct result run(struct input in) {
    const float slideCos = 0.9998477f, defaultSlope = 0.9659258f;
    const float slipperySlope = 0.9848076f, verySlope = 0.9961947f, notSlope = 0.9396926f;
    int16_t d = (int16_t)((int32_t)in.floor_angle - (int32_t)in.face_yaw);
    uint8_t downhill = d > -0x4000 && d < 0x4000;
    uint8_t slope;
    if (in.terrain_slide && in.ny < slideCos) slope = 1;
    else if (in.floor_class == 0x13) slope = in.ny <= verySlope;
    else if (in.floor_class == 0x14) slope = in.ny <= slipperySlope;
    else if (in.floor_class == 0x15) slope = in.ny <= notSlope;
    else slope = in.ny <= defaultSlope;
    float steepLimit = (in.floor_class == 0x13) ? 0.9659258f
        : (in.floor_class == 0x14 ? 0.9396926f : 0.8660254f);
    uint8_t steep = !downhill && in.ny <= steepLimit;
    float steepness = sqrtf(in.nx * in.nx + in.nz * in.nz);
    float forward = in.forward;
    if (slope) {
        float accel = (in.action == ACT_SOFT_BACKWARD || in.action == ACT_SOFT_FORWARD) ? 1.7f
            : (in.floor_class == 0x13 ? 5.3f : (in.floor_class == 0x14 ? 2.7f : (in.floor_class == 0x15 ? 0.0f : 1.7f)));
        if (d > -0x4000 && d < 0x4000) forward += accel * steepness;
        else forward -= accel * steepness;
    }
    return (struct result){downhill,slope,steep,forward,in.face_yaw == 0 ? 0 : 0,forward,0,in.face_yaw,1,1};
}
static struct input in(int16_t klass, uint8_t slide, float nx, float ny, float nz,
                       int16_t angle, int16_t face, float forward, uint32_t action) {
    return (struct input){klass,angle,face,slide,nx,ny,nz,forward,action};
}
int main(void) {
    uint64_t h=FNV_OFFSET;
    h=hash_result(h,run(in(0,0,0,1,0,0,0,10,ACT_IDLE)));
    h=hash_result(h,run(in(0,1,0,0.99f,0,0,0,10,ACT_IDLE)));
    h=hash_result(h,run(in(0x13,0,0.3122499f,0.95f,0,0,0,10,ACT_IDLE)));
    h=hash_result(h,run(in(0,0,0.6f,0.8f,0,(int16_t)0x8000,0,10,ACT_IDLE)));
    h=hash_result(h,run(in(0x13,0,0.3122499f,0.95f,0,0,0,10,ACT_SOFT_FORWARD)));
    h=hash_result(h,run(in(0,0,0.6f,0.8f,0,0x4000,0,10,ACT_IDLE)));
    h=hash_result(h,run(in(0,0,0.6f,0.8f,0,0,0,10,ACT_IDLE)));
    h=hash_result(h,run(in(0,0,0,1,0,0x4000,0,10,ACT_IDLE)));
    printf("marioSlopeFingerprint=0x%016llx\n",(unsigned long long)h);return 0;
}
