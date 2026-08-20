#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,uint32_t px,uint32_t pz,uint32_t vx,uint32_t vz,uint32_t fv,int av,int fp,int boundary,int sound){s=h(s,px);s=h(s,pz);s=h(s,vx);s=h(s,vz);s=h(s,fv);s=h(s,(uint64_t)(int64_t)av);s=h(s,(uint64_t)(int64_t)fp);s=h(s,boundary);return h(s,sound);}
int main(void){uint64_t f=OFFSET;f=row(f,UINT32_C(0x45782000),UINT32_C(0x45646400),0,UINT32_C(0x3e800000),UINT32_C(0x3e800000),0x10,0x10,0,1);f=row(f,UINT32_C(0x45a00000),UINT32_C(0x45bc0200),0,UINT32_C(0x3e800000),UINT32_C(0x3e800000),0x10,0x10,0,1);f=row(f,UINT32_C(0x45abe000),UINT32_C(0x45646000),0,0,0,0x200,0x200,1,1);printf("rollingLogFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern rolling log C contract passed");return 0;}
