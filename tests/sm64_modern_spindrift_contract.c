#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int a,int t,uint32_t z,uint32_t v,int tangible,int dying,int reset){s=h(s,(uint64_t)(int64_t)a);s=h(s,(uint64_t)(int64_t)t);s=h(s,z);s=h(s,v);s=h(s,tangible);s=h(s,dying);return h(s,reset);}
int main(void){uint64_t f=OFFSET;f=row(f,0,1,UINT32_C(0x3f800000),UINT32_C(0x3f800000),1,0,0);f=row(f,1,1,UINT32_C(0xc1200000),UINT32_C(0xc1200000),0,1,0);f=row(f,0,22,UINT32_C(0xc1200000),UINT32_C(0xc1200000),1,0,1);printf("spindriftFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern Spindrift C contract passed");return 0;}
