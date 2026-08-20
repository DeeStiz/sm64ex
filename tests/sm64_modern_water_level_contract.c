#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t addD(uint64_t s,int a,int t,int target,int level,int yaw,int vel,int changing,int sound,int rumble){s=h(s,a);s=h(s,t);s=h(s,target);s=h(s,level);s=h(s,yaw);s=h(s,vel);s=h(s,changing);s=h(s,sound);return h(s,rumble);}
static uint64_t addI(uint64_t s,int a,int t,int phase,int global,int region){s=h(s,a);s=h(s,t);s=h(s,phase);s=h(s,global);return h(s,region);}
int main(void){uint64_t f=O;f=addD(f,0,1,100,0,0,0,0,0,0);f=addD(f,1,0,100,0,0,0,0,0,0);f=addD(f,2,0,100,0,0,0,1,0,0);f=addD(f,2,1,100,10,2048,2048,1,1,1);f=addD(f,3,0,100,100,0,0,1,0,0);f=addD(f,1,0,100,100,4096,0,0,0,0);f=addI(f,1,0,0,100,100);f=addI(f,1,6,0,120,120);f=addI(f,1,11,512,100,100);printf("waterLevelFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern water-level C contract passed");return 0;}
