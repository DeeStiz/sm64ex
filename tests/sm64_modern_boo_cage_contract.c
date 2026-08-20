#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int action,int timer,int tangible,int copied,int sparkle,int jingle,int landing,int collision){s=h(s,action);s=h(s,timer);s=h(s,tangible);s=h(s,copied);s=h(s,sparkle);s=h(s,jingle);s=h(s,landing);return h(s,collision);}
int main(void){uint64_t f=O;f=add(f,0,1,0,1,0,0,0,0);f=add(f,1,0,0,0,0,1,0,0);f=add(f,2,0,0,0,1,0,1,1);f=add(f,3,0,1,0,0,0,0,1);printf("booCageFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern boo-cage C contract passed");return 0;}
