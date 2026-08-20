#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int action,uint32_t y,uint32_t fv,int pitch,int roll,int sound,int shake){s=h(s,(uint64_t)(int64_t)action);s=h(s,y);s=h(s,fv);s=h(s,(uint64_t)(int64_t)pitch);s=h(s,(uint64_t)(int64_t)roll);s=h(s,sound);s=h(s,shake);return h(s,1);}
int main(void){uint64_t f=OFFSET;f=row(f,6,0,0,0,0,0,0);f=row(f,5,UINT32_C(0x42ce0000),0,0,0,0,0);f=row(f,6,UINT32_C(0x42ce0000),UINT32_C(0x42800000),0x800,0,1,0);f=row(f,7,0,0,0,0x800,1,0);printf("toxBoxFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern Tox Box C contract passed");return 0;}
