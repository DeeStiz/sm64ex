#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "game/object_list_processor.h"
#include "object_constants.h"

static uint32_t float_bits(float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

int main(void) {
    static const int update_order[] = {
        OBJ_LIST_SPAWNER,
        OBJ_LIST_SURFACE,
        OBJ_LIST_POLELIKE,
        OBJ_LIST_PLAYER,
        OBJ_LIST_PUSHABLE,
        OBJ_LIST_GENACTOR,
        OBJ_LIST_DESTRUCTIVE,
        OBJ_LIST_LEVEL,
        OBJ_LIST_DEFAULT,
        OBJ_LIST_UNIMPORTANT,
    };

    printf("contract=capacity:%d;numLists:%d;updateOrder:", OBJECT_POOL_CAPACITY, NUM_OBJ_LISTS);
    for (size_t index = 0; index < sizeof(update_order) / sizeof(update_order[0]); ++index) {
        if (index != 0) {
            putchar(',');
        }
        printf("%d", update_order[index]);
    }
    printf(";active:0x%04x;unimportant:0x%04x;hitboxRadius:0x%08x;hitboxHeight:0x%08x;collisionDistance:0x%08x;drawingDistance:0x%08x;distanceToMario:0x%08x;gfxOrigin:0x%08x\n",
           ACTIVE_FLAG_ACTIVE | ACTIVE_FLAG_UNK8,
           ACTIVE_FLAG_ACTIVE | ACTIVE_FLAG_UNK8 | ACTIVE_FLAG_UNIMPORTANT,
           float_bits(50.0f),
           float_bits(100.0f),
           float_bits(1000.0f),
           float_bits(4000.0f),
           float_bits(19000.0f),
           float_bits(-10000.0f));
    return 0;
}
