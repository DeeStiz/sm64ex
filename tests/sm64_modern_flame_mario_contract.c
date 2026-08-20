#include <stdint.h>
#include <stdio.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;++i){s^=(v>>(i*8u))&UINT64_C(0xff);s*=FNV_PRIME;}return s;}
int main(void){uint64_t f=FNV_OFFSET;f=h(f,UINT64_C(0x41200000));f=h(f,UINT64_C(0x42A00000));f=h(f,UINT64_C(0x42100000));f=h(f,UINT64_C(0x40000000));f=h(f,1);f=h(f,0);f=h(f,0);printf("flameMarioFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern flame Mario C contract passed");return 0;}
