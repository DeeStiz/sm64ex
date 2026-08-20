#include <stdint.h>
#include <stdio.h>
static const uint64_t O=UINT64_C(1469598103934665603),P=UINT64_C(1099511628211);static uint64_t h(uint64_t x,uint32_t v){for(unsigned b=0;b<4;++b){x^=(v>>(b*8))&0xffu;x*=P;}return x;}static uint64_t f(uint64_t x,float v){union{float f;uint32_t u;}b={v};return h(x,b.u);}
struct O{float y;int32_t timer;};static struct O u(int kind,int t,float y,int angle,int param){if(!kind)y-=angle==0x4000?.58f:0;else{if(param){if(t==0)y-=300;y+=angle==0x4000?7.0f:0;}else y-=angle==0x4000?3.0f:0;}return(struct O){y,angle+0x100};}static void a(uint64_t*x,struct O v){*x=f(*x,v.y);*x=h(*x,(uint32_t)v.timer);}
int main(void){struct O p=u(0,0,100,0x4000,0),c=u(1,0,100,0,1),co=u(1,1,100,0x4000,1),un=u(1,1,100,0x4000,0);if(p.y!=99.42f||c.y!=-200||co.y!=107||un.y!=97)return 2;uint64_t x=O;a(&x,p);a(&x,c);a(&x,co);a(&x,un);printf("bitfsSinkingPlatformFingerprint=0x%016llx\n",(unsigned long long)x);puts("SM64 Modern BITFS sinking platform C contract passed");return 0;}
