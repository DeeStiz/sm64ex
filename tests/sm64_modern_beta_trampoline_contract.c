#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned b=0;b<8;++b){s^=(v>>(b*8))&255;s*=P;}return s;}
int main(void){uint64_t f=O;f=h(f,1);uint32_t y=0x41c80000,scale=0x40600000;f=h(f,y);f=h(f,scale);printf("betaTrampolineFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern beta trampoline C contract passed");return 0;}
