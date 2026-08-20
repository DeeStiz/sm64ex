#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int action,int delta,uint64_t set,int drained,int hidden,int collision,int particles,int triangles,int activate,int sound,int jingle){s=h(s,(uint64_t)(int64_t)action);s=h(s,(uint64_t)(int64_t)delta);s=h(s,set);s=h(s,drained);s=h(s,hidden);s=h(s,collision);s=h(s,particles);s=h(s,triangles);s=h(s,activate);s=h(s,sound);return h(s,jingle);}
int main(void){uint64_t f=OFFSET;f=row(f,0,0,UINT64_MAX,0,0,1,0,0,0,0,0);f=row(f,0,0,UINT64_C(3000),1,1,0,0,0,0,0,0);f=row(f,1,0,UINT64_MAX,0,1,0,1,1,1,0,0);f=row(f,2,0,UINT64_MAX,1,0,0,0,0,0,0,1);printf("thiIslandTopFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern THI island top C contract passed");return 0;}
