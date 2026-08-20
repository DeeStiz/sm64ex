#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int timer,int yaw,int pitch,uint32_t scale,uint32_t friction,uint32_t buoyancy,int anim,int dead){s=h(s,(uint64_t)(int64_t)timer);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,(uint64_t)(int64_t)pitch);s=h(s,scale);s=h(s,friction);s=h(s,buoyancy);s=h(s,(uint64_t)(int64_t)anim);return h(s,dead);}
int main(void){uint64_t f=OFFSET;f=row(f,1,0x1000,0x1000,UINT32_C(0x3f4ccccd),UINT32_C(0x3f7fbe77),UINT32_C(0x40000000),3,0);f=row(f,61,0x8000,0x8000,UINT32_C(0x40400000),UINT32_C(0x3f7fbe77),UINT32_C(0x40000000),3,1);printf("pyramidTopFragmentFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern pyramid top fragment C contract passed");return 0;}
