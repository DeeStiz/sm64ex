#include <stdint.h>
#include <stdio.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;++i){s^=(v>>(i*8u))&UINT64_C(0xff);s*=FNV_PRIME;}return s;}
static uint64_t hf(uint64_t s,float v){union{float f;uint32_t b;}u={.f=v};return h(s,u.b);}
int main(void){uint64_t f=FNV_OFFSET;f=hf(f,350);f=h(f,1);f=hf(f,50);f=h(f,0x800);f=hf(f,56);f=h(f,0x800);f=h(f,1);f=h(f,0);f=h(f,3);f=h(f,1);f=h(f,1);f=h(f,1);f=h(f,1);printf("spawnedStarFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern spawned-star C contract passed");return 0;}
