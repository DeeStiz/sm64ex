#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int state,int timer,int yaw,int vel,uint32_t scale,int hidden,int particles,int del,int sound){s=h(s,(uint64_t)(int64_t)state);s=h(s,(uint64_t)(int64_t)timer);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,(uint64_t)(int64_t)vel);s=h(s,scale);s=h(s,hidden);s=h(s,particles);s=h(s,del);return h(s,sound);}
int main(void){uint64_t f=OFFSET;f=row(f,0,1,UINT16_C(0x8860),UINT16_C(0x1060),UINT32_C(0x3f000000),0,0,0,0);f=row(f,2,0,UINT16_C(0x2060),UINT16_C(0x2060),UINT32_C(0x3f800000),1,0,0,1);f=row(f,3,0,0,UINT16_C(0x2400),UINT32_C(0x3f800000),1,1,0,0);f=row(f,3,51,0,UINT16_C(0x2400),UINT32_C(0x3f800000),1,0,1,0);printf("unlockDoorStarFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern unlock door star C contract passed");return 0;}
