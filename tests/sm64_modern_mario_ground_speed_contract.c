#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct input { float intended, forward, quicksand, normal; int32_t intended_yaw, face_yaw; int slow, responsive, cheats; };
struct result { float forward; int16_t face_yaw; };
static uint64_t hash_u16(uint64_t h, uint16_t v) { for (unsigned i=0;i<2;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;}return h; }
static uint64_t hash_u32(uint64_t h, uint32_t v) { for (unsigned i=0;i<4;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;}return h; }
static uint64_t hash_result(uint64_t h, struct result r) { uint32_t bits; __builtin_memcpy(&bits,&r.forward,4); return hash_u16(hash_u32(h,bits),(uint16_t)r.face_yaw); }
static int32_t approach(int32_t current) {
    if (current < 0) { int32_t next=current+0x800; return next>0?0:next; }
    int32_t next=current-0x800; return next<0?0:next;
}
static struct result update(struct input in) {
    float max_speed = in.slow ? 24.0f : 32.0f;
    float target = in.intended < max_speed ? in.intended : max_speed;
    if (in.quicksand > 10.0f) target = (float)((double)target * (6.25 / (double)in.quicksand));
    float forward = in.forward;
    if (forward <= 0) forward += 1.1f;
    else if (forward <= target) forward += 1.1f - forward / 43.0f;
    else if (in.normal >= 0.95f) forward -= 1.0f;
    if (forward > 48) forward = 48;
    int32_t intended = (int32_t)(int16_t)in.intended_yaw;
    int32_t face = (int32_t)(int16_t)in.face_yaw;
    int32_t next = in.responsive && in.cheats ? intended : intended - approach((int32_t)(int16_t)(intended-face));
    return (struct result){forward,(int16_t)next};
}
int main(void) {
    struct input inputs[] = {
        {32,0,0,1,0x3000,0,0,0,0},
        {4,10,0,.9f,-0x3000,0x3000,1,0,0},
        {32,2,20,.8f,0x7000,-0x7000,0,0,0},
        {8,50,0,1,-0x7FFF,0x7FFF,0,1,1}
    };
    uint64_t h=FNV_OFFSET;
    for (unsigned i=0;i<sizeof(inputs)/sizeof(inputs[0]);++i) h=hash_result(h,update(inputs[i]));
    printf("marioGroundSpeedFingerprint=0x%016llx\n",(unsigned long long)h); return 0;
}
