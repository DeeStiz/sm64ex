#include <stdint.h>
#include <stdio.h>
#include <math.h>
#define H UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t x,uint64_t v){for(unsigned i=0;i<8;i++){x^=(v>>(i*8u))&0xff;x*=P;}return x;}
int main(void){int opacity=212,scale=(int)round((((254-opacity)/254.0)+.5)*1000);uint64_t f=H;f=h(f,(uint64_t)(int64_t)opacity);f=h(f,(uint64_t)(int64_t)scale);f=h(f,0);printf("waterMistFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern water mist C contract passed");return 0;}
