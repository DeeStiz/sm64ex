#include <stdint.h>
#include <stdio.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t hash_u16(uint64_t h,uint16_t v){for(unsigned i=0;i<2;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;}return h;}
static uint64_t hash_u32(uint64_t h,uint32_t v){for(unsigned i=0;i<4;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;}return h;}
static uint64_t hash_f32(uint64_t h,float v){uint32_t b;__builtin_memcpy(&b,&v,4);return hash_u32(h,b);}
int main(void){
    float speed = 12.0f + 1.1f - 12.0f / 43.0f;
    float slopeSpeed = speed + 1.7f * sqrtf(0.6f * 0.6f);
    float animationSpeed = 20.0f > slopeSpeed ? 20.0f : slopeSpeed;
    int32_t acceleration = (int32_t)((double)(animationSpeed / 4.0f) * 65536.0);
    uint64_t h = FNV_OFFSET;
    h = hash_f32(h, slopeSpeed);
    h = hash_f32(h, slopeSpeed);
    h = hash_u16(h, 0);
    h = hash_u16(h, 0x48);
    h = hash_u32(h, (uint32_t)acceleration);
    h = hash_u16(h, 2);
    printf("marioWalkingSlopeFingerprint=0x%016llx\n",(unsigned long long)h);
    return 0;
}
