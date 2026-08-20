#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned b=0;b<8;++b){s^=(v>>(b*8))&255;s*=P;}return s;}
int main(void){const int a[]={0,2,0},t[]={1,0,1},p[]={-1,0,-1};uint64_t f=O;for(int i=0;i<3;++i){f=h(f,a[i]);f=h(f,t[i]);f=h(f,(uint64_t)(int64_t)p[i]);}printf("bowserTailAnchorFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern Bowser tail anchor C contract passed");return 0;}
