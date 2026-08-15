#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Owner { uint16_t slot; uint32_t generation; };

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

int main(void) {
    struct Owner owner_a = { 2, 1 };
    struct Owner owner_b = { 7, 1 };
    struct Owner recycled_a = { 2, 2 };
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_u32(fingerprint, owner_a.slot);
    fingerprint = hash_u32(fingerprint, owner_a.generation);
    /* A replaces [10,11] with [12], B is removed, and the applied dynamic
       surface list is therefore [12]. */
    fingerprint = hash_u32(fingerprint, 12);
    printf("platformCollisionRegistryFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern platform collision registry C contract matched\n");
    return owner_a.slot == recycled_a.slot && owner_a.generation != recycled_a.generation
        && owner_b.slot != owner_a.slot ? 0 : 1;
}
