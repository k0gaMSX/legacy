/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                       pc98g21.c                         **/
/**                                                         **/
/** This file contains PC-9821 extend mode graphics         **/
/** drivers.                                                **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1994,1995          **/
/** fMSX98 Copyright (C) MURAKAMI Reki 1995-1997            **/
/**      You are not allowed to distribute this software    **/
/**      commercially. Please, notify me, if you make any   **/
/**      changes to this file.                              **/
/*************************************************************/

#include <stdio.h>
#include <dos.h>
#include "MSX.h"
#include "pc98.h"

int InitGraphics21(void)
{
  union REGS r;

  if ((_farpeekw(wConvMemSelector, 0x45c) & 0x40) == 0) {
    printf("9821 mode not available. ");
    return 0;
  }

  r.h.ah = 0x31;
  int86(0x18,&r,&r);
  r.x.ax = 0x300c;
  r.h.bh = (r.h.bh & 0x03) | 0x30;
  int86(0x18,&r,&r);
  if (r.h.ah != 0x05) {
    if (Verbose) printf("9821 mode set error. ");
    return 0;
  }

  outportb(0xa4, 0);                       /* set display page 0 */
  outportb(0xa6, 0);                       /* set active page 0 */
  _farpokeb(wConvMemSelector, 0xe0100, 0);

  if (Verbose) printf("9821 mode. ");
  return -1;
}


void ResetGraphics21(void)
{
    union REGS r;

    r.h.ah = 0x0c;
    int86(0x18, &r, &r);
}


void InitPalette21(void)
{
        int c;

	if (ScrMode != 8) {
		for (c = 0; c < 16; c++)
			ColorsScrF21(c);
	} else {
                for (c = 0; c < 256; c++) {
			outportb(0xa8, c);
                        outportb(0xaa, (c & 0xe0) );
			outportb(0xac, (c & 0x1c) << 3);
			outportb(0xae, (c & 0x03) << 6);
		}
	}
}


int InitScrF21(void)
{
  static char oldScrMode = 0;

  if (oldScrMode != ScrMode) InitPalette21();
  oldScrMode = ScrMode;
  if (Verbose&0x08) printf("Screen %d initialized\n", ScrMode);
  return -1;
}


void ColorsScrF21(byte c)
{
	byte	i;
  if(c==255) return;
	for(i=0;i<16;i++)
	{
		outportb(0xa8,c+i*16);
		outportb(0xaa,Palette[c][1]);
		outportb(0xac,Palette[c][0]);
		outportb(0xae,Palette[c][2]);
	}
	return;
}

