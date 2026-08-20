#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int role,int timer,int deleted,int collision,int model_none,int e6,int e12){s=h(s,role);s=h(s,timer);s=h(s,deleted);s=h(s,collision);s=h(s,model_none);s=h(s,(uint64_t)(int64_t)e6);return h(s,(uint64_t)(int64_t)e12);}
int main(void){uint64_t f=O;f=add(f,0,1,0,1,0,0,0);f=add(f,1,1,1,0,0,0,0);f=add(f,2,5,0,0,1,0,0);f=add(f,3,1,1,0,0,-800,-800);printf("environmentGateFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern environment-gate C contract passed");return 0;}
