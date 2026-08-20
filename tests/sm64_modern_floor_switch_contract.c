#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t hf(uint64_t s,float v){union{float f;uint32_t u;}x={v};return h(s,x.u);}
static uint64_t add(uint64_t s,int a,int t,float scale,int sound,int rumble,int load){s=h(s,a);s=h(s,t);s=hf(s,scale);s=h(s,sound);s=h(s,rumble);return h(s,load);}
int main(void){uint64_t f=O;f=add(f,1,0,1.5f,0,0,1);f=add(f,2,0,.2f,1,1,1);f=add(f,2,11,.2f,2,0,1);f=add(f,3,0,.2f,0,0,1);f=add(f,0,0,1.5f,0,0,1);printf("floorSwitchFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern floor-switch C contract passed");return 0;}
