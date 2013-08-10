/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                           MSX.h                         **/
/**                                                         **/
/** This file contains declarations relevant to the drivers **/
/** and MSX emulation itself. See Z80.h for #defines        **/
/** related to Z80 emulation.                               **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1994,1995          **/
/** fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            **/
/**     You are not allowed to distribute this software     **/
/**     commercially. Please, notify me, if you make any    **/
/**     changes to this file.                               **/
/*************************************************************/

#define PAGESIZE  0x4000L   /* Size of a RAM page            */
#define NORAM     0xFF      /* Byte to be returned from      */
                            /* non-existing pages and ports  */
#define MAXSCREEN 8         /* Highest screen mode supported */

#define WIDTH 320
#define HEIGHT 240          /* Grapshic buffer width/height  */

#define TAPEHEADER "_Header_"
#define ERRORSEC "_ErrSec_"

#define PRINTOK     if(Verbose) printf("OK\n")
#define PRINTFAILED if(Verbose) printf("Failed\n")

#define TRUE 1
#define FALSE 0

/***** Following are macros to be used in screen drivers *****/
#define BigSprites    (VDP[1]&0x01)   /* Zoomed sprites      */
#define Sprites16x16  (VDP[1]&0x02)   /* 16x16/8x8 sprites   */
#define SpritesOFF    (VDP[8]&0x02)   /* Don't show sprites  */
#define ScreenON      (VDP[1]&0x40)   /* Show screen         */
#define SolidColor0   (VDP[8]&0x20)   /* Solid/Tran. COLOR 0 */
#define ScanLines212  (VDP[9]&0x80)   /* 212/192 scanlines   */
/*************************************************************/

#include "Z80.h"            /* Z80 emulation declarations    */

/******** Emulator behavior ********/
extern byte Verbose;                /* Debug msgs ON/OFF      */
extern byte MSXVersion;             /* 0=MSX1,1=MSX2,2=MSX2+  */
extern byte UPeriod;                /* Interrupts/scr. update */
extern byte IFreq;
extern byte IntSync;
volatile extern byte IntSyncWait;   /* 1 if wait real time intr. */
extern char *sysPath;               /* Path to system .ROM files */
extern char *romPath;               /* Path to .ROM files */
extern char *diskPath;              /* Path to disk image files */
extern char *tapePath;              /* Path to tape image files */
extern byte exitFlag;

extern byte UseDisk;                /* 1 if use disk drive(s) */
extern byte UseTape;                /* 1 if use tape devise   */
extern byte UseRS232;               /* 1 if use RS232         */
extern byte UseDOS2;                /* 1 if use MSX-DOS2      */
extern byte UseFM;                  /* 1 if use FM BIOS ROM   */
extern byte UseSCC;                 /* 1 if use SCC           */
extern byte UseKanjiROM;            /* 1 if use Kanji ROM     */

/******** MSX system cotrol ********/
extern byte ResetStatus;            /* MSX2+ Reset Status     */
extern byte EnableSysSelect;        /* TurboR system select   */

extern byte IOReg;                  /* Storage for AAh port   */
extern byte PPIReg;                 /* PPI control            */

extern byte SaveCMOS;               /* Save CMOS.ROM on exit  */
extern byte RTCReg,RTCMode;         /* RTC numbers            */
extern byte RTC[4][13];             /* RTC registers          */
byte RTCIn(byte R);                 /* Read RTC registers     */

/******* Slot and memory *******/
extern byte PSL[4],SSL[4];
extern byte PSLReg,SSLReg[4];   /* Storage for A8h port and (FFFFh)  */

extern byte *MemMap[4][4][8];   /* Memory maps [PPage][SPage][Addr]  */

extern byte RAMPages;               /* Number of RAM pages    */
extern byte VRAMPages;              /* Number of VRAM pages   */

extern byte *RAMMap[256];           /* Blocks for RAM mapper  */
extern byte RAMMapper[4];           /* RAM Mapper state       */
extern byte *ROMMap[4][4][256];     /* Blocks for ROM mappers */
extern byte ROMType[4][4];          /* MEGA ROM type          */
extern byte EnWrite[4];             /* 1 if write enabled     */
extern byte *NoRAMSlot;             /* Dummy slot             */

extern char *CartA;                 /* Cartridge A ROM file   */
extern char *CartB;                 /* Cartridge B ROM file   */

void SSlot(byte Value);
byte *LoadROM(char *FileName,int P,int S,int A);

/******** VDP ********/
extern byte *VRAM,*RAM[8];          /* Main and Video RAMs    */
extern dword VAddrMask;             /* VRAM address mask      */

extern byte *ChrGen,*ChrTab,*ColTab;/* VDP tables [screens]   */
extern byte *SprGen,*SprTab,*SprCol;/* VDP tables [sprites]   */
extern byte Palette[16][3];         /* Palette registers      */
extern dword VAddr;      /* Storage for VRAM addresses in VDP */
extern byte VKey,PKey;              /* Status keys for VDP    */
extern byte FGColor,BGColor;        /* Colors                 */
extern byte XFGColor,XBGColor;      /* Second set of colors   */
extern byte ScrMode;                /* Current screen mode    */
extern byte VDP[64],VDPStatus[16];  /* VDP registers          */
extern byte MMCMode;                /* LMMC,LMCM,HMMC status  */
extern byte _Mask,_Diff,_LogOp,_Shift[4];
extern int _SX,_SY,_DX,_DY,_NX,_NY,_N;
extern int _TX,_TY,_AX,_AY,_BX,_BY,_Line;

extern byte InterLaceMode;
extern byte InterLacePage;

extern byte *ScreenBuf;             /* Screen image buffer    */
extern byte Pal[16];                /* Palette assign         */

void VDPOut(byte Reg,byte Value);   /* Write value into a VDP */
void CheckSprites(void);            /* Check for collisions and 5th sprite */
void DoVDP(byte V);                 /* Perform V9938 operation */
inline byte Oper(byte A,byte B,byte N);    /* VDP bit logival operaton */
void Refresh();                     /* TO BE WRITTEN BY USER  */

typedef struct
{                                   /* Screen mode handlers:  */
  int (*Init)(void);                /* Initialize screen      */
  void (*Colors)(byte C);           /* Update colors/palette  */
  void (*Refresh)(byte Y1,byte Y2); /* Refresh screen image   */
  byte R2,R3,R4,R5;                 /* Masks for table addr.  */
} screen;

extern screen SCR[MAXSCREEN+2];     /* Number of screens + 1  */

int InitTx40(void);void ColorsTx40(byte I);void RefreshTx40(byte Y1,byte Y2);
int InitTx80(void);void ColorsTx80(byte I);void RefreshTx80(byte Y1,byte Y2);
int InitScr1(void);void ColorsScr1(byte I);void RefreshScr1(byte Y1,byte Y2);
int InitScr2(void);void ColorsScr2(byte I);void RefreshScr2(byte Y1,byte Y2);
int InitScr3(void);void ColorsScr3(byte I);void RefreshScr3(byte Y1,byte Y2);
int InitScr4(void);void ColorsScr4(byte I);void RefreshScr4(byte Y1,byte Y2);
int InitScr5(void);void ColorsScr5(byte I);void RefreshScr5(byte Y1,byte Y2);
int InitScr6(void);void ColorsScr6(byte I);void RefreshScr6(byte Y1,byte Y2);
int InitScr7(void);void ColorsScr7(byte I);void RefreshScr7(byte Y1,byte Y2);
int InitScr8(void);void ColorsScr8(byte I);void RefreshScr8(byte Y1,byte Y2);
int InitScrF(void);void ColorsScrF(byte I);void RefreshScrF(byte Y1,byte Y2);


/******* Disk *******/
extern char *DiskA;                 /* Drive A disk image     */
extern char *DiskB;                 /* Drive B disk image     */
extern int  Drives[2];              /* Disk image files       */
extern int  Disks[40];              /* Other disk image files */
extern char DiskNo[0];              /* Disk image file No.    */
void Disk(reg *);                   /* Disk emulation         */
void ChgDisk(byte);                 /* Change disk image files */
void RealDisk(reg *);               /* TO BE WRITTEN BY USER  */

/******** Other devices ********/
extern byte KeyMap[16];             /* Keyboard map           */
void Keyboard(void);                /* TO BE WRITTEN BY USER  */

extern char *TapeFile;              /* Tape image             */
extern FILE *Tape;                  /* Tape image file        */

extern char *PrnName;               /* Printer redirect. file */
extern FILE *PrnStream;
void Printer(byte V);               /* Send a character to a printer */

/******** Sound ********/
extern byte PSGReg;                 /* PSG number             */
extern byte OPLLReg;                /* OPLL number            */
extern byte PSG[16];                /* PSG registers          */
extern byte OPLL[56];               /* OPLL registers         */
extern byte SCC[16];                /* SCC registers          */
void PSGOut(byte R,byte V);         /* TO BE WRITTEN BY USER  */
byte PSGIn(byte R);                 /* TO BE WRITTEN BY USER  */
void OPLLOut(byte R,byte V);        /* TO BE WRITTEN BY USER  */
void SCCOut(byte R,byte V);         /* TO BE WRITTEN BY USER  */

/******* Kanji ********/
extern byte *KanjiFont;             /* Kanji ROM table addr.  */
extern word KanjiCode;              /* Number of Kanji code   */
extern byte KanjiLine;              /* Line number of font    */

/******* other functions ********/
int StartMSX(void);
void TrashMSX(void);

word Interrupt(void);
void BIOSEmulate(reg *R);

/******* other machine independents *******/
extern int InitMachine(void);
extern void TrashMachine(void);

extern int Argc;
extern char **Argv;
extern char **Env;

extern char *titleStr;
