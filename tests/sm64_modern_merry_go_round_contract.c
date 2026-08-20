#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int timer,int yaw,int velocity,int latched,int wind,int music,int stop,int collision){s=h(s,timer);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,(uint64_t)(int64_t)velocity);s=h(s,latched);s=h(s,wind);s=h(s,music);s=h(s,stop);return h(s,collision);}
int main(void){uint64_t f=O;f=add(f,1,228,128,1,0,1,0,1);f=add(f,2,328,128,1,1,1,0,1);f=add(f,3,300,0,0,1,0,1,1);printf("merryGoRoundFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern merry-go-round C contract passed");return 0;}
