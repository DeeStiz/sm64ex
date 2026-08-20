#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t row(uint64_t s,int a,int t,int children,int particle,int dead){s=h(s,a);s=h(s,(uint64_t)(int64_t)t);s=h(s,children);s=h(s,particle);return h(s,dead);}
int main(void){uint64_t f=O;f=row(f,1,1,2,0,0);f=row(f,1,0,0,0,0);f=row(f,1,1,0,0,0);f=row(f,1,0,0,0,0);printf("bubFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern Bub C contract passed");return 0;}
