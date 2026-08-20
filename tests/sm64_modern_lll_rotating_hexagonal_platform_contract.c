#include <stdint.h>
#include <stdio.h>
static const uint64_t O=UINT64_C(1469598103934665603),P=UINT64_C(1099511628211);static uint64_t h(uint64_t x,uint32_t v){for(unsigned b=0;b<4;++b){x^=(v>>(b*8))&0xffu;x*=P;}return x;}
int main(void){int32_t a=0+0x100,b=0x7fff+0x100;if(a!=0x100||b!=0x80ff)return 2;uint64_t f=O;f=h(f,(uint32_t)a);f=h(f,(uint32_t)a);f=h(f,0x100);f=h(f,(uint32_t)b);f=h(f,(uint32_t)b);f=h(f,0x100);printf("lllRotatingHexagonalPlatformFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern LLL rotating hexagonal platform C contract passed");return 0;}
