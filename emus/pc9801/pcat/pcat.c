/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                         pcat.c                          **/
/**                                                         **/
/** This file contains PC-AT clone machine dependent        **/
/** subroutines and drivers.                                **/
/**                                                         **/
/** fMSX      Copyright (C) Marat Fayzullin 1994,1995       **/
/** fMSX98-AT Copyright (C) MURAKAMI Reki 1996              **/
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
#include <sys/farptr.h>


#include "MSX.h"
#include "pcat.h"

char *titleStr = "fMSX98-AT version 1.2k (C) MURAKAMI Reki 1996,1997\n";


/** Key codes conversion **/
const byte Keys[] = {
/*             Esc        1        2        3        4        5        6 */
   0,0x00,  7,0x04,  0,0x02,  0,0x04,  0,0x08,  0,0x10,  0,0x20,  0,0x40,
/*      7        8        9        0        -        ^       BS      Tab */
   0,0x80,  1,0x01,  1,0x02,  0,0x01,  1,0x04,  1,0x08,  7,0x20,  7,0x08,
/*      q        w        e        r        t        y        u        i */
   4,0x40,  5,0x10,  3,0x04,  4,0x80,  5,0x02,  5,0x40,  5,0x04,  3,0x40,
/*      o        p        @        [    Enter   l-Ctrl        a        s */
   4,0x10,  4,0x20,  1,0x20,  1,0x40,  7,0x80,  6,0x02,  2,0x40,  5,0x01,
/*      d        f        g        h        j        k        l        ; */
   3,0x02,  3,0x08,  3,0x10,  3,0x20,  3,0x80,  4,0x01,  4,0x02,  1,0x80,
/*      :  Han.Zen  l-Shift        ]        z        x        c        v */
   2,0x01,  7,0x04,  6,0x01,  2,0x02,  5,0x80,  5,0x20,  3,0x01,  5,0x08,
/*      b        n        m        ,        .        /  r-Shift      [*] */
   2,0x80,  4,0x08,  4,0x04,  2,0x04,  2,0x08,  2,0x10,  6,0x01,  9,0x01,
/*  l-Alt    Space     Caps       f1       f2       f3       f4       f5 */
   6,0x04,  8,0x01,  6,0x08,  6,0x20,  6,0x40,  6,0x80,  7,0x01,  7,0x02,
/*     f6       f7       f8       f9      f10  NumLock  ScrLock      [7] */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00, 10,0x04,
/*    [8]      [9]      [-]      [4]      [5]      [6]      [+]      [1] */
  10,0x08, 10,0x10, 10,0x20,  9,0x80, 10,0x01, 10,0x02,  9,0x02,  9,0x10,
/*    [2]      [3]      [0]      [.]                                 f11 */
   9,0x20,  9,0x40,  9,0x08, 10,0x80,  0,0x00,  0,0x00,  0,0x00,  7,0x40,
/*    f12                                                                */
   7,0x10,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*                                                                       */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*                                                                       */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*   Kana                          _                                     */
   6,0x10,  0,0x00,  0,0x00,  2,0x20,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*          Henkan          Muhenkan                 \                   */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  1,0x10,  0,0x00,  0,0x00,

/*                                                                       */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*                                                                       */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*                                                                       */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*                                      Enter   r-Ctrl                   */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  7,0x80,  6,0x10,  0,0x00,  0,0x00,
/*                                                                       */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*          han/zen                                                      */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*                                                   /                   */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  2,0x10,  0,0x00,  0,0x00,
/*  r-Alt              Caps                                              */
   7,0x40,  0,0x00,  6,0x08,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*                                                                  Home */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  8,0x02,
/*     up     PgUp              left             right               End */
   8,0x20,  0,0x00,  0,0x00,  8,0x10,  0,0x00,  8,0x80,  0,0x00,  0,0x00,
/*   down     PgDn      Ins      Del                                     */
   8,0x40,  0,0x00,  8,0x04,  8,0x08,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*                                                                       */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*                                                                       */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*                                                                       */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*   Kana                                                                */
   6,0x10,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
/*          Henkan           Muhenkan                                    */
   0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,  0,0x00,
};



_go32_dpmi_seginfo DiskBuffer;
word segDiskBuffer;

_go32_dpmi_seginfo segOldIntKey;
_go32_dpmi_seginfo segNewIntKey;
_go32_dpmi_seginfo segRealOldIntKey;
_go32_dpmi_seginfo segRealNewIntKey;
_go32_dpmi_registers regRealNewIntKey;

_go32_dpmi_seginfo eventHandler;
_go32_dpmi_seginfo segOldTimer;
_go32_dpmi_seginfo segNewTimer;
_go32_dpmi_seginfo segRealOldTimer;
_go32_dpmi_seginfo segRealNewTimer;
_go32_dpmi_registers regRealNewTimer;

byte KeyMapAT[16];

union REGS r86;

word wConvMem;

byte keylist[100];
int	keylistidx=0;

volatile byte lock = 0;

volatile int cntTimer;
int cntTimerDefault;

void Timer()
{
	disable();
	cntTimer--;
	if(cntTimer == 0) {
	  cntTimer = cntTimerDefault;
	  IntSyncWait = 0;
	}
	enable();
}

void IntKey(_go32_dpmi_registers *reg)
{
  _go32_dpmi_registers r;
  byte drv = 0;
  byte key, key2;
  static char ext = 0;
  char numlock;

  if(lock == 1) return;
  lock = 1;
  asm("sti"::);
  key = inportb(0x60);

  key2 = key & 0x7f;

  /* numlock = ext || (_farpeekb(wConvMem, 0x417) & 0x20 == 0x00); */

  if (key == 0xe0) ext = 1;
  else if (key == 0xcf && ext) exitFlag = 1;
  else if (key == 0x49 && ext && RefreshLine < 153) RefreshLine += 8;
  else if (key == 0x51 && ext && RefreshLine >   7) RefreshLine -= 8;
  else switch(key) {
    case 0x42: RefreshMode ^= 0x01; break;
    case 0x41: drv = 1;
    case 0x40:
      DiskNo[drv] = (Drives[drv] == -1) ? 0 : DiskNo[drv] + 1;
      Drives[drv] = Disks[DiskNo[drv]];
      break;
    case 0x43: Trace = 4; Verbose = 1; break;
    case 0x44: Verbose = 0; break;

    default:
      if (ext) key2 = key2 + 0x80;
      if (key & 0x80) KeyMapAT[Keys[key2 * 2]] |= Keys[key2 * 2 + 1];
      else KeyMapAT[Keys[key2 * 2]] &= ~Keys[key2 * 2 + 1];
      ext = 0;
      break;
  }

  /* clear key buffer */
  _farpokew(wConvMem, 0x41c, _farpeekw(wConvMem, 0x41a));

  asm("cli"::);
  lock = 0;

#ifdef 0
  outportb(0x20,0x20);
  r.x.cs = segOldIntKey.rm_segment;
  r.x.ip = segOldIntKey.rm_offset;
  r.x.ss = r.x.sp = 0;
  _go32_dpmi_simulate_fcall_iret(&r);
#endif
}


byte exitFlag=0;

void Keyboard(void)
{
  char capsLocked = 0;

/*  int i;
  if(keylistidx!=0) for(i=0;i<keylistidx;i++) printf("%02x ",keylist[i]);
  puts("");keylistidx=0;
*/

  memcpy(KeyMap, KeyMapAT, 16);

#ifdef 0
  if (_farpeekb(wConvMem, 0x497) & 0x04) {		/* Caps key check */
    if (capsLocked < 3) {
      capsLocked++;
      KeyMap[6] &= 0xf7;
    } else {
      KeyMap[6] |= 0x08;
    }
  } else {
    if (capsLocked > 0) {
      capsLocked--;
      KeyMap[6] &= 0xf7;
    } else {
      KeyMap[6] |= 0x08;
    }
  }
#endif

  if(exitFlag) { TrashMachine(); TrashMSX(); exit(0); }
}



#define SEC_PER_TRACK 9

void RealDisk(reg *R)
{
  byte bMediaChanged=0;
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
  Drv=R->AF.B.h&0x01;
  if(!isReadFD) {
    P = segDiskBuffer << 4;
    _farsetsel(wConvMem);
    for(A = R->HL.W, I = Len2 * 512; I; I--)
      _farnspokeb(P++, *(RAM[A >> 13] + (A++ & 0x1fff)));
  }

  do {
    C = Sec / (SEC_PER_TRACK * 2);
    H = (Sec / SEC_PER_TRACK) & 1;
    S = (Sec % SEC_PER_TRACK);
    length = (SEC_PER_TRACK - S < Len)? SEC_PER_TRACK - S : Len;

    r.h.ah=(isReadFD)? 0x02:0x03;
    r.h.al=length;
    r.h.ch=C; r.h.cl=S + 1;
    r.h.dh=H; r.h.dl=Drv;
    r.x.es=segDiskBuffer;
    r.x.bx=offset;
    r.x.ss=r.x.sp=0;

    _go32_dpmi_simulate_int(0x13,&r);

    if(Verbose & 0x10 && r.h.ah) printf("bios result : %02x - ",r.h.ah);
    switch(r.h.ah) {
      case 0x00:
        Value=0x00; break;
      case 0x03:
        Value=0x01; break;              /* WRITE PROTECT */
      case 0xaa:
      case 0x80:
        Value=0x03-isReadFD; break;     /* NOT READY */
      case 0x10:
        Value=0x05-isReadFD; break;     /* DATA CRC ERROR */
      case 0x40:
        Value=0x07-isReadFD; break;     /* SEEK ERROR */
      case 0x04:
        Value=0x09-isReadFD; break;     /* RECORD NOT FOUND */
      case 0x01:
      case 0x07:
        Value=0x0a; break;              /* UNSUPPORTED MEDIA */
      case 0xcc:
        Value=0x0b; break;              /* WRITE FAULT */
      case 0x06:
        bMediaChanged++;                /* Media Changed (3 times retry) */
        if(bMediaChanged>3) {
          Value=0x0a;
          break;
        } else {
          continue;                     /* retry */
        }
      default:
        Value=0x0c;                     /* OTHER ERROR */
      }
    if(Value) break;

    Sec+=length; Len-=length;
    offset+=length*512;
  } while(Len);

  if(isReadFD) {
    P = segDiskBuffer << 4;
    _farsetsel(wConvMem);
    for(A = R->HL.W, I = Len2 * 512; I ; I--)
      *(RAM[A >> 13] + (A++ & 0x1fff)) = _farnspeekb(P++);
  }

  R->AF.B.h=Value;
  R->AF.B.l=(Value)? 0x01:0x00;
  R->BC.B.h=Len;
}



int InitMachine(void)
{
  _go32_dpmi_registers r;

  wConvMem = _go32_conventional_mem_selector();

  /*** Initialize 640x480x256 Graphics */
  if(Verbose) printf("Initializing graphic drivers: ");
  if(!InitGraphics()) { PRINTFAILED; return 0; }
  PRINTOK;

  /*** Initialize sounds ***/
  if(Verbose) printf("Initializing sound drivers: ");
  if(!InitSound()) { PRINTFAILED; return 0; }
  PRINTOK;

  /*** Disk drives ***/
  if(UseDisk) {
    DiskBuffer.size = (512 * SEC_PER_TRACK * 2 + 15) / 16;
    if (Verbose) printf("Initializing disk drives: ");
    if (_go32_dpmi_allocate_dos_memory(&DiskBuffer) != 0) {
      PRINTFAILED; return 0;
    }
    segDiskBuffer = DiskBuffer.rm_segment;
    if (Verbose) printf("Buffer addr is %04x0h", segDiskBuffer);
    if ((segDiskBuffer & 0xfff) + ((512 * SEC_PER_TRACK) >> 4) > 0x1000 ) {
      segDiskBuffer += ((512 * SEC_PER_TRACK) >> 4);
      if (Verbose) printf(" -> %04x0h", segDiskBuffer);
    }
    if (Verbose) printf(". ");
    PRINTOK;
  }

  /*** Keyboard ***/
  if (Verbose) printf("Initializing keyboard drivers: ");
  memset(KeyMapAT, 0xff, 16);
  disable();

  segNewIntKey.pm_selector = _go32_my_cs();
  segNewIntKey.pm_offset = (dword)IntKey;
  _go32_dpmi_get_protected_mode_interrupt_vector(0x09, &segOldIntKey);
  /* _go32_dpmi_allocate_iret_wrapper(&segNewIntKey); */
  _go32_dpmi_chain_protected_mode_interrupt_vector(0x09, &segNewIntKey);

#ifdef 0
  _go32_dpmi_get_real_mode_interrupt_vector(0x09, &segRealOldIntKey);
  segRealNewIntKey.pm_selector = _go32_my_cs();
  segRealNewIntKey.pm_offset = (dword)IntKey;
  _go32_dpmi_allocate_real_mode_callback_iret(&segRealNewIntKey, &regRealNewIntKey);
  _go32_dpmi_set_real_mode_interrupt_vector(0x09, &segRealNewIntKey);
#endif
  enable();

  /*** Initialize real time clock ***/
  if (IntSync == 1) {
    if (Verbose) printf("timer: ");

    cntTimerDefault = 1024 / IFreq;
    cntTimer = cntTimerDefault;

    _go32_dpmi_get_protected_mode_interrupt_vector(0x70, &segOldTimer);
    segNewTimer.pm_selector = _go32_my_cs();
    segNewTimer.pm_offset = (int) Timer;
    _go32_dpmi_chain_protected_mode_interrupt_vector(0x70, &segNewTimer);

    eventHandler.size = 1;
    _go32_dpmi_allocate_dos_memory(&eventHandler);
    r.x.ax = 0x8300;
    r.x.cx = 0xffff;
    r.x.dx = 0xffff;
    r.x.es = eventHandler.rm_segment;
    r.x.bx = 0;                          /* for temporary area */
    _go32_dpmi_simulate_int(0x15, &r); /* start real time clock */
    if (r.x.flags & 0x01) {
      PRINTFAILED;
      return FALSE;
    }
  }

  PRINTOK;

  return TRUE;
}


void TrashMachine()
{
  _go32_dpmi_registers r;

  /*** Enfree disk buffer ***/
  _go32_dpmi_free_dos_memory(&DiskBuffer);

  /*** Stop sounds ***/
  ResetSound();

  /*** Reset keyboard ***/
  disable();

  _go32_dpmi_set_protected_mode_interrupt_vector(0x09, &segOldIntKey);
  _farpokew(wConvMem, 0x41c, _farpeekw(wConvMem, 0x41a));

#ifdef 0
  _go32_dpmi_free_iret_wrapper(&segNewIntKey);
  _go32_dpmi_set_real_mode_interrupt_vector(0x09, &segRealOldIntKey);
  _go32_dpmi_free_real_mode_callback(&segRealNewIntKey);
#endif

  enable();

  /*** Reset timer ***/
  if (IntSync == 1) {
    r.x.ax = 0x8301;
    _go32_dpmi_simulate_int(0x15, &r); /* cancel event */
    _go32_dpmi_set_protected_mode_interrupt_vector(0x70, &segOldTimer);
  }

  /*** Text on ***/
  ResetGraphics();
}
