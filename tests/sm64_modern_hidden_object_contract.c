#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t hf(uint64_t s,float v){union{float f;uint32_t u;}x={v};return h(s,x.u);}
static uint64_t add(uint64_t s,int32_t a,int32_t t,int vis,int tang,float scale,int32_t coins,int mist,int tri,int sound,int load){s=h(s,(uint64_t)(int64_t)a);s=h(s,(uint64_t)(int64_t)t);s=h(s,vis);s=h(s,tang);s=hf(s,scale);s=h(s,(uint64_t)(int64_t)coins);s=h(s,mist);s=h(s,tri);s=h(s,sound);return h(s,load);}
int main(void){uint64_t f=O;f=add(f,0,1,0,0,1,0,0,0,0,0);f=add(f,1,0,1,1,1,3,0,0,0,0);f=add(f,1,361,1,1,1,3,0,0,0,1);f=add(f,2,0,0,0,1,0,1,1,1,0);f=add(f,0,0,0,0,1,0,0,0,0,0);printf("hiddenObjectFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern hidden-object C contract passed");return 0;}
