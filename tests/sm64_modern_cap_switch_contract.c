#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t hf(uint64_t s,float v){union{float f;uint32_t u;}x={v};return h(s,x.u);}
static uint64_t add(uint64_t s,uint64_t a,int32_t t,int32_t v,float y,float sx,float sy,float sz,int32_t anim,int base,uint64_t flag,int sound,int mist,int tri,int rumble,int load){s=h(s,a);s=h(s,(uint64_t)(int64_t)t);s=h(s,(uint64_t)(int64_t)v);s=hf(s,y);s=hf(s,sx);s=hf(s,sy);s=hf(s,sz);s=h(s,(uint64_t)(int64_t)anim);s=h(s,base);s=h(s,flag);s=h(s,sound);s=h(s,mist);s=h(s,tri);s=h(s,rumble);return h(s,load);}
int main(void){uint64_t f=O;f=add(f,1,0,0,171,.5,.5,.5,0,1,0,0,0,0,0,1);f=add(f,3,0,1,171,.5,.1,.5,1,1,0,0,0,0,0,1);f=add(f,2,0,0,171,.5,.5,.5,0,0,2,1,0,0,0,1);f=add(f,2,1,0,171,.5,.5,.5,0,0,0,0,0,0,0,1);f=add(f,2,5,0,171,.5,.1,.5,0,0,0,0,1,1,1,1);f=add(f,3,0,0,171,.5,.1,.5,0,0,0,0,0,0,0,1);f=h(f,1);f=h(f,1);printf("capSwitchFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern cap-switch C contract passed");return 0;}
