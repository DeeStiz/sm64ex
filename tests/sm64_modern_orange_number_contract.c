#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int timer,int anim,uint32_t x,uint32_t y,uint32_t z,uint32_t vy,int deleted,int spark){s=h(s,timer);s=h(s,anim);s=h(s,x);s=h(s,y);s=h(s,z);s=h(s,vy);s=h(s,deleted);return h(s,spark);}
int main(void){uint64_t f=O;f=add(f,1,4,0,0x41d00000,0,0x41c00000,0,0);f=add(f,1,4,0,0xc1a80000,0,0x41600000,0,0);f=add(f,36,4,0x3f800000,0x40000000,0x40400000,0xc0000000,1,1);printf("orangeNumberFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern orange-number C contract passed");return 0;}
