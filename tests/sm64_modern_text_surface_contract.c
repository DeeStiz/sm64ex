#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int kind,int timer,int collision,int text,uint32_t radius,uint32_t height,int reset){s=h(s,kind);s=h(s,timer);s=h(s,collision);s=h(s,text);s=h(s,radius);s=h(s,height);return h(s,reset);}
int main(void){uint64_t f=O;f=add(f,0,1,1,1,0x43160000,0x42a00000,1);f=add(f,1,5,0,1,0x43160000,0x42a00000,1);printf("textSurfaceFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern text-surface C contract passed");return 0;}
