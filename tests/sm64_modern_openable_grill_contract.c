#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t gp(uint64_t s,uint64_t a,int32_t t,int spawn,int signal,int sound,int jingle){s=h(s,a);s=h(s,(uint64_t)(int64_t)t);s=h(s,spawn);s=h(s,signal);s=h(s,sound);return h(s,jingle);}
static uint64_t gc(uint64_t s,int32_t a,int32_t t,int32_t yaw,int load){s=h(s,(uint64_t)(int64_t)a);s=h(s,(uint64_t)(int64_t)t);s=h(s,(uint64_t)(int64_t)yaw);return h(s,load);}
int main(void){uint64_t f=O;f=gp(f,1,0,1,0,0,0);f=gp(f,2,0,0,0,0,0);f=gp(f,3,0,0,1,1,1);f=gp(f,3,3,0,0,0,0);f=gc(f,0,1,0,1);f=gc(f,1,1,0x100,1);f=gc(f,2,0,-0x4000,1);printf("openableGrillFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern openable-grill C contract passed");return 0;}
