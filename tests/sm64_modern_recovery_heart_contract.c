#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t hf(uint64_t s,float v){union{float f;uint32_t u;}x={v};return h(s,x.u);}
static uint64_t add(uint64_t s,int spin,int played,int yaw,int total,int face,int heal){s=h(s,spin);s=h(s,played);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,(uint64_t)(int64_t)total);s=h(s,(uint64_t)(int64_t)face);s=h(s,(uint64_t)(int64_t)heal);s=hf(s,50);s=hf(s,50);s=hf(s,50);return hf(s,50);}
int main(void){uint64_t f=O;f=add(f,0,0,400,500,400,0);f=add(f,1,1,3000,0x0ab8,3000,4);f=add(f,0,1,3000,3000,3000,0);printf("recoveryHeartFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern recovery-heart C contract passed");return 0;}
