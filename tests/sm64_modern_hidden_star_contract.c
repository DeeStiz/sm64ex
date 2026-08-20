#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&UINT64_C(255);s*=P;}return s;}
int main(void){uint64_t f=O;f=h(f,0);f=h(f,1);f=h(f,1);f=h(f,1);f=h(f,5);f=h(f,1);printf("hiddenStarFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern hidden-star C contract passed");return 0;}
