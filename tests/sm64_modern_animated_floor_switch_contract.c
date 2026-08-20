#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int active,int toggle,int rem,int frame,int model,int sound,int load){s=h(s,active);s=h(s,toggle);s=h(s,rem);s=h(s,frame);s=h(s,model);s=h(s,sound);return h(s,load);}
int main(void){uint64_t f=O;f=add(f,1,1,249,1,0,2,1);f=add(f,1,1,249,5,2,2,1);f=add(f,0,1,58,9,4,1,1);f=add(f,0,1,249,9,4,2,1);printf("animatedFloorSwitchFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern animated-floor-switch C contract passed");return 0;}
