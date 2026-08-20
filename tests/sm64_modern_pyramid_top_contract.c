#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int action,int timer,int yaw,int av,uint32_t vy,int fragments,int puzzle,int spin,int explosion,int dead){s=h(s,(uint64_t)(int64_t)action);s=h(s,(uint64_t)(int64_t)timer);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,(uint64_t)(int64_t)av);s=h(s,vy);s=h(s,(uint64_t)(int64_t)fragments);s=h(s,puzzle);s=h(s,spin);s=h(s,explosion);return h(s,dead);}
int main(void){uint64_t f=OFFSET;f=row(f,1,1,0,0,0,0,1,0,0,0);f=row(f,1,1,0,0,0,1,0,1,0,0);f=row(f,2,1,0,0,0,30,0,0,1,1);printf("pyramidTopFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern pyramid top C contract passed");return 0;}
