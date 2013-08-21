/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                      pcats.c                            **/
/**                                                         **/
/** This file contains PC-AT dependent sound drivers.       **/
/**                                                         **/
/** fMSX      Copyright (C) Marat Fayzullin 1994,1995       **/
/** fMSX98-AT Copyright (C) MURAKAMI Reki 1995,1996         **/
/**      You are not allowed to distribute this software    **/
/**      commercially. Please, notify me, if you make any   **/
/**      changes to this file.                              **/
/*************************************************************/

#include <stdio.h>
#include <dos.h>

#include "msx.h"
#include "pcat.h"

byte UseSB16=3;                   /* 1 if use Sound Blaster 16 */

#define CH_OPLL 0
#define CH_SCC 9
#define CH_PSG 14
#define CH_NOISE 17
#define CH_RHYTHM 6

#define VOICE_OPLL 0
#define VOICE_SCC 16
#define VOICE_PSG 17
#define VOICE_NOISE 18
#define VOICE_RHYTHM 19

word ch2reg[18] = {
  0x000, 0x001, 0x002, 0x008, 0x009, 0x00a, 0x010, 0x011, 0x012,
  0x100, 0x101, 0x102, 0x108, 0x109, 0x10a, 0x110, 0x111, 0x112
};

byte OPL3TL[16] = { 0, 1, 2, 3, 4, 6, 8, 10, 12, 16, 20, 28, 36, 44, 52, 63 };

int InitSound(void);
void StopSound(void);


int OPL3Init();                   /*** Initialize OPL3          ***/
void OPL3Out(dword R,byte V);     /*** Write value into an OPL3 ***/
void PSGOutOPL3(byte R,byte V);   /*** OPL3 driver for PSG      ***/
byte PSGInOPL3(void);             /*** GAME port driver         ***/
void OPLLOutOPL3(byte R,byte V);  /*** OPL3 driver for OPLL     ***/
void SCCOutOPL3(byte R,byte V);   /*** OPL3 driver for SCC      ***/

dword OPL3Reg  = 0x220;           /* OPL3 I/O port             */
dword GameReg  = 0x201;           /* Game I/O port             */
dword JoyCal1,JoyCal2;
char JoySwap1 = 0, JoySwap2 = 0;


byte OPL3Voice[][9] = {
  { 0x32,0x32, 0x3f,0x3f, 0xF0,0xF0, 0xFF,0xFF, 0xf1 }, /* @63 */
  { 0x61,0x61, 0x12,0x3f, 0xB4,0x56, 0x14,0x17, 0xfE }, /* @02 */
  { 0x02,0x41, 0x15,0x3f, 0xA3,0xA3, 0x75,0x05, 0xfA }, /* @10 */
  { 0x31,0x11, 0x0E,0x3f, 0xD9,0xB2, 0x11,0xF4, 0xfA }, /* @00 */
  { 0x61,0x31, 0x20,0x3f, 0x6C,0x43, 0x18,0x26, 0xfE }, /* @03 */
  { 0xA2,0x30, 0xA0,0x3f, 0x88,0x54, 0x14,0x06, 0xfE }, /* @04 */
  { 0x31,0x34, 0x20,0x3f, 0x72,0x56, 0x0A,0x1C, 0xfA }, /* @05 */
  { 0x31,0x71, 0x16,0x3f, 0x51,0x52, 0x26,0x24, 0xfE }, /* @06 */
  { 0xE1,0x63, 0x0A,0x3f, 0xFC,0xF8, 0x28,0x29, 0xfD }, /* @09 */
  { 0x61,0x71, 0x0D,0x3f, 0x75,0xF2, 0x18,0x03, 0xfA }, /* @48 */
  { 0x42,0x44, 0x0B,0x3f, 0x94,0xB0, 0x33,0xF6, 0xfC }, /* @24 */
  { 0x01,0x00, 0x06,0x3f, 0xA3,0xE2, 0xF4,0xF4, 0xfD }, /* @14 */
  { 0xF9,0xF1, 0x24,0x3f, 0x95,0xD1, 0xE5,0xF2, 0xfC }, /* @16 */
  { 0x40,0x31, 0x89,0x3f, 0xC7,0xF9, 0x14,0x04, 0xfC }, /* @23 */
  { 0x11,0x11, 0x11,0x3f, 0xC0,0xB2, 0x01,0xF4, 0xf0 }, /* @33 */
  { 0x23,0x43, 0x0F,0x3f, 0xDD,0xBF, 0x4A,0x05, 0xfE }, /* @12 */
  { 0x32,0x34, 0x0E,0x3f, 0xF0,0xF0, 0x0F,0x0F, 0xf8 }, /* SCC tone */
  { 0x32,0x36, 0x1e,0x3f, 0xF0,0xF0, 0x0F,0x0F, 0xfa }, /* PSG tone */
  { 0x22,0x21, 0x00,0x3f, 0xF0,0xF0, 0x0F,0x0F, 0xfe }, /* PSG noise */
  { 0x00,0x00, 0x00,0x3f, 0xf9,0xf7, 0xf9,0xf7, 0xf8 }, /* bass drum */
  { 0x00,0x00, 0x3f,0x3f, 0xf8,0xf6, 0xf8,0xf6, 0xf0 }, /* snare & hi-hat */
  { 0x04,0x01, 0x3f,0x3f, 0xf7,0xf6, 0xf7,0xf6, 0xf0 }  /* tom & cymbal */
};




void OPL3Out(dword R,byte V)
{
  dword reg;
  int i;

  if(!OPL3Reg) return;
  reg=(R>0xff)? OPL3Reg+2:OPL3Reg;
  outportb(reg,R&0xff);
  for(i=0;i<6;i++) inportb(OPL3Reg);
  outportb(reg+1,V);
  for(i=0;i<35;i++) inportb(OPL3Reg);
}



void OPL3SetVoice(byte ch, byte no)
{
  byte i, j;
  dword reg;

  reg = ch2reg[ch] + 0x20;
  for (i = 0, j = 0; i < 4; i++) {
    OPL3Out(reg, OPL3Voice[no][j++]);
    OPL3Out(reg + 3, OPL3Voice[no][j++]);
    reg += 0x20;
  }
  OPL3Out((ch > 8) ? ch - 9 + 0x1c0 : ch + 0xc0, OPL3Voice[no][8]);
}

int OPL3Init()
{
  byte ch,C,i,vn;
  dword I,reg,count;
  byte buf0,buf1;

  i=0;
  while(Env[i]!=NULL) {
    if(sscanf(Env[i++],"BLASTER=A%x ",&OPL3Reg)==1) {
      break;
    }
  }

  OPL3Out(4,0x60);
  OPL3Out(4,0x80);
  buf0 = inportb(OPL3Reg);
  OPL3Out(2,0xff);
  OPL3Out(4,0x21);
  for(i=0;i<120;i++) buf1 = inportb(OPL3Reg);
  OPL3Out(4,0x60);
  OPL3Out(4,0x80);
  if(((buf0 & 0xe0) == 0x00) && ((buf1 & 0xe0) == 0xc0)) {
    OPL3Out(0x105,0x01);
    OPL3Out(0x104,0x00);
    OPL3Out(0x01,0x00);
    OPL3Out(0x08,0x00);
    for(I=0x40;I<0x56;I++) {
      OPL3Out(I,0x3f);
      OPL3Out(I+0x100,0x3f);
    }
    /*** set SCC/PSG tone ***/
    for (ch = CH_SCC; ch < CH_SCC + 5; ch++) {
      OPL3SetVoice(ch, VOICE_SCC);
    }
    for (ch = CH_PSG; ch < CH_PSG + 3; ch++) {
      OPL3SetVoice(ch, VOICE_PSG);
    }
    OPL3SetVoice(CH_NOISE, VOICE_NOISE);

    for (i = 0; i < 18; i++) {
      OPL3Out(ch2reg[i] + 0xe0,0x00); /* waveform */
    }
    OPL3Out(0xbd, 0x00); /* rhythm off */

    /* silent */
    for(I=0xB0;I<0xB9;I++) {
      OPL3Out(I,0);
      OPL3Out(I+0x100,0);
    }
    if(Verbose) printf(" Found YMF-262 at %04Xh",OPL3Reg);
  } else {
    OPL3Reg = 0;
    if(Verbose) printf(" Not Found FM-Synthesizer",OPL3Reg);
  }

  /* joystick support */
  JoyCal1=JoyCal2=0;
  count=0;
  outportb(GameReg,0x0f);
  while(count++<65536) {
    if(!(inportb(GameReg)&0x01)) break;
  }
  if(count<65536) {
     JoyCal1=count;
     if(Verbose) {
       printf(", Joy-A");
       if(JoySwap1) printf("(sw)");
     }
  }
  count=0;
  outportb(GameReg,0x0f);
  while(count++<65536) {
    if(!(inportb(GameReg)&0x04)) break;
  }
  if(count<65536) {
     JoyCal2=count;
     if(Verbose) {
       printf(", Joy-B");
       if(JoySwap2) printf("(sw)");
     }
  }

  if(Verbose) printf(". ");
  return 1;
}


/****************************************************************/
/*** Write number into given PSG register.                    ***/
/****************************************************************/
void PSGOut(byte R,byte V)
{
  if(UseSB16) PSGOutOPL3(R,V);
  PSG[R]=V;
}



void PSGOutOPL3(byte R,byte V)
{
  dword freq, f, reg;
  byte i,ch,B;
  static byte keyon[4] = {0, 0, 0, 0};

  switch(R) {
    case  0:
    case  1:
    case  2:
    case  3:
    case  4:
    case  5:
      ch = R >> 1;
      if (R & 0x01) {
         f = PSG[R - 1] | ((V & 15) << 8);
      } else {
         f = V | ((PSG[R + 1] & 15) << 8);
      }
      freq = 111860L / (f ? f : 1);
      B = (freq > 6208) ? 8 : (freq > 3104) ? 7 : (freq > 1552) ? 6
        : (freq >  776) ? 5 : (freq >  388) ? 4 : (freq >  194) ? 3
        : (freq >   97) ? 2 : 1;
      f = (freq << (20 - B) ) / 49716;
      OPL3Out(ch + 0x1a5, f & 0xff);
      keyon[ch] = (keyon[ch] & 0x20) | ((f >> 8) & 0x03) | ((B - 1) << 2);
      OPL3Out(ch + 0x1b5, keyon[ch]);
      break;

    case 6:
      f = ((V & 31) + 32) << 6;
      freq = 111860L / (f ? f : 1);
      B = (freq > 6208) ? 8 : (freq > 3104) ? 7 : (freq > 1552) ? 6
        : (freq >  776) ? 5 : (freq >  388) ? 4 : (freq >  194) ? 3
        : (freq >   97) ? 2 : 1;
      f = (freq << (20 - B) ) / 49716;
      OPL3Out(0x1a8, f & 0xff);
      keyon[3] = (keyon[3] & 0x20) | ((f >> 8) & 0x03) | (B << 2);
      OPL3Out(0x1b8, keyon[3]);
      break;

    case 7:
      PSG[7] = V;
      PSGOutOPL3(8, PSG[8]);
      PSGOutOPL3(9, PSG[9]);
      PSGOutOPL3(10, PSG[10]);
      break;

    case 8:
    case 9:
    case 10:
      ch = R - 8;
      V = (V & 0x10) ? 0 : (V & 15);
      if ((PSG[7] >> ch) & 1 || V == 0) {   /* tone disable */
        keyon[ch] &= 0xdf;
        OPL3Out(ch + 0x1b5, keyon[ch]);
      } else {
        if ((keyon[ch] & 0x20) == 0) {
          keyon[ch] |= 0x20;
          OPL3Out(ch + 0x1b5, keyon[ch]);
        }
        OPL3Out(ch2reg[ch + CH_PSG] + 0x43, OPL3TL[15 - V]);
      }

      if ((PSG[7] >> (3 + ch)) & 1 || V == 0) { /* noise disable */
        keyon[3] &= 0xdf;
        OPL3Out(0x1b8, keyon[3]);
      } else {
        if ((keyon[3] & 0x20) == 0) {
          keyon[3] |= 0x20;
          OPL3Out(0x1b8, keyon[3]);
        }
        OPL3Out(ch2reg[CH_NOISE] + 0x43, OPL3TL[15 - V]);
      }

      break;

    case 11:
    case 12:
    case 13:
    case 14:
    case 15:
       break;
  }
}


byte PSGIn(byte R)
{
  if(R==0x0e) {
    return PSGInOPL3() | 0xc0;
  } else return PSG[R];
}




byte PSGInOPL3(void)
{
  byte dat,Out=0xff;
  int x1,y1,x2,y2,cmax,count;
  byte trig;

  if(JoyCal1==0 && JoyCal2==0) return 0x3f;

  outportb(GameReg,0x0f);
  x1=x2=y1=y2=count=0;
  cmax=JoyCal1*2;
  if(cmax<JoyCal2*2) cmax=JoyCal2*2;

  while(count<cmax) {
    dat=inportb(GameReg);
    if(dat&0x01) x1++;
    if(dat&0x04) x2++;
    if(dat&0x02) y1++;
    if(dat&0x08) y2++;
    count++;
  }
  if(JoyCal1 && (PSG[15]&0x40)==0) {
    Out&=(x1<JoyCal1*0.5)? 0xfb:0xff;
    Out&=(x1>JoyCal1*1.5)? 0xf7:0xff;
    Out&=(y1<JoyCal1*0.5)? 0xfe:0xff;
    Out&=(y1>JoyCal1*1.5)? 0xfd:0xff;
    Out&=((dat&0x30)|0x0f);
    if(JoySwap1) {
      if((Out & 0x30) == 0x10 || (Out & 0x30) == 0x20) Out^=0x30;
    }
  }
  if(JoyCal2 && (PSG[15]&0x40)==0x40) {
    Out&=(x2<JoyCal2*0.5)? 0xfb:0xff;
    Out&=(x2>JoyCal2*1.5)? 0xf7:0xff;
    Out&=(y2<JoyCal2*0.5)? 0xfe:0xff;
    Out&=(y2>JoyCal2*1.5)? 0xfd:0xff;
    Out&=(((dat&0xc0)>>2)|0x0f);
    if(JoySwap2) {
      if((Out & 0x30) == 0x10 || (Out & 0x30) == 0x20) Out^=0x30;
    }
  }

  return Out&0x3f;
}


/****************************************************************/
/*** Write number into given OPLL register.                   ***/
/****************************************************************/
void OPLLOut(byte R,byte V)
{
  if(UseSB16) OPLLOutOPL3(R,V);
  OPLL[R]=V;
}


void OPLLOutOPL3(byte R,byte V)
{
  dword F;
  byte I,C,ch,reg;
  byte vno;
  static char rhythm_mode = 0;

  switch (R) {
    case 0x0e:               /* rhythm */
      if (V & 0x20) {
        if (!rhythm_mode) {
          rhythm_mode = 1;
          for (ch = 0; ch < 3; ch++) {
            OPL3SetVoice(CH_RHYTHM + ch, VOICE_RHYTHM + ch);
          }
          OPL3Out(0x53, OPL3TL[OPLL[36] & 15]);  /* rhythm volome */
          OPL3Out(0x51, OPL3TL[OPLL[37] >> 4]);
          OPL3Out(0x54, OPL3TL[OPLL[37] & 15]);
          OPL3Out(0x52, OPL3TL[OPLL[38] >> 4]);
          OPL3Out(0x55, OPL3TL[OPLL[38] & 15]);
        }
        OPL3Out(0xbd, V);
      } else {
        if (rhythm_mode) {
          rhythm_mode = 0;
          OPL3Out(0xbd, 0);
        }
      }
      break;

    case 0x10:   /* freq (F-Number) */
    case 0x11:
    case 0x12:
    case 0x13:
    case 0x14:
    case 0x15:
    case 0x16:
    case 0x17:
    case 0x18:
      ch = R - 0x10;
      F = (((OPLL[ch + 0x20] & 1) << 8) | V) << 1;
      OPL3Out(ch + 0xa0, F & 0xff);
      break;

    case 0x20:  /* freq (F-Number, block, key-on/off) */
    case 0x21:
    case 0x22:
    case 0x23:
    case 0x24:
    case 0x25:
    case 0x26:
    case 0x27:
    case 0x28:
      ch=R-0x20;
      F=(OPLL[ch+0x10]|((dword)(V&1)<<8)) << 1;
      OPL3Out(ch+0xa0,F&0xff);
      OPL3Out(ch+0xb0,(V<<1)&0x3c|(F>>8));
      break;

    case 0x36:                              /* inst and vol */
      if (rhythm_mode) {
        OPL3Out(0x53, OPL3TL[V & 15]);
        break;
      }
      /* BREAKTHROUGH if not rhythm mode */
    case 0x37:
      if (rhythm_mode) {
        OPL3Out(0x51, OPL3TL[V >> 4]);
        OPL3Out(0x54, OPL3TL[V & 15]);
        break;
      }
      /* BREAKTHROUGH if not rhythm mode */
    case 0x38:
      if (rhythm_mode) {
        OPL3Out(0x52, OPL3TL[V >> 4]);
        OPL3Out(0x55, OPL3TL[V & 15]);
        break;
      }
      /* BREAKTHROUGH if not rhythm mode */
    case 0x30:
    case 0x31:
    case 0x32:
    case 0x33:
    case 0x34:
    case 0x35:
      ch = R - 0x30;
      reg = ch2reg[ch + CH_OPLL];
      vno = V >> 4;
      if (vno != (OPLL[R] >> 4)) {
        if (vno == 0) {
          memcpy(OPL3Voice[0], OPLL, 8);
          OPL3Voice[0][8] = 0x30 | (OPLL[3] << 1) & 0x0e; /* make voice */
        }
        for(I = reg + 0x20, C = 0; C < 8; I += 0x20) {
          OPL3Out(I    , OPL3Voice[vno][C++]);
          OPL3Out(I + 3, OPL3Voice[vno][C++]);
        }
        OPL3Out(ch + 0xc0, OPL3Voice[vno][8]);
      }
      OPL3Out(reg + 0x43, OPL3Voice[vno][3] & 0xc0 | OPL3TL[V & 15]);
      break;
    default:
  }
}


/****************************************************************/
/*** Write number into given SCC register.                    ***/
/****************************************************************/
void SCCOut(byte R,byte V)
{
  if(R>15) return;
  if(UseSB16) SCCOutOPL3(R,V);
  SCC[R]=V;
}


void SCCOutOPL3(byte R,byte V)
{
  dword f, freq, reg;
  byte i, ch, B;
  static byte keyon[5] = {0x0, 0x0, 0x0, 0x0, 0x0};

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
      ch = R >> 1;
      if (R & 0x01) {
         f = SCC[R - 1] | ((V & 15) << 8);
      } else {
         f = V | ((SCC[R + 1] & 15) << 8);
      }
      freq = 111860L / (f ? f : 1);
      B = (freq > 6208) ? 8 : (freq > 3104) ? 7 : (freq > 1552) ? 6
        : (freq >  776) ? 5 : (freq >  388) ? 4 : (freq >  194) ? 3
        : (freq >   97) ? 2 : 1;
      f = (freq << (20 - B) ) / 49716;
      OPL3Out(ch + 0x1a0, f & 0xff);
      keyon[ch] = (keyon[ch] & 0x20) | ((f >> 8) & 0x03) | ((B - 1) << 2);
      OPL3Out(ch + 0x1b0, keyon[ch]);
      break;

    case 10:
    case 11:
    case 12:
    case 13:
    case 14:
      ch = R - 10;
      V &= 15;
      if (V == 0 || (((SCC[15] >> ch) & 1) == 0)) {   /* tone disable */
        keyon[ch] &= 0xdf;
        OPL3Out(ch + 0x1b0, keyon[ch]);
      } else {
        if ((keyon[ch] & 0x20) == 0) {
          keyon[ch] |= 0x20;
          OPL3Out(ch + 0x1b0, keyon[ch]);
        }
        OPL3Out(ch2reg[ch + CH_SCC] + 0x43, OPL3TL[15 - V]);
      }
      break;

    case 15:
      SCC[15] = V;
      SCCOutOPL3(10, SCC[10]);
      SCCOutOPL3(11, SCC[11]);
      SCCOutOPL3(12, SCC[12]);
      SCCOutOPL3(13, SCC[13]);
      SCCOutOPL3(14, SCC[14]);
      break;
  }
}



int InitSound(void)
{
  int status=1;

  if(UseSB16) status=OPL3Init();
  return status;
}


void ResetSound(void)
{
  byte i;

  if(UseSB16) {
    for(i=0x40;i<0x56;i++) {
      OPL3Out(i,0x3f);
      OPL3Out(i+0x100,0x3f);
    }
    for(i=0xB0;i<0xB9;i++) {
      OPL3Out(i,0);
      OPL3Out(i+0x100,0);
    }
  }
}

