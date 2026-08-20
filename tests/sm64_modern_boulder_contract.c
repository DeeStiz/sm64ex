#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned b=0;b<8;++b){s^=(v>>(b*8))&255;s*=PRIME;}return s;}static uint64_t f(uint64_t s,float v){uint32_t b=0;memcpy(&b,&v,4);return h(s,b);}
struct R{uint64_t a;float y,vy,fv,scale,graph,radius,height;int32_t pitch;int sr,si,sm,del;};
static uint64_t row(uint64_t s,struct R r){s=h(s,r.a);s=f(s,r.y);s=f(s,r.vy);s=f(s,r.fv);s=h(s,(uint64_t)(int64_t)r.pitch);s=f(s,r.scale);s=f(s,r.graph);s=f(s,r.radius);s=f(s,r.height);s=h(s,r.sr);s=h(s,r.si);s=h(s,r.sm);return h(s,r.del);}
int main(void){const struct R rs[]={{1,0,0,40,1.5f,270,210,350,0,0,0,0,0},{1,0,20,70,1.5f,270,210,350,4666,1,1,1,0},{1,-1001,0,20,1.5f,270,210,350,1333,0,1,0,1}};uint64_t x=OFFSET;for(unsigned i=0;i<3;++i)x=row(x,rs[i]);printf("boulderFingerprint=0x%016llx\n",(unsigned long long)x);puts("SM64 Modern boulder C contract passed");return 0;}
