/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                       pc98gn.c                          **/
/**                                                         **/
/** This file contains PC-9800 normal mode graphics         **/
/** drivers.                                                **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1994,1995          **/
/** fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            **/
/**      You are not allowed to distribute this software    **/
/**      commercially. Please, notify me, if you make any   **/
/**      changes to this file.                              **/
/*************************************************************/

#include <stdio.h>
#include <dos.h>
#include "MSX.h"
#include "pc98.h"

dword pattern[256], pattern2[256];
byte scrHeight    = 220;
byte RefreshLine  = 64;
/* byte *oldImage; */

int InitGraphicsN(void)
{
  union REGS r;
  byte buf,dt0,dt1,dt2,dt3;
  int i,I,dt;

  /*** 640x(400+alpha)x16 Graphic ***/

  outportb(0x62,0x0c);                    /* text off */
  outportb(0xa2,0x0d);                    /* graphic off */

  r.x.ax=0x1810; r.x.bx=0x5454;         /* TT.com check */
  int86(0x18,&r,&r);
  if(r.x.ax&0x1010==0x1010) {
    if(Verbose) printf("found TT.com. ");
    r.x.ax=0x1804; r.x.bx=0x5454;
    int86(0x18,&r,&r);
  }

  r.x.ax=0x0b00; r.x.bx=0xc0a3 ;        /* 30bios.com check */
  int86(0x18,&r,&r);
  if(r.h.al&0x40) {
    if(Verbose) printf("found 30bios.com. ");
    r.x.ax=0x0a00; r.x.bx=0xc0a3;
    int86(0x18,&r,&r);
  }

                                          /* normal GDC setup */
    _farsetsel(wConvMemSelector);
    _farnspokeb(0x054d, _farnspeekb(0x054d) & 0xdb); /* system area GDC clk */
    outportb(0x6a,0x84);                  /* GDC clock=2.5MHz */
    while(!(inportb(0x60)&4));            /* text GDC FIFO wait */
    outportb(0x62,0x0e);                  /* sync command */
    outportb(0x60,0x00);                  /* mode set */
    outportb(0x60,0x4e);                  /* 78 chrs per a line */
    outportb(0x60,0x07);
    outportb(0x60,0x25);                  /* HS :03h VS :08h HFP:04h */
    outportb(0x60,0x07);                  /* HBP:03h */
    outportb(0x60,0x07);                  /* VFP:07h */
    outportb(0x60,scrHeight << 1);        /* screen height */
    outportb(0x60,0x64 | (scrHeight>>7)); /* VBP:19h */
    outportb(0x62,0x47);
    outportb(0x60,0x50);                  /* VRAM width: 80 */
    outportb(0x62,0x70);                  /* scroll command */
    outportb(0x60,0x00);
    outportb(0x60,0x00);                  /* SAD:0000h */
    outportb(0x60,(scrHeight&0x7) << 5);
    outportb(0x60,scrHeight >> 3);        /* SL: scrHeight  */
    while(!(inportb(0xa0)&4));            /* graphic GDC FIFO wait */
    outportb(0xa2,0x0e);                  /* sync command */
    outportb(0xa0,0x04);                  /* mode set */
    outportb(0xa0,0x26);                  /* 38 chrs per a line */
    outportb(0xa0,0x03);
    outportb(0xa0,0x11);                  /* HS :03h VS :08h HFP:04h */
    outportb(0xa0,0x03);                  /* HBP:03h */
    outportb(0xa0,0x07);                  /* VFP:07h */
    outportb(0xa0,scrHeight << 1);        /* screen height */
    outportb(0x60,0x64 | (scrHeight>>7)); /* VBP:19h */
    outportb(0xa2,0x47);
    outportb(0xa0,0x28);                  /* VRAM width: 40 */
    outportb(0xa2,0x70);                  /* scroll command */
    outportb(0xa0,0x00);
    outportb(0xa0,0x00);                  /* SAD:0000h */
    outportb(0xa0,(scrHeight&0x7) << 5);
    outportb(0xa0,scrHeight >> 3);        /* SL:scrHeight , IM:0  */

  outportb(0xa2,0x4b);
  outportb(0xa0,0x01);                    /* csrform: 2 per a line */
  outportb(0x68,0x09);                    /* 400 line mode */
  outportb(0x6a,0x01);                    /* 16 colors */
  outportb(0x6a,0x04);                    /* GRCG compatible mode */
  outportb(0xa4,0);                       /* set page 0 */
  outportb(0xa6,1);                       /* set page 0 */

  outportb(0xa2,0x0d);                    /* graphic on */
  outportb(0x62,(Verbose||Trace)? 0x0d:0x0c);    /* text on */

  for(I=0;I<256;I++) {                          /* make pattern table */
    dt0= I    &1|(I>>3)&2;
    dt1=(I>>1)&1|(I>>4)&2;
    dt2=(I>>2)&1|(I>>5)&2;
    dt3=(I>>3)&1|(I>>6)&2;
    dt=dt0|(dt1<<8)|(dt2<<16)|(dt3<<24);
    pattern[I]=dt|(dt<<2)|(dt<<4)|(dt<<6);
    dt0= I    &1|(I>>2)&4;
    dt1=(I>>1)&1|(I>>3)&4;
    dt2=(I>>2)&1|(I>>4)&4;
    dt3=(I>>3)&1|(I>>5)&4;
    dt=dt0|(dt1<<8)|(dt2<<16)|(dt3<<24); dt|=(dt<<1);
    pattern2[I]=dt|(dt<<4);
  }

  /*** Palette ***/
  for(I=0;I<16;I++) ColorsScrFN(I);

  /* oldImage = (byte *)malloc(640 * 240); */

  if (Verbose) printf("normal mode. ");
  return -1;
}

void ResetGraphicsN(void)
{
  union REGS r;

  r.x.ax=0x1810; r.x.bx=0x5454;         /* TT.com check */
  int86(0x18,&r,&r);
  if(r.x.ax&0x1010==0x1010) {
    r.x.ax=0x1805; r.x.bx=0x5454;
    int86(0x18,&r,&r);
    return;
  }

  r.x.ax=0x0b00; r.x.bx=0xc0a3 ;        /* 30bios.com check */
  int86(0x18,&r,&r);
  if(r.h.al&0x40) {
    if(Verbose) printf("found 30bios.com: ");
    r.x.ax=0x0a10; r.x.bx=0xc0a3;
    int86(0x18,&r,&r);
    return;
  }

  /* Text on */
  r.h.ah = 0x0b;
  int86(0x18, &r, &r);
  r.h.ah = 0x0a;
  r.h.al &= 0x0f;
  int86(0x18, &r, &r);
  r.h.ah = 0x11;
  int86(0x18, &r, &r);
  r.h.ah = 0x0c;
  int86(0x18, &r, &r);
}


int InitScrFN(void)
{
  if(Verbose&0x08) printf("Screen %d initialized.\n",ScrMode);
  return -1;
}


void ColorsScrFN(byte c)
{
  if(c==255) return;
  c&=0x0f;
  outportb(0xa8,c);
  outportb(0xaa,Palette[c][1]>>4);
  outportb(0xac,Palette[c][0]>>4);
  outportb(0xae,Palette[c][2]>>4);
}
