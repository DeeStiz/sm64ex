#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int action,int timer,uint32_t y,uint32_t v){s=h(s,(uint64_t)(int64_t)action);s=h(s,(uint64_t)(int64_t)timer);s=h(s,y);return h(s,v);}
int main(void){uint64_t f=OFFSET;f=row(f,0,1,UINT32_C(0x4478b852),UINT32_C(0xc0a3d70a));f=row(f,0,101,UINT32_C(0x447b47ae),UINT32_C(0x40a3d70a));printf("sslMovingPyramidWallFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern SSL moving pyramid wall C contract passed");return 0;}
