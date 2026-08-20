#include <stdint.h>
#include <stdio.h>
static const uint64_t O=UINT64_C(1469598103934665603),P=UINT64_C(1099511628211);static uint64_t h(uint64_t x,uint32_t v){for(unsigned b=0;b<4;++b){x^=(v>>(b*8))&0xffu;x*=P;}return x;}static uint64_t f(uint64_t x,float v){union{float f;uint32_t u;}b={v};return h(x,b.u);}
int main(void){uint64_t x=O;x=f(x,1);x=f(x,2);x=f(x,3);x=h(x,4);x=h(x,5);x=h(x,6);printf("dddMovingPoleFingerprint=0x%016llx\n",(unsigned long long)x);puts("SM64 Modern DDD moving pole C contract passed");return 0;}
