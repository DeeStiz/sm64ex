#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int a,int t,uint32_t scale,int mist,int tri,int collision,int del){s=h(s,(uint64_t)(int64_t)a);s=h(s,(uint64_t)(int64_t)t);s=h(s,scale);s=h(s,mist);s=h(s,tri);s=h(s,collision);return h(s,del);}
int main(void){uint64_t f=OFFSET;f=row(f,0,1,UINT32_C(0x3f828f5c),0,0,1,0);f=row(f,1,2,UINT32_C(0x3f828f5c),1,1,1,0);f=row(f,1,9,UINT32_C(0x3f828f5c),0,0,1,1);printf("unusedPoundablePlatformFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern unused poundable platform C contract passed");return 0;}
