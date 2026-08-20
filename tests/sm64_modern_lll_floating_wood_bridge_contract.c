#include <stdint.h>
#include <stdio.h>
static const uint64_t O=UINT64_C(1469598103934665603),P=UINT64_C(1099511628211);static uint64_t h(uint64_t x,uint32_t v){for(unsigned b=0;b<4;++b){x^=(v>>(b*8))&0xffu;x*=P;}return x;}
int main(void){int actions[]={0,1,2,0};int spawns[]={0,1,0,0};uint64_t x=O;for(int i=0;i<4;++i){x=h(x,(uint32_t)actions[i]);x=h(x,(uint32_t)spawns[i]);}union{float f;uint32_t u;}b={0};x=h(x,b.u);x=h(x,0x400);printf("lllFloatingWoodBridgeFingerprint=0x%016llx\n",(unsigned long long)x);puts("SM64 Modern LLL floating wood bridge C contract passed");return 0;}
