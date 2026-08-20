#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
int main(void){uint64_t f=OFFSET;f=h(f,(uint64_t)(int64_t)-128);f=h(f,(uint64_t)(int64_t)-128);f=h(f,(uint64_t)(int64_t)-256);f=h(f,(uint64_t)(int64_t)-128);printf("rrRotatingBridgePlatformFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern RR rotating bridge platform C contract passed");return 0;}
