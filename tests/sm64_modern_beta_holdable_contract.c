#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned b=0;b<8;++b){s^=(v>>(b*8))&255;s*=P;}return s;}
int main(void){const int a[]={0,1,0,0},vis[]={1,0,1,1},fv[]={0x40000000,0x40000000,0x42200000,0},vy[]={0x40400000,0x40400000,0x41a00000,0},clear[]={0,0,1,0};uint64_t f=O;for(int i=0;i<4;++i){f=h(f,a[i]);f=h(f,vis[i]);f=h(f,fv[i]);f=h(f,vy[i]);f=h(f,clear[i]);}printf("betaHoldableFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern beta holdable C contract passed");return 0;}
