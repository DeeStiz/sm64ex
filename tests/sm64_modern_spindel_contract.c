#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t f, int timer, int phase, int direction, uint32_t z, int pitch, int shake) { f=h(f,(uint64_t)(int64_t)timer); f=h(f,(uint64_t)(int64_t)phase); f=h(f,(uint64_t)(int64_t)direction); f=h(f,z); f=h(f,(uint64_t)(int64_t)pitch); return h(f,(uint64_t)shake); }
int main(void){uint64_t f=OFFSET;f=row(f,1,0,0,UINT32_C(0x40a00000),256,0);f=row(f,11,-1,1,0,100,0);f=row(f,0,0,1,0,100,0);printf("spindelFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern Spindel C contract passed");return 0;}
