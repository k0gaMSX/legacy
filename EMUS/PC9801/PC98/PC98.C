/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                         pc98.c                          **/
/**                                                         **/
/** This file contains PC-9800 dependent subroutines and    **/
/** drivers.                                                **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1994,1995          **/
/** fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            **/
/**      You are not allowed to distribute this software    **/
/**      commercially. Please, notify me, if you make any   **/
/**      changes to this file.                              **/
/*************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos.h>
#include <dpmi.h>
#include <go32.h>

#include "MSX.h"
#include "pc98.h"

char *titleStr = "fMSX98 version 1.2j (C) MURAKAMI Reki 1995-1997\n";

_go32_dpmi_registers regNewTimer;
_go32_dpmi_seginfo segOldTimer,segNewTimer;    /* Timer interrupt vector */
word NewClock;                                 /* Clock couter value     */

_go32_dpmi_seginfo DiskBuffer;
word segDiskBuffer;

word wConvMemSelector;

byte UseCDrive    = 0;                   /* 1 if use drive C: D:      */

const byte Keys[] = {
/*    ESC        1        2        3        4        5        6        7 */
   7,0x04,  0,0x02,  0,0x04,  0,0x08,  0,0x10,  0,0x20,  0,0x40,  0,0x80,
/*      8        9        0        -        ^        \       BS      TAB */
   1,0x01,  1,0x02,  0,0x01,  1,0x04,  1,0x08,  1,0x10,  7,0x20,  7,0x08,
/*      Q        W        E        R        T        Y        U        I */
   4,0x40,  5,0x10,  3,0x04,  4,0x80,  5,0x02,  5,0x40,  5,0x04,  3,0x40,
/*      O        P        @        [      Ret        A        S        D */
   4,0x10,  4,0x20,  1,0x20,  1,0x40,  7,0x80,  2,0x40,  5,0x01,  3,0x02,
/*      F        G        H        J        K        L        ;        : */
   3,0x08,  3,0x10,  3,0x20,  3,0x80,  4,0x01,  4,0x02,  1,0x80,  2,0x01,
/*      ]        Z        X        C        V        B        N        M */
   2,0x02,  5,0x80,  5,0x20,  3,0x01,  5,0x08,  2,0x80,  4,0x08,  4,0x04,
/*      ,        .        /        _    Space     Xfer     R.up     R.dn */
   2,0x04,  2,0x08,  2,0x10,  2,0x20,  8,0x01,  7,0x40, 15,0x80, 15,0x40,
/*    Ins      Del     (up)   (left)  (right)   (down) Home/clr     Help */
   8,0x04,  8,0x08,  8,0x20,  8,0x10,  8,0x80,  8,0x40,  8,0x02, 14,0x01,
/*      -        /        7        8        9        *        4        5 */
  10,0x20,  9,0x04, 10,0x04, 10,0x08, 10,0x10,  9,0x01,  9,0x80, 10,0x01,
/*      6        +        1        2        3        =        0        , */
  10,0x02,  9,0x02,  9,0x10,  9,0x20,  9,0x40, 15,0x00,  9,0x08, 10,0x40,
/*      .     Nfer      vf1      vf2       vf3     vf4      vf5          */
  10,0x80,  7,0x10, 15,0x10, 15,0x08, 15,0x04, 15,0x02, 15,0x01, 15,0x00,
/*                                                         Home          */
  15,0x00, 15,0x00, 15,0x00, 15,0x00, 15,0x00, 15,0x00, 15,0x00, 15,0x00,
/*   Stop     Copy       f1       f2       f3       f4       f5       f6 */
  15,0x00, 15,0x00,  6,0x20,  6,0x40,  6,0x80,  7,0x01,  7,0x02, 14,0x80,
/*     f7       f8       f9      f10                                     */
  14,0x40, 14,0x20, 14,0x10, 14,0x08, 15,0x00, 15,0x00, 15,0x00, 15,0x00,
/*  Shift     Caps     Kana     Grph     Ctrl                            */
   6,0x01, 15,0x00, 15,0x00,  6,0x04,  6,0x02, 15,0x00, 15,0x00, 15,0x00,
/*                                                                       */
  15,0x00, 15,0x00, 15,0x00, 15,0x00, 15,0x00, 15,0x00, 15,0x00, 15,0x00,
};



void Keyboard(void)
{
  byte keys98[16 + 1];                        /* 98 key matrix */
  static byte oldKeys98[16] = { 0 };          /* 98 key matrix saved */
  static byte capsLocked = 0, kanaLocked = 0;
  static char autoRepeat = 0;
  byte drv, i, j, key;

  dosmemget(0x52a,17,keys98);           /* get pc98 key matrix */

  KeyMap[6] |= 0x18;                 /* kana caps reset */
  KeyMap[14] = KeyMap[15] = 0xff;    /* special function reset */

  if ((keys98[16] & 0x02) == 0x02) {	/* Caps key check */
    if (capsLocked < 3) {
      capsLocked++;
      KeyMap[6] &= 0xf7;
    }
  } else {
    if (capsLocked > 0) {
      capsLocked--;
      KeyMap[6] &= 0xf7;
    }
  }

  if ((keys98[16] & 0x04) == 0x04) {	/* Kana key check */
    if (kanaLocked < 3) {
      kanaLocked++;
      KeyMap[6] &= 0xef;
    }
  } else {
    if (kanaLocked > 0) {
      kanaLocked--;
      KeyMap[6] &= 0xef;
    }
  }

  for (j = 0; j < 15; j++) {           /* convert pc98 to msx */
    key = keys98[j] | oldKeys98[j];
    oldKeys98[j] = keys98[j];
    for (i = 0; i < 8; i++, key >>= 1) {
      if (key & 0x01)
       KeyMap[Keys[j * 16 + i * 2]] &= ~Keys[j * 16 + i * 2 + 1];
      else
        KeyMap[Keys[j * 16 + i * 2]] |= Keys[j * 16 + i * 2 + 1];
    }
  }

  /* special functions */

  if(~KeyMap[14] & 0x01) { TrashMachine(); TrashMSX(); exit(0); } /* exit */
  if(~KeyMap[15] & 0x80 && RefreshLine<160-4) { RefreshLine+=4; } /* scrl */
  if(~KeyMap[15] & 0x40 && RefreshLine>    3) { RefreshLine-=4; }

  if (~KeyMap[14] & 0xc0) {
    if(!autoRepeat) ChgDisk((~KeyMap[14] & 0x80) ? 0 : 1); autoRepeat = TRUE;
  } else if (~KeyMap[15] & 0x3f) {
    if(!autoRepeat) Verbose ^= ~KeyMap[15] & 0x3f; autoRepeat = TRUE;
  } else if (~KeyMap[14] & 0x10) {
    if(!autoRepeat) { Trace = 3; Verbose = 1; } autoRepeat = TRUE;
  } else if (~KeyMap[14] & 0x08) {
    if(!autoRepeat) Verbose = 0; autoRepeat = TRUE;
  }  else autoRepeat = FALSE;                 /* the next isn't auto-repeat */

  /* text on/off controll */
  outportb (0x62, (Verbose || Trace) ? 0x0d : 0x0c);
}


#define SEC_PER_TRACK 9

void RealDisk(reg *R)
{
  int I,J;
  word A,Sec,offset=0,offset2,Value=0;
  byte Drv,isReadFD,Len,Len2;
  byte C,H,S,length,PS,SS;
  byte *B;
  dword P;
  _go32_dpmi_registers r;

  isReadFD=(R->AF.B.l&C_FLAG)? 0:1;
  Len2=Len=R->BC.B.h;
  Sec=R->DE.W;
  Drv=R->AF.B.h&0x01; if(UseCDrive) Drv|=0x02;

  if(!isReadFD) {
    P = segDiskBuffer << 4;
    _farsetsel(wConvMemSelector);
    for(A=R->HL.W,I=Len2*512;I;I--)
      _farnspokeb(P++, *(RAM[A >> 13] + (A++ & 0x1fff)));
  }

  do {
    C = Sec / (SEC_PER_TRACK * 2);
    H = (Sec / SEC_PER_TRACK) & 1;
    S = (Sec % SEC_PER_TRACK);
    length = (SEC_PER_TRACK - S < Len)? SEC_PER_TRACK - S : Len;

    r.h.ah=(isReadFD)? 0x76:0x75;
    r.h.al=0x10|Drv;

    r.x.bx=length*512;
    r.h.dh=H; r.h.dl=S+1;
    r.h.ch=2; r.h.cl=C;
    r.x.es=segDiskBuffer;
    r.x.bp=offset;
    r.x.ss=r.x.sp=0;

    _go32_dpmi_simulate_int(0x1b,&r);

    if(Verbose & 0x10 && r.h.ah) printf("bios result : %02x - ",r.h.ah);
    switch(r.h.ah) {
      case 0x00:
        Value=0x00; break;
      case 0x70:
        Value=0x01; break;              /* WRITE PROTECT */
      case 0x40:
        Value=0x07-isReadFD; break;     /* SEEK ERROR */
      case 0x90:
      case 0x60:
        Value=0x03-isReadFD; break;     /* NOT READY */
      case 0xb0:
      case 0xa0:
        Value=0x05-isReadFD; break;     /* DATA CRC ERROR */
      case 0xe0:
      case 0xd0:
      case 0xc0:
        Value=0x09-isReadFD; break;     /* RECORD NOT FOUND */
      default:
        Value=0x0c;                     /* OTHER ERROR */
    }
    if(Value) break;

    Sec+=length; Len-=length;
    offset+=length*512;
  } while(Len);

  if(isReadFD) {
    P = segDiskBuffer << 4;
    _farsetsel(wConvMemSelector);
    for(A=R->HL.W,I=Len2*512;I;I--)
      *(RAM[A>>13]+(A++&0x1fff)) = _farnspeekb(P++);
  }

  R->AF.B.h=Value;
  R->AF.B.l=(Value)? 0x01:0x00;
  R->BC.B.h=Len;
}


void TimerHandler(_go32_dpmi_registers *r)
{
  asm("cli"::);
  Cnt=200;
  outportb(0x00,0x20);
  asm("sti"::);
}



int InitMachine(void)
{
  union REGS r;
  int i;

  wConvMemSelector = _go32_conventional_mem_selector();

  /*** Initialize 640x400x16 Graphics ***/
  if(Verbose) printf("Initializing graphic drivers: ");
  if(!InitGraphics()) { PRINTFAILED; return 0; }
  PRINTOK;

  /*** Initialize sounds ***/
  if(Verbose) printf("Initializing sound drivers: ");
  if(!InitSound()) { PRINTFAILED; return 0; }
  PRINTOK;

  /*** Keyboard ***/
  if(Verbose) printf("Initializing keyboard drivers: ");
  _farsetsel(wConvMemSelector);
  _farnspokeb(0x500, _farnspeekb(0x500) | 0x20);
  r.x.ax=0x3301;
  r.h.dl=0x00;
  int86(0x21,&r,&r);
  PRINTOK;

  /*** Timer interrupt ***/
  if(!IntSync) {
    if(Verbose) printf("Initializing timer for %dHz: ",IFreq);
    asm("cli"::);
    outportb(0x02,inportb(0x02)|0x01);
    segNewTimer.pm_offset = (dword)TimerHandler;
    segNewTimer.pm_selector = _go32_my_cs();
    _go32_dpmi_get_real_mode_interrupt_vector(0x08,&segOldTimer);
    _go32_dpmi_allocate_real_mode_callback_iret(&segNewTimer,&regNewTimer);
    _go32_dpmi_set_real_mode_interrupt_vector(0x08,&segNewTimer);

    NewClock = (_farpeekb(wConvMemSelector, 0x00501) & 0x80)?
                1996800 / 2 / IFreq : 2457600 / 2 / IFreq;
    outportb(0x77,0x36);
    outportb(0x5f,0);
    outportb(0x71,NewClock&0xff);
    outportb(0x5f,0);
    outportb(0x71,NewClock>>8);
    outportb(0x02,inportb(0x02)&0xfe);
    asm("sti"::);
    PRINTOK;
  }

  /*** Disk drives ***/
  if(UseDisk) {
    DiskBuffer.size = 512 * SEC_PER_TRACK * 2 / 16;
    if(Verbose) printf("Initializing disk drives: ");
    if(_go32_dpmi_allocate_dos_memory(&DiskBuffer) != 0) {
      PRINTFAILED; return 0;
    }
    segDiskBuffer = DiskBuffer.rm_segment;
    if (Verbose) printf("segment = %04x0 ", segDiskBuffer);
    if ((segDiskBuffer & 0xfff) + ((512 * SEC_PER_TRACK) >> 4) > 0x1000 ) {
      segDiskBuffer += ((512 * SEC_PER_TRACK) >> 4);
      if (Verbose) printf("-> %04x0 ", segDiskBuffer);
    }
    PRINTOK;
  }

  return -1;
}


void TrashMachine()
{
  union REGS r;

  /*** Enfree disk buffer ***/
  _go32_dpmi_free_dos_memory(&DiskBuffer);

  /*** Reset sounds ***/
  ResetSound();

  /*** Release timer interrupt ***/
  if(!IntSync) {
    asm("cli"::);
    outportb(0x02,inportb(0x02)|0x01);
    _go32_dpmi_set_real_mode_interrupt_vector(0x08,&segOldTimer);
    _go32_dpmi_free_real_mode_callback(&segNewTimer);
    asm("sti"::);
  }

  /*** Reset keyboard ***/
  _farsetsel(wConvMemSelector);
  _farnspokeb(0x500, _farnspeekb(0x500) & 0xdf);
  r.h.ah=0x03;
  int86(0x18,&r,&r);

  /*** Reset graphics ***/
  ResetGraphics();
}
