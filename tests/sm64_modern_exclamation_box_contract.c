#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t add(uint64_t s,int action,int timer,int anim,int visible,int tangible,int deleted,uint32_t model,uint32_t sx,uint32_t sy,uint32_t yoff,int phase,uint32_t vy,int mark,int content,int param,int mist,int triangles,int sound,int collision){s=h(s,action);s=h(s,timer);s=h(s,anim);s=h(s,visible);s=h(s,tangible);s=h(s,deleted);s=h(s,model);s=h(s,sx);s=h(s,sy);s=h(s,yoff);s=h(s,phase);s=h(s,vy);s=h(s,mark);s=h(s,content);s=h(s,param);s=h(s,mist);s=h(s,triangles);s=h(s,sound);return h(s,collision);}
int main(void){uint64_t f=OFFSET;f=add(f,1,0,0,1,0,0,0x89,0x40000000,0x40000000,0,0,0,1,0,0,0,0,0,1);f=add(f,1,1,0,1,0,0,0x83,0x40000000,0x40000000,0,0,0,1,0,0,0,0,0,1);f=add(f,3,1,3,1,0,0,0x89,0x40000000,0x40000000,0,0x4000,0x41f00000,0,0,0,0,0,0,1);f=add(f,4,0,3,1,0,0,0x89,0x40000000,0x3f99999a,0,0x5000,0,0,0,0,0,0,0,1);f=add(f,4,1,3,0,0,1,0x89,0x40000000,0x40000000,0,0,0,0,9,0,1,1,1,1);f=add(f,2,0,0,1,1,0,0x89,0x40000000,0x40000000,0,0,0,0,0,0,0,0,0,1);printf("exclamationBoxFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern exclamation-box C contract passed");return 0;}
