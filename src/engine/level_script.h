#ifndef LEVEL_SCRIPT_H
#define LEVEL_SCRIPT_H

#include <PR/ultratypes.h>

struct LevelCommand;

extern u8 level_script_entry[];

struct LevelCommand *level_script_execute(struct LevelCommand *cmd);

// Test-only host bootstrap: choose the save/level register before entering the
// stock main level script. Normal title/menu startup never calls this helper.
void sm64_modern_level_script_set_register(s32 value);

#endif // LEVEL_SCRIPT_H
