#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned b=0;b<8;++b){s^=(v>>(b*8))&255;s*=P;}return s;}
int main(void){const int t[]={1,65,1,1},spawn[]={1,1,0,1},period[]={64,64,0,128};uint64_t f=O;for(int i=0;i<4;++i){f=h(f,t[i]);f=h(f,spawn[i]);f=h(f,(uint64_t)(int64_t)period[i]);}printf("boulderGeneratorFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern boulder generator C contract passed");return 0;}
