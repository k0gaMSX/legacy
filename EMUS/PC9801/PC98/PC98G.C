/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                       pc98g.c                           **/
/**                                                         **/
/** This file contains PC-9800 display driver selecters.    **/
/** drivers.                                                **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1994,1995          **/
/** fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            **/
/**     (21/dr/wab drivers are by HOSOZAWA Rei)             **/
/**      You are not allowed to distribute this software    **/
/**      commercially. Please, notify me, if you make any   **/
/**      changes to this file.                              **/
/*************************************************************/

#include <stdio.h>
#include <dos.h>
#include "MSX.h"
#include "pc98.h"


byte dispDrv=0;                       /* Display driver no. */

/** Screen Mode Handlers [number of screens + 1] *************/
screen SCR[MAXSCREEN+2] =               /* Number of screens + 1  */
{
  { InitScrF,ColorsScrF,RefreshTx40,0x7F,0x00,0x3F,0x00 }, /* TEXT 40x24  */
  { InitScrF,ColorsScrF,RefreshScr1,0x7F,0xFF,0x3F,0xFF }, /* TEXT 32x24  */
  { InitScrF,ColorsScrF,RefreshScr2,0x7F,0x80,0x3C,0xFF }, /* BLK 256x192 */
  { InitScrF,ColorsScrF,RefreshScr3,0x7F,0xFF,0x00,0xFF }, /* 64x48x16    */
  { InitScrF,ColorsScrF,RefreshScr2,0x7F,0x80,0x3C,0xF8 }, /* BLK 256x192 */
  { InitScrF,ColorsScrF,RefreshScr5,0x60,0x00,0x00,0xF8 }, /* 256x192x16  */
  { InitScrF,ColorsScrF,RefreshScr6,0x60,0x00,0x00,0xF8 }, /* 512x192x4   */
  { InitScrF,ColorsScrF,RefreshScr7,0x20,0x00,0x00,0xF8 }, /* 512x192x16  */
  { InitScrF,ColorsScrF,RefreshScr8,0x20,0x00,0x00,0xF8 }, /* 256x192x256 */
  { InitScrF,ColorsScrF,RefreshTx80,0x7C,0xF8,0x3F,0x00 }  /* TEXT 80x24  */
};

int InitGraphics(void)
{
   int  status;  

	switch(dispDrv){
		case 1:/*9821*/
                        status = InitGraphics21();break;
#ifdef 0
		case 2:/*GA-DRx*/
			InitGraphicsdr();break;
		case 3:/*WAB-S*/
			InitGraphicswab();break;
		case 4:/*Power Window*/
			InitGraphicsPW();break;
#endif
		default:/*9801 normal*/
                        status = InitGraphicsN();break;
	}
  return status;
}

void ResetGraphics(void)
{
	switch(dispDrv){
		case 1:/*9821*/
			ResetGraphics21();break;
#ifdef 0
		case 2:/*GA-DRx*/
			ResetGraphicsdr();break;
		case 3:/*WAB-S*/
			ResetGraphicswab();break;
		case 4:/*Power Window*/
			ResetGraphicsPW();break;
#endif
		default:/*9801 normal*/
			ResetGraphicsN();break;
	}
  return;
}


int InitScrF(void)
{
	switch(dispDrv){
		case 1:/*9821*/
			InitScrF21();break;
#ifdef 0
		case 2:/*GA-DRx*/
			InitScrFdr();break;
		case 3:/*WAB-S*/
			InitScrFwab();break;
		case 4:/*Power Window*/
			InitScrFPW();break;
#endif
		default:/*9801 normal*/
			InitScrFN();break;
	}
  return -1;
}


void ColorsScrF(byte c)
{
	switch(dispDrv){
		case 1:/*9821*/
			ColorsScrF21(c);break;
#ifdef 0
		case 2:/*GA-DRx*/
			ColorsScrFdr(c);break;
		case 3:/*WAB-S*/
			ColorsScrFwab(c);break;
		case 4:/*Power Window*/
			ColorsScrFPW(c);break;
#endif
		default:/*9801 normal*/
			ColorsScrFN(c);break;
	}
  return;
}


void PutImage(byte *p)
{
	switch(dispDrv){
		case 1:/*9821*/
		    PutImage21(p);break;
#ifdef 0
		case 2:/*GA-DRx*/
		    PutImagedr(p);break;
		case 3:/*WAB-S*/
		    PutImagewab(p);break;
		case 4:/*Power Window*/
		    PutImagePW(p);break;
#endif
		default:/*9801 normal*/
		    PutImageN(p);break;
	}
  return;
}
