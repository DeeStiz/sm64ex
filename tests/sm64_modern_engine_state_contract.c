#include <stdio.h>

#include "game/memory.h"
#include "game/object_list_processor.h"
#include "level_table.h"

int main(void) {
    printf("contract=levelMin:%d;objectArena:%d;effectsArena:%d;timeStopMask:0x%02x;initialArea:0;initialTimeStop:0;initialObjectCounter:0\n",
           LEVEL_MIN,
           0x800,
           0x4000,
           TIME_STOP_UNKNOWN_0 | TIME_STOP_ENABLED | TIME_STOP_DIALOG
               | TIME_STOP_MARIO_AND_DOORS | TIME_STOP_ALL_OBJECTS
               | TIME_STOP_MARIO_OPENED_DOOR | TIME_STOP_ACTIVE);
    return 0;
}
