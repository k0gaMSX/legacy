/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                         pcatg.c                         **/
/**                                                         **/
/** This file contains SVGA 640x480x256 graphics driver.    **/
/**                                                         **/
/** fMSX      Copyright (C) Marat Fayzullin 1994,1995       **/
/** fMSX98-AT Copyright (C) MURAKAMI Reki 1996              **/
/**      You are not allowed to distribute this software    **/
/**      commercially. Please, notify me, if you make any   **/
/**      changes to this file.                              **/
/*************************************************************/

#include <stdio.h>
#include <dos.h>
#include <go32.h>
#include <dpmi.h>
#include <dos.h>
#include <sys/farptr.h>

#include "MSX.h"
#include "pcat.h"

byte videoMode;
byte *SVGABuf;

byte RefreshLine = 64;
byte RefreshMode = 0;

/** Screen Mode Handlers [number of screens + 1] *************/
screen SCR[MAXSCREEN+2] =               /* Number of screens + 1  */
{
  { InitScrF,ColorsScrF,RefreshTx40,0x7F,0x00,0x3F,0x00 }, /* TEXT 40x24  */
  { InitScrF,ColorsScrF,RefreshScr1,0x7F,0xFF,0x3F,0xFF }, /* TEXT 32x24  */
  { InitScrF,ColorsScrF,RefreshScr2,0x7F,0x80,0x3C,0xFF }, /* BLK 256x192 */
  { InitScrF,ColorsScrF,RefreshScr3,0x7F,0xFF,0x00,0xFF }, /* 64x48x16    */
  { InitScrF,ColorsScrF,RefreshScr2,0x7F,0x80,0x3C,0xF8 }, /* BLK 256x192 */
  { InitScrF,ColorsScrF,RefreshScr5,0x60,0x00,0x00,0xF8 }, /* 256x212x16  */
  { InitScrF,ColorsScrF,RefreshScr6,0x60,0x00,0x00,0xF8 }, /* 512x212x4   */
  { InitScrF,ColorsScrF,RefreshScr7,0x20,0x00,0x00,0xF8 }, /* 512x212x16  */
  { InitScrF,ColorsScrF,RefreshScr8,0x20,0x00,0x00,0xF8 }, /* 256x212x256 */
  { InitScrF,ColorsScrF,RefreshTx80,0x7C,0xF8,0x3F,0x00 }  /* TEXT 80x24  */
};


char  SVGAsupport;

int InitGraphics(void)
{
  int i;
  _go32_dpmi_registers r;
  _go32_dpmi_seginfo sel;

  videoMode = _farpeekb(wConvMem, 0x00449);
  SVGABuf = (byte *)malloc(640 * 480);

  /* SVGA mode 101h available? */
  sel.size = (256 + 15) >> 4;
  if(_go32_dpmi_allocate_dos_memory(&sel) != 0) {
    return FALSE;
  }

  r.x.es = sel.rm_segment;
  r.x.di = 0;
  r.x.cx = 0x101;
  r.x.ax = 0x4f01;
  r.x.ss = r.x.sp = 0;
  _go32_dpmi_simulate_int(0x10, &r);   /* SVGA call */

  SVGAsupport = (r.h.ah != 0 ||
      _farpeekb(wConvMem, sel.rm_segment << 4) & 0x01 != 0);

  if(_go32_dpmi_free_dos_memory(&sel) != 0) {
    return FALSE;
  }

  if (!SVGAsupport) {
    printf("SVGA not supported.");
    if(RefreshMode == 1) {
      return FALSE;
    } else {
      return TRUE;
    }
  }

  if (Verbose) printf("SVGA mode 101h supported. ");
  return TRUE;
}



int InitGraphicsVGA(void)
{
  union REGS r;

  if(!Verbose) {
    r.x.ax = 0x0013;
    int86(0x10, &r, &r);
    InitPalette();
  }
  return TRUE;
}



int InitGraphicsSVGA(void)
{
  union REGS r;

  if (!SVGAsupport) {
    RefreshMode = 0;
    return TRUE;
  }

  if(!Verbose) {
    r.x.ax = 0x0013;
    int86(0x10, &r, &r);
    r.x.ax = 0x4f02;
    r.x.bx = 0x0101;
    int86(0x10, &r, &r);
    InitPalette();
  }
  return TRUE;
}



void ResetGraphics(void)
{
  union REGS r;
  int i;

  if(_farpeekb(wConvMem, 0x00449) != videoMode) {
    r.h.al = videoMode;
    r.h.ah = 0x00;
    int86(0x10, &r, &r);
  }
}


void ColorsScrF(byte c)
{
  union REGS r;

  if(c!=255&&ScrMode!=8) {
    outportb(0x3c8,c);
    outportb(0x3c9,Palette[c][0]>>2);
    outportb(0x3c9,Palette[c][1]>>2);
    outportb(0x3c9,Palette[c][2]>>2);
  }
}


void InitPalette(void)
{
  int i,j;

  outportb(0x3c8,0);
  if(ScrMode!=8)
    for(i=0;i<16;i++) {
      ColorsScrF(i);
    }
  else {
    for(i=0;i<256;i++) {
      outportb(0x3c9,(i&0x1c)<<1);
      outportb(0x3c9,(i&0xe0)>>2);
      outportb(0x3c9,(i&0x03)<<4);
    }
  }
}


int InitScrF(void)
{
  static char oldScrMode=0;

  if(oldScrMode!=ScrMode) InitPalette();
  oldScrMode=ScrMode;
}


void PutImage(byte *buf)
{
  static int oldGrMode=-1;

  if(RefreshMode==1) {
    if(oldGrMode!=1) {
      if (!InitGraphicsSVGA()) {
        TrashMachine();
      }
      oldGrMode=1;
    }
    PutImageSVGA(buf);
  } else {
    if(oldGrMode!=0) {
      InitGraphicsVGA();
      oldGrMode=0;
    }
    PutImageVGA(buf);
  }
}





void PutImageVGA(byte *buf)
{
  switch(ScrMode) {
    case 6:
    case 7:
    case MAXSCREEN+1:
      buf=(byte *)(buf+(RefreshLine>>2)*640);
      asm("
        pushw %%es;
        movw %1,%%es;
        movl %0,%%esi;
        movl $0xa0000,%%edi;
        movl $16000,%%ecx;
        movl $0x0f0f0f0f,%%edx;
      0:movb 4(%%esi),%%al;
        movb 7(%%esi),%%ah;
        rorl $16,%%eax;
        movb 0(%%esi),%%al;
        movb 3(%%esi),%%ah;
        andl %%edx,%%eax;
        addl $8,%%esi
        stosl;
        decl %%ecx;
        jnz 0b;
        popw %%es;
      " :: "r"(buf),"r"(_go32_conventional_mem_selector())
         : "%eax","%ecx","%edx","%esi","%edi"
      );
      break;

    case 8:
      buf=(byte *)(buf+(RefreshLine>>2)*320);
      movedata(_go32_my_ds(), (int)buf, wConvMem, 0xa0000, 320 * 200);
      break;
    default:
      buf=(byte *)(buf+(RefreshLine>>2)*320);
      asm("
        pushw %%es;
        movw %1,%%es;
        movl %0,%%esi;
        movl $0xa0000,%%edi;
        movl $16000,%%ecx;
        movl $0x0f0f0f0f,%%edx;
      0:lodsl;
        andl %%edx,%%eax;
        stosl;
        decl %%ecx;
        jnz 0b;
        popw %%es;
      " :: "r"(buf),"r"(wConvMem)
         : "%eax","%ecx","%edx","%esi","%edi"
      );
      break;
  }
}
