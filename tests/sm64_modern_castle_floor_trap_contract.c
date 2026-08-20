#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int role,int action,int timer,int roll,int velocity,int sound,int parent,int clear,int collision){s=h(s,role);s=h(s,action);s=h(s,timer);s=h(s,(uint64_t)(int64_t)roll);s=h(s,(uint64_t)(int64_t)velocity);s=h(s,sound);s=h(s,parent);s=h(s,clear);return h(s,collision);}
int main(void){uint64_t f=O;f=add(f,0,1,1,0,1024,0,0,0,0);f=add(f,0,1,1,768,768,1,0,0,0);f=add(f,1,0,1,-16384,0,0,1,0,1);f=add(f,0,0,1,0,1024,0,0,1,0);printf("castleFloorTrapFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern castle-floor-trap C contract passed");return 0;}
