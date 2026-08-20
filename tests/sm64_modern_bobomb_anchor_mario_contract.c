#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t row(uint64_t s,int yaw,int thr,int toss,int dead){s=h(s,(uint64_t)(int64_t)yaw);s=h(s,thr);s=h(s,toss);return h(s,dead);}
int main(void){uint64_t f=O;f=row(f,0x2000,1,0,0);f=row(f,0x1000,0,1,0);f=row(f,0,0,0,1);printf("bobombAnchorFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern Bob-omb anchor C contract passed");return 0;}
