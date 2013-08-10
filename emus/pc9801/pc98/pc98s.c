/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                      pc98s.c                            **/
/**                                                         **/
/** This file contains PC-9800 dependent sound drivers.     **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1994,1995          **/
/** fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            **/
/**      You are not allowed to distribute this software    **/
/**      commercially. Please, notify me, if you make any   **/
/**      changes to this file.                              **/
/*************************************************************/

#include <stdio.h>
#include <dos.h>

#include "msx.h"
#include "pc98.h"


int InitSound(void);
void ResetSound(void);

byte UseSB16=0;                   /* >=1 if use Sound Blaster 16 */

/* OPN support */

extern int OPNInit();                    /*** Initialize OPN(A)        ***/
extern void OPNReset();                  /*** Initialize OPN(A)        ***/
extern void OPNOut(dword R,byte V);      /*** Write value into an OPN  ***/
extern void PSGOutOPN(byte R,byte V);    /*** OPN(A) driver for PSG    ***/
extern byte PSGInOPN(void);              /*** I/O port driver          ***/
extern void OPLLOutOPN(byte R,byte V);   /*** OPN(A) driver for OPLL   ***/
extern void SCCOutOPN(byte R,byte V);    /*** OPN(A) driver for SCC    ***/

/* OPL3 support */

extern int OPL3Init();                   /*** Initialize OPL3          ***/
extern void OPL3Reset();                 /*** Initialize OPL3          ***/
extern void OPL3Out(dword R,byte V);     /*** Write value into an OPL3 ***/
extern void PSGOutOPL3(byte R,byte V);   /*** OPL3 driver for PSG      ***/
extern byte PSGInOPL3(void);             /*** GAME port driver         ***/
extern void OPLLOutOPL3(byte R,byte V);  /*** OPL3 driver for OPLL     ***/
extern void SCCOutOPL3(byte R,byte V);   /*** OPL3 driver for SCC      ***/

/****************************************************************/
/*** Write number into given PSG register.                    ***/
/****************************************************************/
void PSGOut(byte R,byte V)
{
  switch(UseSB16) {
    case 0:
    case 1: PSGOutOPN(R,V);
            break;
    case 2: if(R==0x0f) PSGOutOPN(R,V);
            else PSGOutOPL3(R,V);
            break;
    case 3: PSGOutOPL3(R,V);
  }
  PSG[R]=V;
}


byte PSGIn(byte R)
{
  if(R==0x0e) {
    return (UseSB16>2)?  PSGInOPL3():PSGInOPN();
  } else return PSG[R];
}


/****************************************************************/
/*** Write number into given OPLL register.                   ***/
/****************************************************************/
void OPLLOut(byte R,byte V)
{
  if(UseSB16) OPLLOutOPL3(R,V);
  else OPLLOutOPN(R,V);
  OPLL[R]=V;
}


/****************************************************************/
/*** Write number into given SCC register.                    ***/
/****************************************************************/
void SCCOut(byte R,byte V)
{
  if(R>15) return;
  if(UseSB16) SCCOutOPL3(R,V);
  else SCCOutOPN(R,V);
  SCC[R]=V;
}



int InitSound(void)
{
  int statusOPN, statusOPL3;

  if(UseSB16<3) statusOPN = OPNInit();
  if(UseSB16) statusOPL3 = OPL3Init();

  return statusOPN && statusOPL3;
}

void ResetSound(void)
{
  if(UseSB16<3) {
    OPNReset();
  }

  if(UseSB16) {
    OPL3Reset();
  }
}
