/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                      pc98.h                             **/
/**                                                         **/
/** This file contains common functions and variables for   **/
/** PC-9800 dependent subroutines and drivers.              **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1994,1995          **/
/** fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            **/
/**      You are not allowed to distribute this software    **/
/**      commercially. Please, notify me, if you make any   **/
/**      changes to this file.                              **/
/*************************************************************/

#define WAIT(x) {for(i=0;i<x;i++) outportb(0x5f,0);}
#define ATOX(x) (('a'<=x && x<='f')? x-'a'+10: \
                 ('A'<=x && x<='F')? x-'A'+10: \
                 ('0'<=x && x<='9')? x-'0':0)

extern byte UseCDrive;                   /* 1 if use drive C: D:      */

/******** graphics *******/
int InitGraphics(void);
void ResetGraphics(void);
void Cls(void);

int InitGraphicsN(void);
void ResetGraphicsN(void);
void ClsN(void);
void ColorsScrFN(byte );
int InitScrFN(void);
void PutImageN(byte *);

int InitGraphics21(void);
void ResetGraphics21(void);
void Cls21(void);
void ColorsScrF21(byte );
int InitScrF21(void);
void PutImage21(byte *);

#ifdef 0
int InitGraphicsdr(void);
void ResetGraphicsdr(void);
void Clsdr(void);
void ColorsScrFdr(byte );
int InitScrFdr(void);
void PutImagedr(byte *);

int InitGraphicswab(void);
void ResetGraphicswab(void);
void Clswab(void);
void ColorsScrFwab(byte );
int InitScrFwab(void);
void PutImagewab(byte *);

int InitGraphicsPW(void);
void ResetGraphicsPW(void);
void ClsPW(void);
void ColorsScrFPW(byte );
int InitScrFPW(void);
void PutImagePW(byte *);
#endif

extern byte dispDrv;                      /* Display driver no. */
extern byte scrHeight;
extern byte RefreshLine;                  /* Start Line to put image */


/******** sound ********/
int InitSound();
void ResetSound();

extern byte UseSB16;                   /* 1 if use Sound Blaster 16 */
extern byte PSGVolOffset;              /* PSG volume against OPN    */
extern int OPNWait;
extern int GDCParam;

#define OPN_NO_MAX 18
#define OPN_DATA_MAX 13
#define OPL3_DATA_MAX 9

extern byte OPNVoice[OPN_NO_MAX][OPN_DATA_MAX];
extern byte OPL3Voice[][OPL3_DATA_MAX];

extern word wConvMemSelector;