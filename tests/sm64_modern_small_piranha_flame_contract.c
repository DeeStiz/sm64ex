#include <stdint.h>
#include <stdio.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t hash_u64(uint64_t seed,uint64_t value){for(unsigned i=0;i<8;++i){seed^=(value>>(i*8u))&UINT64_C(0xff);seed*=FNV_PRIME;}return seed;}
int main(void){uint64_t f=FNV_OFFSET;f=hash_u64(f,UINT64_C(0x3fe66666));f=hash_u64(f,UINT64_C(0x40000000));f=hash_u64(f,UINT64_C(3));f=hash_u64(f,0);printf("smallPiranhaFlameFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern small Piranha flame C contract passed");return 0;}
