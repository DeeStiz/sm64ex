#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t hf(uint64_t s,float v){union{float f;uint32_t u;}x={v};return h(s,x.u);}
static uint64_t add(uint64_t s,int a,int t,float y,int e0,int e2,int mist,int sound,int jingle,int save){s=h(s,a);s=h(s,t);s=hf(s,y);s=h(s,(uint64_t)(int64_t)e0);s=h(s,(uint64_t)(int64_t)e2);s=h(s,mist);s=h(s,sound);s=h(s,jingle);return h(s,save);}
int main(void){uint64_t f=O;f=add(f,1,0,100,0,0,1,0,0,0);f=add(f,2,0,40,0,0,0,0,0,0);f=add(f,4,0,0,0,0,0,0,1,1);f=add(f,4,1,0,-105,-105,0,1,0,0);f=add(f,5,0,0,-2450,-2450,0,1,0,0);f=add(f,5,1,20,-2450,-2450,0,0,0,0);printf("waterPillarFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern water-pillar C contract passed");return 0;}
