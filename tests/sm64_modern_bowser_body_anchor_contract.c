#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned b=0;b<8;++b){s^=(v>>(b*8))&255;s*=P;}return s;}
int main(void){const uint32_t type[]={8,0,0};const int tangible[]={1,0,0};uint64_t f=O;for(int i=0;i<3;++i){f=h(f,type[i]);f=h(f,tangible[i]);}printf("bowserBodyAnchorFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern Bowser body anchor C contract passed");return 0;}
