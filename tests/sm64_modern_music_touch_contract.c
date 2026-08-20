#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int action,int timer,int jingle){s=h(s,action);s=h(s,timer);return h(s,jingle);}
int main(void){uint64_t f=O;f=add(f,0,1,0);f=add(f,1,1,1);f=add(f,1,5,0);printf("musicTouchFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern music-touch C contract passed");return 0;}
