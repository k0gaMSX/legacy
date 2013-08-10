/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                      pcat.h                             **/
/**                                                         **/
/** This file contains common functions and variables for   **/
/** PC-AT clone dependent subroutines and drivers.          **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1994,1995          **/
/** fMSXAT Copyright (C) MURAKAMI Reki 1995,1996            **/
/**      You are not allowed to distribute this software    **/
/**      commercially. Please, notify me, if you make any   **/
/**      changes to this file.                              **/
/*************************************************************/

#define ATOX(x) (('a'<=x && x<='f')? x-'a'+10: \
                 ('A'<=x && x<='F')? x-'A'+10: \
                 ('0'<=x && x<='9')? x-'0':0)

extern byte UseSB16;                    /* 1 if use Sound Blaster 16 */

extern word wConvMem;                   /* _go32_conventional_mem_selector() */

/******* graphics *******/
extern byte videoMode;                  /* saved video mode */

extern byte RefreshLine;                /* Start Line to put image */
extern byte RefreshMode;                /* 0:VGA 1:SVGA */

int InitGraphics(void);
int InitGraphicsVGA(void);
int InitGraphicsSVGA(void);
void PutImageVGA(byte *);
void PutImageSVGA(byte *);
void ResetGraphics(void);
void Cls(void);
void InitPalette(void);

/******** sound ********/

#define OPL3_DATA_MAX 9

extern char JoySwap1,JoySwap2;

int InitSound(void);
void ResetSound(void);

extern byte OPL3Voice[][OPL3_DATA_MAX];
