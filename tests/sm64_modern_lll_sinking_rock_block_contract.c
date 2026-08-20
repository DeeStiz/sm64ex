#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);
static uint64_t hash_u32(uint64_t h, uint32_t v) { for (unsigned b=0;b<4;++b) { h ^= (v>>(b*8))&0xffu; h*=FNV_PRIME; } return h; }
static uint64_t hash_f32(uint64_t h, float v) { union { float f; uint32_t u; } b={v}; return hash_u32(h,b.u); }
struct Output { int32_t angle, endpoint; float offset, position; };
static float sine(int32_t angle) { return angle == 0 ? 0.0f : angle >= 0x4000 ? 1.0f : 0.5f; }
static struct Output update(int32_t angle, float home, int mario) {
    if (mario) { angle += 124; if (angle > 0x4000) angle=0x4000; }
    else { angle -= 124; if (angle < 0) angle=0; }
    float offset = sine(angle) * -110.0f;
    return (struct Output){angle, angle==0 || angle==0x4000, offset, home+offset};
}
static uint64_t append(uint64_t h, struct Output o) { h=hash_u32(h,(uint32_t)o.angle); h=hash_f32(h,o.offset); h=hash_f32(h,o.position); return hash_u32(h,(uint32_t)o.endpoint); }
int main(void) {
    struct Output idle=update(0,100,0), sinking=update(0x3f84,100,1), top=update(0x4000,100,1), rising=update(124,100,0);
    if (idle.angle!=0 || idle.offset!=0 || sinking.angle!=0x4000 || sinking.offset!=-110 || top.angle!=0x4000 || !top.endpoint || rising.angle!=0) return 2;
    uint64_t h=FNV_OFFSET; h=append(h,idle); h=append(h,sinking); h=append(h,top); h=append(h,rising);
    printf("lllSinkingRockBlockFingerprint=0x%016llx\n",(unsigned long long)h); puts("SM64 Modern LLL sinking rock block C contract passed"); return 0;
}
