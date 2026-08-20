#include <stdint.h>
#include <stdio.h>
static const uint64_t O=UINT64_C(1469598103934665603),P=UINT64_C(1099511628211);static uint64_t h(uint64_t x,uint32_t v){for(unsigned b=0;b<4;++b){x^=(v>>(b*8))&0xffu;x*=P;}return x;}
struct O{int32_t action,spawn;};static struct O u(int a,float my,float hy){struct O o={a,0};if(a==0){if(my>hy-1000)o.action=1;}else if(a==1){o.action=2;o.spawn=1;}else if(a==2){if(my<hy-1000)o.action=3;}else if(a==3)o.action=0;return o;}
static void ap(uint64_t*x,struct O o){*x=h(*x,(uint32_t)o.action);*x=h(*x,(uint32_t)o.spawn);}
int main(void){struct O idle=u(0,0,2000),approach=u(0,1100,2000),spawn=u(1,1100,2000),leave=u(2,900,2000),reset=u(3,900,2000);if(idle.action!=0||idle.spawn||approach.action!=1||spawn.action!=2||!spawn.spawn||leave.action!=3||reset.action!=0)return 2;uint64_t x=O;ap(&x,idle);ap(&x,approach);ap(&x,spawn);ap(&x,leave);ap(&x,reset);printf("wfTowerPlatformGroupFingerprint=0x%016llx\n",(unsigned long long)x);puts("SM64 Modern WF tower platform group C contract passed");return 0;}
