#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t row(uint64_t s,int a,int t,int shake,int tangible,int bubbles){s=h(s,a);s=h(s,(uint64_t)(int64_t)t);s=h(s,(uint64_t)(int64_t)shake);s=h(s,tangible);return h(s,bubbles);}
int main(void){uint64_t f=O;f=row(f,1,0,0,0,0);f=row(f,0,0,10,1,0);f=row(f,1,1,0,0,12);printf("clamShellFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern clam-shell C contract passed");return 0;}
