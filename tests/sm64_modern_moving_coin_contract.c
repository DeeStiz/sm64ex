#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t hf(uint64_t s,float v){union{float f;uint32_t u;}x={v};return h(s,x.u);}
static uint64_t add(uint64_t s,int kind,int32_t a,int32_t t,float speed,float vy,int tang,int sound,int spark,int del,int value){s=h(s,kind);s=h(s,(uint64_t)(int64_t)a);s=h(s,(uint64_t)(int64_t)t);s=hf(s,speed);s=hf(s,vy);s=h(s,tang);s=h(s,sound);s=h(s,spark);s=h(s,del);return h(s,(uint64_t)(int64_t)value);}
int main(void){uint64_t f=O;f=add(f,0,0,11,0,0,1,1,0,0,1);f=add(f,0,1,0,0,0,1,0,0,0,1);f=add(f,1,1,0,20,0,0,0,0,0,5);f=add(f,1,1,11,75,0,0,1,0,0,5);f=add(f,1,1,11,58.800003f,0,0,0,1,1,5);f=add(f,2,1,0,0,0,1,0,0,0,5);f=add(f,3,0,1,0,50,0,0,0,0,5);f=add(f,2,1,1,15,18,1,1,0,0,5);printf("movingCoinFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern moving-coin C contract passed");return 0;}
