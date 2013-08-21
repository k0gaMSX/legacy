/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                      pc98s86.c                          **/
/**                                                         **/
/** This file contains PC-9800 dependent sound drivers.     **/
/** for PC-9801-26K/PC-9801-86 sound card.                  **/
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


/* OPN support */

int OPNInit();                    /*** Initialize OPN(A)        ***/
void OPNReset();
void OPNOut(dword R,byte V);      /*** Write value into an OPN  ***/
void PSGOutOPN(byte R,byte V);    /*** OPN(A) driver for PSG    ***/
byte PSGInOPN(void);              /*** I/O port driver          ***/
void OPLLOutOPN(byte R,byte V);   /*** OPN(A) driver for OPLL   ***/
void SCCOutOPN(byte R,byte V);    /*** OPN(A) driver for SCC    ***/

dword OPNReg   = 0x188;           /* OPN  I/O port             */
dword OPNAReg  = 0x18c;           /* OPNA I/O port             */
byte PSGVolOffset = 0;            /* PSG volume against OPN    */
int OPNWait = 20;

byte OPNVoice[][13] = {
  { 0x00,0x00,0x7F,0x7f,0x01,0x01,0x01,0x01,0x01,0x01,0xFF,0xFF,0x04 }, /*@63*/
  { 0x01,0x01,0x25,0x7f,0x17,0x0B,0x09,0x0D,0x00,0x00,0x14,0x17,0x3C }, /*@02*/
  { 0x02,0x01,0x2B,0x7f,0x15,0x15,0x07,0x07,0x07,0x07,0x75,0x05,0x2C }, /*@10*/
  { 0x01,0x01,0x1D,0x7f,0x9B,0x97,0x13,0x05,0x00,0x05,0x11,0xF4,0x2C }, /*@00*/
  { 0x01,0x01,0x41,0x7f,0x0D,0x89,0x19,0x07,0x00,0x00,0x18,0x26,0x3C }, /*@03*/
  { 0x02,0x00,0x41,0x7f,0x11,0x8B,0x91,0x09,0x00,0x00,0x14,0x06,0x3C }, /*@04*/
  { 0x01,0x04,0x41,0x7f,0x8F,0x8B,0x05,0x0D,0x00,0x00,0x0A,0x1C,0x2C }, /*@05*/
  { 0x01,0x01,0x2D,0x7f,0x8B,0x8B,0x03,0x05,0x00,0x00,0x26,0x24,0x3C }, /*@06*/
  { 0x01,0x03,0x15,0x7f,0x1F,0x1F,0x99,0x11,0x00,0x00,0x28,0x29,0x34 }, /*@09*/
  { 0x01,0x01,0x1B,0x7f,0x0F,0x9F,0x0B,0x05,0x00,0x00,0x18,0x03,0x2C }, /*@48*/
  { 0x02,0x04,0x17,0x7f,0x13,0x17,0x09,0x01,0x09,0x01,0x33,0xF6,0x34 }, /*@24*/
  { 0x01,0x00,0x0D,0x7f,0x15,0x1D,0x07,0x05,0x07,0x05,0xF4,0xF4,0x34 }, /*@14*/
  { 0x09,0x01,0x49,0x7f,0x93,0x9B,0x8B,0x83,0x00,0x00,0xE5,0xF2,0x34 }, /*@16*/
  { 0x00,0x01,0x13,0x7f,0x19,0x9F,0x0F,0x13,0x0F,0x00,0x14,0x04,0x34 }, /*@23*/
  { 0x01,0x01,0x23,0x7f,0x99,0x97,0x01,0x05,0x01,0x05,0x01,0xF4,0x04 }, /*@33*/
  { 0x03,0x03,0x1F,0x7f,0x1B,0x17,0x1B,0x1F,0x00,0x1F,0x4A,0x05,0x3C }, /*@12*/
/* This is the original SCC Voice */
/*{ 0x02,0x02,0x15,0x7f,0x9f,0x9f,0x00,0x00,0x00,0x00,0x0f,0x0f,0x2C }    SCC*/
/* This is by Hosozawa and his friend. Thanks! */
  { 0x72,0x32,0x15,0x7f,0x1f,0x1f,0x00,0x00,0x00,0x00,0x0f,0x0f,0x2C }, /*SCC*/
  { 0x32,0x72,0x11,0x7f,0x1f,0x1f,0x00,0x00,0x00,0x00,0x0f,0x0f,0x2C }  /*SCC*/
};


void OPNOut(dword r,byte v)
{
  dword reg;
  int i;

  reg = (r > 0xff)? OPNAReg : OPNReg;

  if(!reg) return;

  WAIT(3);
  /* while(inportb(reg) & 0x80); */
  outportb(reg, r & 0xff);

  WAIT(OPNWait);
  /* while(inportb(reg) & 0x80); */
  outportb(reg + 2, v);
}


int OPNInit()
{
  dword reg;
  byte ch, i, j;

  OPNReg = OPNAReg = 0;

  /* ?Enable OPNA mode of 118 sound board (non PnP mode)*/
  /* outportw(0xa461,0xff71); */

  /* Enable using OPNA for PC-9821 */
  ch=inportb(0xa460);
  switch(ch>>4) {
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
      outportb(0xa460,(ch&0xfc)|1); break;
  }

  /* Detect OPN/OPNA */
  for(i = 0, ch = 0; (ch <= 2) && (i == 0); ch++) {
    reg = (ch == 0)? 0x188 : (ch == 1) ? 0x288 : 0x88;
    for(i = 200; i; i--) if(inportb(reg) != 0xff) {
      OPNReg = reg;
      break;
    }
  }

  /* Detect OPNA */
  if (OPNReg) {
    reg = OPNReg + 0x04;
    for (i = 200; i; i--) if(inportb(reg) != 0xff) {
      OPNAReg = reg;
      break;
    }
  }

  if(OPNReg) {
    if(Verbose) printf("found %s at %03Xh. ",(OPNAReg)? "OPNA":"OPN",OPNReg);
  } else {
    if(Verbose) printf("not found OPN/OPNA. ");
    return -1;
  }

  /* Initialize OPN/OPNA */
  OPNOut(7,0xbf);
  OPNOut(0x2d,0);
  OPNOut(0x27,0);
  OPNOut(0x29,0x83);
  OPNOut(0x10,0xbf);
  OPNOut(0x11,0x3f);

  for(ch = 0; ch < 16; ch++) {
    OPNOut(0x40 + ch, 0x7f);
    OPNOut(0x140 + ch, 0x7f);
  }
  for(reg = 0x18; reg < 0x1e; reg++)
    OPNOut(reg, 0xdf);

  for(ch = 0; ch < 6; ch++) {
    reg = (ch > 2)? (ch - 3) | 0x100 : ch;
    for(i = 0x30, j = 0; j < 12; i += 8)
    { /* This part is by Hosozawa and his friend. */
      OPNOut(reg + i, OPNVoice[16][j]);
      OPNOut(reg + i + 4,OPNVoice[17][j++]);
    }

    OPNOut(reg + 0x90, 0); OPNOut(reg + 0x98, 0);
    OPNOut(reg + 0xB0, OPNVoice[16][12]);
    OPNOut(reg + 0xB4, 0xd0);
    OPNOut(0x28, ((ch > 2)? ch + 1 : ch) | 0x30);
  }
  return -1;
}


void PSGOutOPN(byte R,byte V)
{
  byte ch;
  dword F;

  PSG[R]=V;
  if(!OPNReg) return;
  switch(R) {
    case 0:
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
      ch=R>>1;
      F=(R&1)? PSG[R-1]|(dword)(V<<8)&0xf00:V|(dword)(PSG[R+1]<<8)&0xf00;
      F=((F+1)*124800)/111861-1;
      OPNOut(ch<<1,F&0xff);
      OPNOut(0x01|(ch<<1),F>>8);
      break;
    case 6:
      F=(V+1)*124800/111861-1;
      OPNOut(6,F);
      break;
    case 7:
      OPNOut(7,V&0x3f|0x80);
      break;
    case 8:
    case 9:
    case 10:
      OPNOut(R,(V<16&&V>PSGVolOffset)? V-PSGVolOffset:V);
      break;
    default:
      OPNOut(R,V);
      break;
  }
}


byte PSGInOPN(void)
{
  if(OPNReg) {
    outportb(OPNReg,0xe);
    return inportb(OPNReg+2);
  } else return 0xff;
}



void OPLLOutOPN(byte R,byte V)
{
  dword F,reg;
  byte I,C;

  switch(R) {
    case 0x20:
    case 0x21:
    case 0x22:
    case 0x23:
    case 0x24:
    case 0x25:
      reg=(R>0x22)? 0x100+R-0x23:R-0x20;
      F=( OPLL[R-0x20+0x10] | ( (dword)(V&1)<<8 ) )*200000/55467;
      OPNOut(reg+0xA4,((V&0x0e)<<2)|(F>>8));
      OPNOut(reg+0xA0,F&0xff);
      OPNOut(0x28, ( (R>0x22)? R-0x23+4:R-0x20 ) | ( (V&0x10)? 0x30:0 ) );
      break;
    case 0x30:
    case 0x31:
    case 0x32:
    case 0x33:
    case 0x34:
    case 0x35:
      reg=(R>0x32)? 0x100+R-0x33:R-0x30;
      if((V&0xf0)!=(OPLL[R]&0xf0)) {
        if(!(V&0xf0)) {
          OPNVoice[0][ 0]=OPLL[0]&0x0f;
          OPNVoice[0][ 1]=OPLL[1]&0x0f;
          OPNVoice[0][ 2]=(OPLL[2]<<1)&0x7e;
          OPNVoice[0][ 3]=0x7f;
          OPNVoice[0][ 4]=(OPLL[4]>>3)&0x1e|(OPLL[0]<<3)&0x80|0x01;
          OPNVoice[0][ 5]=(OPLL[5]>>3)&0x1e|(OPLL[1]<<3)&0x80|0x01;
          OPNVoice[0][ 6]=(OPLL[4]<<1)&0x1e|(OPLL[0]&0x80)|0x01;
          OPNVoice[0][ 7]=(OPLL[5]<<1)&0x1e|(OPLL[1]&0x80)|0x01;
          OPNVoice[0][ 8]=(OPLL[0]&0x20)? 0:OPNVoice[0][6];
          OPNVoice[0][ 9]=(OPLL[1]&0x20)? 0:OPNVoice[0][7];
          OPNVoice[0][10]=OPLL[6];
          OPNVoice[0][11]=OPLL[7];
          OPNVoice[0][12]=(OPLL[3]&0x07)<<3|0x04;
        }
        for(I=0x30,C=0;I<0x90;I+=8)
          OPNOut(reg+I,OPNVoice[V>>4][C++]);
        OPNOut(reg+0x90,0); OPNOut(reg+0x98,0);
        OPNOut(reg+0xB0,OPNVoice[V>>4][12]);
        OPNOut(reg+0xB4,0xd0);
      }
      OPNOut(reg+0x48,(V<<3)&0x78);
      break;
    case 0x0e:
      if(V&0x20)
        OPNOut( 0x10,((V&0x10)? 0x01:0) | ((V&0x08)? 0x02:0) |
          ((V&0x04)? 0x10:0) | ((V&0x02)? 0x04:0) | ((V&0x01)? 0x08:0) );
      break;
    case 0x36:
      if(OPLL[0x0e]&0x20)
        OPNOut(0x18,63-((V&0x0f)<<1)|0xc0);
      break;
    case 0x37:
      if(OPLL[0x0e]&0x20) {
        OPNOut(0x19,63-((V&0x0f)<<1)|0xc0);
        OPNOut(0x1b,63-((V&0xf0)>>3)|0xc0);
      }
      break;
    case 0x38:
      if(OPLL[0x0e]&0x20) {
        OPNOut(0x1a,63-((V&0x0f)<<1)|0xc0);
        OPNOut(0x1c,63-((V&0xf0)>>3)|0xc0);
      }
      break;
    default:
  }
}


void SCCOutOPN(byte R,byte V)
{
  dword F,reg;
  byte i,ch,B;

  switch(R) {
    case  0:
    case  1:
    case  2:
    case  3:
    case  4:
    case  5:
    case  6:
    case  7:
    case  8:
    case  9:
      reg=(R>5)? 0x100+((R-6)>>1):R>>1;
      F=(R&1)? SCC[R-1]|(dword)(V<<8)&0xf00:V|(dword)(SCC[R+1]<<8)&0xf00;
      F=(F<10)? 13866:111860/F;
      B=(F>7366)? 8:(F>3466)? 7:(F>1733)? 6:(F>866)? 5
        :(F>433)? 4:(F>216)? 3:(F>108)? 2:1;
      F=(dword)(F<<(21-B))/55467;
      OPNOut(reg+0xA4,((B-1)<<3)|(F>>8));
      OPNOut(reg+0xA0,F&0xff);
      break;
    case 10:
    case 11:
    case 12:
    case 13:
    case 14:
      reg=(R>12)? R-13:R-10;
      /* This part is by Hosozawa and his friend. */
      OPNOut(reg+0x48,V&0x0f? ((15-V&0x0f)<<1) + 20:127);
      OPNOut(reg+0x48 + 4,V&0x0f? ((15-V&0x0f)<<1) + 20:127);
      break;
    case 15:
       /* This part is by Hosozawa and his friend. */
       OPNOut(0x28,0xf0);
       OPNOut(0x28,0xf1);
       OPNOut(0x28,0xf2);
       OPNOut(0x128,0xf0);
       OPNOut(0x128,0xf1);
       for(i=0,B=V;i<5;i++,B>>=1) {
         if(i>2) { reg = 0x100; ch = i; }
         else { reg = 0; ch = i-3; }
         OPNOut(reg + 0x28,(B&1)? 0xf0:0x00 | ch);
       }
  }
}


void OPNReset(void)
{
  char i;

  OPNOut(7,0xbf);
  for(i=0;i<16;i++) {
    OPNOut(0x40+i,0x7f);
    OPNOut(0x140+i,0x7f);
  }
}
