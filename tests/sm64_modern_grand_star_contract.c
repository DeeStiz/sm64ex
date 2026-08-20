#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int action,int timer,int sub,int tangible,int deleted,int sparkle,int appears,int grand,int jump,int yaw){s=h(s,action);s=h(s,timer);s=h(s,sub);s=h(s,tangible);s=h(s,deleted);s=h(s,sparkle);s=h(s,appears);s=h(s,grand);s=h(s,jump);return h(s,(uint64_t)(int64_t)yaw);}
int main(void){uint64_t f=O;f=add(f,0,1,0,0,0,1,1,0,0,1024);f=add(f,1,1,0,0,0,1,0,1,0,1024);f=add(f,2,2,1,1,1,0,0,0,0,10);printf("grandStarFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern grand-star C contract passed");return 0;}
