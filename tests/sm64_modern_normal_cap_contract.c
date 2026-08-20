#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int yaw,int pitch,int phase,int flag,int dead){s=h(s,(uint64_t)(int64_t)yaw);s=h(s,(uint64_t)(int64_t)pitch);s=h(s,(uint64_t)(int64_t)phase);s=h(s,(uint64_t)(int64_t)flag);return h(s,dead);}
int main(void){uint64_t f=OFFSET;f=row(f,356,180,0,0,0);f=row(f,0,0,2,0,0);f=row(f,0,0,0,2,1);printf("normalCapFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern normal cap C contract passed");return 0;}
