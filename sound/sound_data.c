unsigned char gSoundDataADSR[] = {
#include "sound/sound_data.ctl.inc.c"
};

unsigned char gSoundDataRaw[] = {
#include "sound/sound_data.tbl.inc.c"
};

unsigned char gMusicData[] = {
#include "sound/sequences.bin.inc.c"
};

// Audio initialization performs the original fixed 0x100-byte DMA. Pad the
// generated table to that complete accessible range instead of reading beyond
// a shorter regional payload into adjacent globals.
unsigned char gBankSetsData[0x100] = {
#include "sound/bank_sets.inc.c"
};
