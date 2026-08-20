#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned b=0;b<8;++b){s^=(v>>(b*8))&255;s*=P;}return s;}
struct R{int g,t;int32_t my,ty;float fv,vy,gr;int32_t fy;int impact,jump,shake;};
static uint64_t row(uint64_t s,struct R r){s=h(s,r.g);s=h(s,(uint64_t)(int64_t)r.t);s=h(s,(uint64_t)(int64_t)r.my);s=h(s,(uint64_t)(int64_t)r.ty);s=h(s,*(uint32_t*)&r.fv);s=h(s,*(uint32_t*)&r.vy);s=h(s,*(uint32_t*)&r.gr);s=h(s,(uint64_t)(int64_t)r.fy);s=h(s,r.impact);s=h(s,r.jump);return h(s,r.shake);}
int main(void){const struct R r[]={{1,0,0,0,0,0,-4,16384,1,0,1},{1,0,0,-32768,0,0,-4,16384,0,0,0},{0,0,0,0,11,70,-4,16384,0,1,0},{0,5,0,0,11,-1,-16,16384,0,0,0}};uint64_t f=O;for(unsigned i=0;i<4;++i)f=row(f,r[i]);printf("horizontalGrindelFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern horizontal Grindel C contract passed");return 0;}
