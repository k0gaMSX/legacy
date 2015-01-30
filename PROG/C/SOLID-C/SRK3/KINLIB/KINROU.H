#ifndef __KINROU_H
#define	__KINROU_H

/* for poor linker */
#define kinrou_init kinini
#define kinrou_play1 kinply1
#define kinrou_play2 kinply2
#define kinrou_stop kinstop
#define kinrou_fadeout kinfade
#define kinrou_getloops kinglop
#define kinrou_checkplay kinchk
#define kinrou_pause kinpau
#define kinrou_vol kinvol
#define kinrou_volpart kinvolp
#define kinrou_psgswitch kinpsw
#define kinrou_credit kincre
#define kinrou_getparam kingpr

unsigned int kinrou_init();
char kinrou_play1();
char kinrou_play2();
void kinrou_stop();
void kinrou_fadeout();
unsigned int kinrou_getloops();
char kinrou_checkplay();
void kinrou_pause();
void kinrou_vol();
void kinrou_volpart();
void kinrou_psgswitch();
unsigned char *kinrou_credit();
unsigned char *kinrou_getparam();

#endif
