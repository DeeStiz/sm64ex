#include <stdint.h>
#include <stdio.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t x,uint64_t v){for(unsigned i=0;i<8;i++){x^=(v>>(i*8u))&UINT64_C(0xff);x*=FNV_PRIME;}return x;}
int main(void){const int d[]={0,1};const int s[]={0,1};uint64_t f=FNV_OFFSET;for(unsigned i=0;i<2;i++){f=h(f,d[i]);f=h(f,s[i]);}printf("objectBubbleFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern object bubble C contract passed");return 0;}
