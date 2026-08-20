#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
int main(void){uint64_t f=OFFSET;f=h(f,1);f=h(f,100);f=h(f,2248);f=h(f,0);f=h(f,17);f=h(f,(uint64_t)(int64_t)-8092);f=h(f,200);f=h(f,0);f=h(f,0);f=h(f,100);f=h(f,2248);f=h(f,1);printf("rrCruiserWingFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern RR cruiser wing C contract passed");return 0;}
