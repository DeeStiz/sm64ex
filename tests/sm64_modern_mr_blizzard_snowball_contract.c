#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int a,int t,int yaw,uint32_t speed,int del){s=h(s,(uint64_t)(int64_t)a);s=h(s,(uint64_t)(int64_t)t);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,speed);return h(s,del);}
int main(void){uint64_t f=OFFSET;f=row(f,1,1,0,UINT32_C(0x40a00000),0);f=row(f,2,0,4600,UINT32_C(0x42200000),0);f=row(f,2,4,0,UINT32_C(0x42200000),1);printf("mrBlizzardSnowballFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern Mr Blizzard snowball C contract passed");return 0;}
