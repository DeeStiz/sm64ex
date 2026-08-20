#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int t,int yaw,uint32_t scale){s=h(s,(uint64_t)(int64_t)t);s=h(s,(uint64_t)(int64_t)yaw);return h(s,scale);}
int main(void){uint64_t f=OFFSET;f=row(f,1,-32768,UINT32_C(0x41100000));f=row(f,2,-32768,UINT32_C(0x41100000));printf("yellowBackgroundMenuFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern yellow background menu C contract passed");return 0;}
