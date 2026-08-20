#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int initialized,int frame,int timer){s=h(s,initialized);s=h(s,frame);return h(s,timer);}
int main(void){uint64_t f=O;f=add(f,1,27,1);f=add(f,1,12,1);printf("castleFlagFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern castle-flag C contract passed");return 0;}
