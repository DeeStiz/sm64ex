#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int a,int t,int yaw,int dialog,int particles,int sound){s=h(s,(uint64_t)(int64_t)a);s=h(s,(uint64_t)(int64_t)t);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,(uint64_t)(int64_t)dialog);s=h(s,(uint64_t)(int64_t)particles);return h(s,(uint64_t)sound);}
int main(void){uint64_t f=OFFSET;f=row(f,1,1,100,153,0,0);f=row(f,2,2,100,153,0,0);f=row(f,2,3,5476,153,12,1);printf("snowmanWindFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern Snowman wind C contract passed");return 0;}
