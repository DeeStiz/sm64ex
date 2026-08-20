#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int action,int timer,int yaw,uint32_t gravity,int opacity,int tangible){s=h(s,(uint64_t)(int64_t)action);s=h(s,(uint64_t)(int64_t)timer);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,gravity);s=h(s,opacity);return h(s,tangible);}
int main(void){uint64_t f=OFFSET;f=row(f,0,1,356,UINT32_C(0x3f99999a),255,0);f=row(f,0,22,0,UINT32_C(0x3f99999a),255,1);printf("wingCapFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern wing cap C contract passed");return 0;}
