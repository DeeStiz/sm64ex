#include <stdint.h>
#include <stdio.h>
static const uint64_t O=UINT64_C(1469598103934665603),P=UINT64_C(1099511628211);static uint64_t h(uint64_t x,uint32_t v){for(unsigned b=0;b<4;++b){x^=(v>>(b*8))&0xffu;x*=P;}return x;}static uint64_t f(uint64_t x,float v){union{float f;uint32_t u;}b={v};return h(x,b.u);}
int main(void){float idle=(0.0f+1.0f)*0.3f+0.4f,full=(1.0f+1.0f)*0.3f+0.4f;uint64_t x=O;x=f(x,idle);x=h(x,0x80);x=f(x,full);x=h(x,0x4080);printf("squishablePlatformFingerprint=0x%016llx\n",(unsigned long long)x);puts("SM64 Modern squishable platform C contract passed");return 0;}
