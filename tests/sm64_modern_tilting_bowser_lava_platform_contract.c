#include <stdint.h>
#include <stdio.h>

static const uint64_t OFFSET = UINT64_C(1469598103934665603);
static const uint64_t PRIME = UINT64_C(1099511628211);
static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) { hash ^= (value >> (byte * 8)) & UINT32_C(0xff); hash *= PRIME; }
    return hash;
}
static uint64_t append(uint64_t hash, int32_t pitch, int32_t yaw, int32_t roll) {
    hash = hash_u32(hash, (uint32_t)pitch); hash = hash_u32(hash, (uint32_t)yaw); return hash_u32(hash, (uint32_t)roll);
}
int main(void) {
    int32_t pitch = 0x1000 + 3, yaw = (int32_t)0x8000 - 0x400, roll = -0x200 + 7;
    uint64_t fingerprint = append(OFFSET, pitch, yaw, roll);
    if (pitch != 0x1003 || (uint32_t)yaw != UINT32_C(0x7C00) || roll != -0x1F9) return 2;
    printf("tiltingBowserLavaPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern tilting Bowser lava platform C contract passed");
    return 0;
}
