#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define MAGIC UINT32_C(0x50524D53)
#define HEADER_SIZE 64
#define RECORD_SIZE 128
#define RECORD_COUNT 3
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint32_t get32(const uint8_t *bytes, size_t offset) {
    return (uint32_t)bytes[offset]
        | (uint32_t)bytes[offset + 1] << 8
        | (uint32_t)bytes[offset + 2] << 16
        | (uint32_t)bytes[offset + 3] << 24;
}

static uint64_t get64(const uint8_t *bytes, size_t offset) {
    uint64_t value = 0;
    for (size_t index = 0; index < 8; ++index) {
        value |= (uint64_t)bytes[offset + index] << (index * 8);
    }
    return value;
}

static void put32(uint8_t *bytes, size_t offset, uint32_t value) {
    for (size_t index = 0; index < 4; ++index) {
        bytes[offset + index] = (uint8_t)(value >> (index * 8));
    }
}

static void put64(uint8_t *bytes, size_t offset, uint64_t value) {
    for (size_t index = 0; index < 8; ++index) {
        bytes[offset + index] = (uint8_t)(value >> (index * 8));
    }
}

static uint64_t hash_bytes(const uint8_t *bytes, size_t count) {
    uint64_t hash = FNV_OFFSET;
    for (size_t index = 0; index < count; ++index) {
        hash = (hash ^ bytes[index]) * FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_artifact(const uint8_t *bytes) {
    uint64_t hash = FNV_OFFSET;
    for (size_t index = 0; index < 48; ++index) {
        hash = (hash ^ bytes[index]) * FNV_PRIME;
    }
    for (size_t index = HEADER_SIZE; index < HEADER_SIZE + RECORD_SIZE * RECORD_COUNT; ++index) {
        hash = (hash ^ bytes[index]) * FNV_PRIME;
    }
    return hash;
}

static int read_file(const char *path, uint8_t **out_bytes, size_t *out_size) {
    FILE *file = fopen(path, "rb");
    if (!file) return 0;
    if (fseek(file, 0, SEEK_END) != 0) { fclose(file); return 0; }
    long length = ftell(file);
    if (length < 0 || fseek(file, 0, SEEK_SET) != 0) { fclose(file); return 0; }
    uint8_t *bytes = (uint8_t *)malloc((size_t)length);
    if (!bytes || fread(bytes, 1, (size_t)length, file) != (size_t)length) {
        free(bytes); fclose(file); return 0;
    }
    fclose(file);
    *out_bytes = bytes;
    *out_size = (size_t)length;
    return 1;
}

static int write_file(const char *path, const uint8_t *bytes, size_t size) {
    FILE *file = fopen(path, "wb");
    if (!file) return 0;
    const int wrote = fwrite(bytes, 1, size, file) == size;
    const int closed = fclose(file) == 0;
    return wrote && closed;
}

static int verify_artifact(const uint8_t *bytes, size_t size) {
    if (size != HEADER_SIZE + RECORD_SIZE * RECORD_COUNT
        || get32(bytes, 0) != MAGIC
        || get32(bytes, 4) != 1
        || get32(bytes, 8) != HEADER_SIZE
        || get32(bytes, 12) != RECORD_SIZE
        || get32(bytes, 24) != RECORD_COUNT) {
        return 0;
    }
    if (get64(bytes, 48) != hash_bytes(bytes, 48)
        || get64(bytes, 56) != hash_artifact(bytes)) {
        return 0;
    }
    for (size_t index = 0; index < RECORD_COUNT; ++index) {
        const size_t offset = HEADER_SIZE + index * RECORD_SIZE;
        if (get32(bytes, offset) != 1 || get32(bytes, offset + 4) != RECORD_SIZE
            || get64(bytes, offset + 112) != hash_bytes(bytes + offset, 112)) {
            return 0;
        }
    }
    return 1;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: %s swift-artifact c-artifact\n", argv[0]);
        return 2;
    }
    uint8_t *bytes = NULL;
    size_t size = 0;
    if (!read_file(argv[1], &bytes, &size) || !verify_artifact(bytes, size)
        || get32(bytes, 16) != 1 || get32(bytes, 20) != 1) {
        fprintf(stderr, "save replay artifact C verification failed\n");
        free(bytes);
        return 1;
    }

    // Emit a second artifact from the C side with the authority switched to
    // compatibility and the replay directions reversed. Swift reads this
    // file in the second half of the shell test.
    put32(bytes, 16, 2);
    put32(bytes, 20, 0);
    for (size_t index = 0; index < RECORD_COUNT; ++index) {
        const size_t offset = HEADER_SIZE + index * RECORD_SIZE;
        put32(bytes, offset + 24, index == 2 ? 1 : 2);
        put64(bytes, offset + 112, hash_bytes(bytes + offset, 112));
    }
    put64(bytes, 48, hash_bytes(bytes, 48));
    put64(bytes, 56, hash_artifact(bytes));
    if (!write_file(argv[2], bytes, size)) {
        fprintf(stderr, "save replay artifact C write failed\n");
        free(bytes);
        return 1;
    }
    printf("saveReplayArtifactCVerifiedFingerprint=0x%016llx\n",
           (unsigned long long)get64(bytes, 56));
    free(bytes);
    return 0;
}
