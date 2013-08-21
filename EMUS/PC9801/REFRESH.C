/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                        refresh.c                        **/
/**                                                         **/
/** This file contains device-independent screen refresh    **/
/** drivers.                                                **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1994,1995          **/
/** fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            **/
/**      You are not allowed to distribute this software    **/
/**      commercially. Please, notify me, if you make any   **/
/**      changes to this file.                              **/
/*************************************************************/

#include <stdio.h>
#include <memory.h>
#include <pc.h>
#include "MSX.h"

#define EVENPAGE (InterLaceMode&&InterLacePage&&(VDP[9]&0x04)&&(VDP[2]&0x20))

byte InterLaceMode = 0;
byte InterLacePage = 0;

byte *ScreenBuf = NULL;             /* Screen image buffer    */
byte Pal[16] =                      /* Palette assign         */
  {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};


void CheckSprites(void)
{
}

void ColorSprites(byte Y1,byte Y2)
{
  byte N,M,I,J,X,Y,C,H,line;
  byte *P,*T,*AT,*PT,*CT;
  int L;

  H=ScanLines212? 212:192;

  for(N=0,AT=SprTab;(N<32)&&(AT[0]!=216);N++,AT+=4);
  CT=SprTab-0x0200+((long)N<<4)-16;AT-=4;
  M=SolidColor0;

  if(Sprites16x16) {
    for(;N;N--,AT-=4,CT-=16) {
      P=ScreenBuf+WIDTH*(HEIGHT-192)/2+(WIDTH-256)/2;
      P-=((VDP[18]+8)&15)-8+((((VDP[18]>>4)+8)&15)-8)*WIDTH;
      PT=SprGen+((dword)(AT[2]&0xFC)<<3);T=CT;
      line=Y=AT[0]+1-VDP[23];

      if(BigSprites) {
        if(Y<H) { P+=WIDTH*Y;Y=(Y>H-32)? (H-Y)>>1:16; }
        else    { Y=256-Y;PT+=(Y>>1); T+=(Y>>1);Y=(Y<32)? (32-Y)>>1:0; }
        for(;Y;Y--,T++,line++,PT++,P+=WIDTH*2) {
          L=*T&0x80? AT[1]-32:AT[1];C=*T&0x0F;
          if((Y1<=line)&&(line<=Y2)&&(L<=256-32)&&(L>=0)&&(C||M)) {
            P+=L;J=*PT;I=*(PT+16);
            if(*T&0x40)
              for(X=8,C|=(C<<4);X;X--,J<<=1,I<<=1,P+=2) {
                if(J&0x80) *P=*(P+1)=*(P+WIDTH)=*(P+WIDTH+1)=C;
                if(I&0x80) *(P+16)=*(P+17)=*(P+WIDTH+16)=*(P+WIDTH+17)=C;
              }
            else
              for(X=8;X;X--,J<<=1,I<<=1,P+=2) {
                if(J&0x80) *P=*(P+1)=*(P+WIDTH)=*(P+WIDTH+1)=(*P>>4)|C;
                if(I&0x80) *(P+16)=*(P+17)=*(P+WIDTH+16)
                             =*(P+WIDTH+17)=(*(P+8)>>4)|C;
              }
            P-=16+L;
          }
        }
      } else {
        if(Y<H) { P+=WIDTH*Y;Y=(Y>H-16)? H-Y:16; }
        else    { Y=256-Y;PT+=Y;T+=Y;Y=(Y<16)? 16-Y:0; }
        for(;Y;Y--,T++,line++,PT++,P+=WIDTH) {
          L=*T&0x80? AT[1]-32:AT[1];C=*T&0x0F;
          if((Y1<=line)&&(line<=Y2)&&(L<=256-16)&&(L>=0)&&(C||M)) {
            P+=L;J=*PT;I=*(PT+16);
            if(*T&0x40)
              for(X=8,C|=(C<<4);X;X--,J<<=1,I<<=1,P++) {
                if(J&0x80) *P=C;
                if(I&0x80) *(P+8)=C;
              }
            else
              for(X=8;X;X--,J<<=1,I<<=1,P++) {
                if(J&0x80) *P=(*P>>4)|C;
                if(I&0x80) *(P+8)=(*(P+8)>>4)|C;
              }
            P-=8+L;
          }
        }
      }
    }
  } else {
    for (; N; N--, AT -= 4, CT -= 16) {
      /* set view's start address */
      P = ScreenBuf + WIDTH * (HEIGHT - 192) / 2 + (WIDTH - 256) / 2;
      /* adjust view's start address by VDP[19]*/
      P -= ((VDP[18] + 8) & 15) - 8;
      P -= ((((VDP[18] >> 4) + 8) & 15) - 8) * WIDTH;

      /* pattern generater table addr */
      PT = SprGen + ((dword)AT[2] << 3);
      T=CT;

      /* top scanline-No of putting sprite */
      line = (AT[0] + 1 - VDP[23]) & 255;

      /* the scanlino-No is within the range of the screen */
      /* Y is height of the sprite */
      if (line < H) {
         P += (word)line * WIDTH;
         Y = (line > H - 8) ? H - line : 8;
      } else if (256 - 8 < line) {
        Y = 8 - (256 - line);
        PT += 8 - Y;
        T += 8 - Y;
      } else {
        continue;
      }

      /* put the sprite pattern */
      for (; Y; Y--, T++, line++, PT++, P += WIDTH) {
        L = *T & 0x80 ? AT[1] - 32 : AT[1];
        C = *T & 0x0F;
        if ((Y1 <= line) && (line <= Y2) &&
            (0 <= L) && (L <= 256 - 8) && (C || M)) {
          P += L;      /* L is x of the sprite */
          J = *PT;     /* sprite pattern */
          if (*T & 0x40) {
            /* if cc bit is 1 */
            for (X = 8, C |= (C << 4); X; X--, J <<= 1, P++)
              if (J & 0x80) *P = C;
          } else {
            /* cc bit is 0 */
            for (X = 8; X; X--, J <<= 1, P++)
              if (J & 0x80) *P = (*P >> 4) | C;
          }
          P -= 8 + L;
        }
      }
    }
  }
}


void ColorSprites512(byte Y1,byte Y2)
{
  byte N,M,I,J,X,Y,C,H,line;
  byte *P,*T,*AT,*PT,*CT;
  int L;

  H=ScanLines212? 212:192;

  for(N=0,AT=SprTab;(N<32)&&(AT[0]!=216);N++,AT+=4);
  CT=SprTab-0x0200+((long)N<<4)-16;AT-=4;
  M=SolidColor0;

  if(Sprites16x16)
    for(;N;N--,AT-=4,CT-=16) {
      P=ScreenBuf+WIDTH*2*(HEIGHT-192)/2+(WIDTH*2-512)/2;
      P-=(((VDP[18]+8)&15)-8+((((VDP[18]>>4)+8)&15)-8)*WIDTH)*2;
      PT=SprGen+((long)(AT[2]&0xFC)<<3);T=CT;

      line=Y=AT[0]+1-VDP[23];
      if(Y<H) { P+=(word)Y*WIDTH*2;Y=(Y>H-16)? H-Y:16; }
      else    { Y=256-Y;PT+=Y;T+=Y;Y=(Y<16)? 16-Y:0; }

      for(;Y;Y--,T++,PT++,line++,P+=WIDTH*2) {
        L=*T&0x80? AT[1]-32:AT[1];C=*T&0x0F;
        if((Y1<=line)&&(line<=Y2)&&(L<=256-16)&&(L>=0)&&(C||M)) {
          P+=L*2;J=*PT;I=*(PT+16);
          if(*T&0x40)
            for(X=8,C|=(C<<4);X;X--,J<<=1,I<<=1,P+=2) {
              if(J&0x80) *P=*(P+1)=C;
              if(I&0x80) *(P+16)=*(P+17)=C;
            }
          else
            for(X=8;X;X--,J<<=1,I<<=1,P+=2) {
              if(J&0x80) *P=*(P+1)=(*P>>4)|C;
              if(I&0x80) *(P+16)=*(P+17)=(*(P+16)>>4)|C;
            }
          P-=16+L*2;
        }
      }
    }
  else
    for(;N;N--,AT-=4,CT-=16) {
      P=ScreenBuf+WIDTH*2*(HEIGHT-192)/2+(WIDTH*2-512)/2;
      P-=(((VDP[18]+8)&15)-8+((((VDP[18]>>4)+8)&15)-8)*WIDTH)*2;
      PT=SprGen+((int)AT[2]<<3);T=CT;

      line=Y=AT[0]+1-VDP[23];
      if(Y<H) { P+=(word)Y*WIDTH*2;Y=(Y>H-8)? H-Y:8; }
      else    { Y=256-Y;PT+=Y;T+=Y;Y=(Y<8)? 8-Y:0; }

      for(;Y;Y--,T++,line++,PT++,P+=WIDTH*2) {
        L=*T&0x80? AT[1]-32:AT[1];C=*T&0x0F;
        if((Y1<=line)&&(line<=Y2)&&(L<=256-8)&&(L>=0)&&(C||M)) {
          P+=L*2;J=*PT;
          if(*T&0x40)
            for(X=8,C|=(C<<4);X;X--,J<<=1,P+=2)
              if(J&0x80) *P=*(P+1)=C;
          else
            for(X=8;X;X--,J<<=1,P+=2)
              if(J&0x80) *P=*(P+1)=(*P>>4)|C;
          P-=16+L*2;
        }
      }
    }
}


void Sprites(byte Y1,byte Y2)
{
  byte N,M,I,J,X,Y,C,H;
  byte *P,*T,*S;
  int L;

  for(N=0,S=SprTab;(N<32)&&(S[0]!=208);N++,S+=4);
  H=ScanLines212? 212:192; M=SolidColor0; S-=4;

  if(Sprites16x16)
    for(;N;N--,S-=4) {
      C=S[3]&0x0F;L=S[3]&0x80? S[1]-32:S[1];
      if((L<=256-(BigSprites)? 32:16)&&(L>=0)&&(C||M)) {
        P=ScreenBuf+WIDTH*(HEIGHT-192)/2+(WIDTH-256)/2+L;
        P-=((VDP[18]+8)&15)-8+((((VDP[18]>>4)+8)&15)-8)*WIDTH;
        T=SprGen+((long)(S[2]&0xFC)<<3);
        Y=S[0]+1-VDP[23];

        if(BigSprites) {
          if(Y<H) { P+=WIDTH*Y;Y=(Y>H-32)? (H-Y)>>1:16; }
          else    { Y=256-Y;T+=(Y>>1);Y=(Y<32)? (32-Y)>>1:0; }
          for(;Y;Y--,T++,P+=WIDTH*2-16)
            for(X=8,J=*T,I=*(T+16);X--;J<<=1,I<<=1,P+=2) {
              if(J&0x80) *P=*(P+1)=*(P+WIDTH)=*(P+WIDTH+1)=C;
              if(I&0x80) *(P+16)=*(P+17)=*(P+WIDTH+16)=*(P+WIDTH+17)=C;
            }
        } else {
          if(Y<H) { P+=WIDTH*Y;Y=(Y>H-16)? H-Y:16; }
          else    { Y=256-Y;T+=Y;Y=(Y<16)? 16-Y:0; }
          for(;Y;Y--,T++,P+=WIDTH-8)
            for(X=8,J=*T,I=*(T+16);X--;J<<=1,I<<=1,P++) {
              if(J&0x80) *P=C;
              if(I&0x80) *(P+8)=C;
            }
        }
      }
    }
  else
    for(;N;N--,S-=4) {
      C=S[3]&0x0F;L=S[3]&0x80? S[1]-32:S[1];
      if((L<=256-(BigSprites)? 16:8)&&(L>=0)&&(C||M)) {
        P=ScreenBuf+WIDTH*(HEIGHT-192)/2+(WIDTH-256)/2+L;
        P-=((VDP[18]+8)&15)-8+((((VDP[18]>>4)+8)&15)-8)*WIDTH;
        T=SprGen+((long)S[2]<<3);
        Y=S[0]+1-VDP[23];

        if(BigSprites) {
          if(Y<H) { P+=WIDTH*Y;Y=(Y>H-16)? (H-Y)>>1:8; }
          else    { Y=256-Y;T+=(Y>>1);Y=(Y<16)? (16-Y)>>1:0; }
          for(;Y;Y--,T++,P+=WIDTH*2-16)
            for(X=0,J=*T;X<8;X++,J<<=1,P+=2)
              if(J&0x80) *P=*(P+WIDTH)=*(P+1)=*(P+WIDTH+1)=C;
        } else {
          if(Y<H) { P+=WIDTH*Y;Y=(Y>H-8)? H-Y:8; }
          else    { Y=256-Y;T+=Y;Y=(Y<8)? 8-Y:0; }
          for(;Y;Y--,T++,P+=WIDTH-8)
            for(X=0,J=*T;X<8;X++,J<<=1,P++)
              if(J&0x80) *P=C;
        }
      }
    }
}


void RefreshScrF(byte Y1,byte Y2)
{
  if(Verbose&0x08)
    printf
    (
      "ScrMODE %d: ChrTab=%X ChrGen=%X ColTab=%X SprTab=%X SprGen=%X\n",
      ScrMode,ChrTab-VRAM,ChrGen-VRAM,ColTab-VRAM,SprTab-VRAM,SprGen-VRAM
    );
}

void RefreshTx40(byte Y1,byte Y2)
{
  byte X,Y,J,K,FC,BC;
  byte *P,*S,*T;
  byte *G;

  if(Y1==0) memset(ScreenBuf,Pal[BGColor],WIDTH*HEIGHT);
  if(!ScreenON) return;

  P=ScreenBuf+WIDTH*(HEIGHT-192)/2+(WIDTH-256)/2;
  P-=((VDP[18]+8)&15)-8-(VDP[27]&7)+((((VDP[18]>>4)+8)&15)-8)*WIDTH;
  T=ChrTab; G=ChrGen;
  BC=Pal[BGColor];FC=Pal[FGColor];

  for(Y=ScanLines212? 26:24;Y;Y--,P+=WIDTH*8-6*40)
    for(X=0;X<40;X++,T++) {
      S=G+((long)*T<<3);
      for(J=0;J<8;J++) {
        K=*S++;
        *P++=K&0x80? FC:BC;*P++=K&0x40? FC:BC;
        *P++=K&0x20? FC:BC;*P++=K&0x10? FC:BC;
        *P++=K&0x08? FC:BC;*P  =K&0x04? FC:BC;
        P+=WIDTH-5;
      }
      P+=6-WIDTH*8;
    }
}

void RefreshTx80(byte Y1,byte Y2)
{
  byte X,Y,J,K,L,FC,BC;
  byte *P,*S,*T,*U;
  byte *G;

  if(Y1==0) memset(ScreenBuf,Pal[BGColor],WIDTH*2*HEIGHT);
  if(!ScreenON) return;

  P=ScreenBuf+WIDTH*2*(HEIGHT-192)/2+(WIDTH*2-512)/2;
  P-=((VDP[18]+8)&15-8-VDP[27]&7+(((VDP[18]>>4)+8)&5-8)*WIDTH)*2;
  T=ChrTab; G=ChrGen; U=ColTab;

  for(Y=ScanLines212? 26:24;Y;Y--,P+=WIDTH*2*8-6*80)
    for(X=0;X<80;X++,T++) {
      S=G+((long)*T<<3);
      if(X % 8 == 0) L=*U++;
      if(L & 0x80) {
         BC=Pal[XBGColor];FC=Pal[XFGColor];
      } else {
         BC=Pal[BGColor];FC=Pal[FGColor];
      }
      L<<=1;
      for(J=0;J<8;J++) {
        K=*S++;
        *P++=K&0x80? FC:BC;*P++=K&0x40? FC:BC;
        *P++=K&0x20? FC:BC;*P++=K&0x10? FC:BC;
        *P++=K&0x08? FC:BC;*P  =K&0x04? FC:BC;
        P+=WIDTH*2-5;
      }
      P+=6-WIDTH*2*8;
    }
}


void RefreshScr1(byte Y1,byte Y2)
{
  byte X,Y,J,K,FC,BC;
  byte *P,*T;
  dword offset;

  if(Y1==0) memset(ScreenBuf,Pal[BGColor],WIDTH*HEIGHT);
  if(!ScreenON) return;

  P=ScreenBuf+WIDTH*(HEIGHT-192)/2+Y1*WIDTH+(WIDTH-256)/2;
  P-=((VDP[18]+8)&15)-8-(VDP[27]&7)+((((VDP[18]>>4)+8)&15)-8)*WIDTH;
  J=VDP[23]+Y1; T=ChrTab+((J&0xf8)<<2);

  for(Y=Y1;Y<=Y2;Y++,P+=WIDTH-256) {
    if(!J) T=ChrTab;
    for(X=0;X<32;X++) {
      BC=*(ColTab+(*T>>3));
      K=*(ChrGen+(J&0x07)+(*T++<<3));
      FC=Pal[BC>>4]; BC=Pal[BC&0x0F];
      *P++=K&0x80? FC:BC; *P++=K&0x40? FC:BC;
      *P++=K&0x20? FC:BC; *P++=K&0x10? FC:BC;
      *P++=K&0x08? FC:BC; *P++=K&0x04? FC:BC;
      *P++=K&0x02? FC:BC; *P++=K&0x01? FC:BC;
    }
    if(++J&7) T-=32;
  }
  if(!SpritesOFF) Sprites(Y1,Y2);
}


void RefreshScr2(byte Y1,byte Y2)
{
  byte X,Y,J,K,FC,BC;
  byte *P,*T;
  dword offset;

  if(Y1==0) memset(ScreenBuf,Pal[BGColor],WIDTH*HEIGHT);
  if(!ScreenON) return;

  P=ScreenBuf+WIDTH*(HEIGHT-192)/2+Y1*WIDTH+(WIDTH-256)/2;
  P-=((VDP[18]+8)&15)-8-(VDP[27]&7)+((((VDP[18]>>4)+8)&15)-8)*WIDTH;
  J=VDP[23]+Y1; T=ChrTab+((J&0xf8)<<2);

  for(Y=Y1;Y<=Y2;Y++,P+=WIDTH-256) {
    if(!J) T=ChrTab;
    for(X=0;X<32;X++) {
      offset=((J&0xc0)<<5)+(J&0x07)+(*T++<<3);
      BC=*(ColTab+offset); K=*(ChrGen+offset);
      FC=Pal[BC>>4]; BC=Pal[BC&0x0F];
      *P++=K&0x80? FC:BC; *P++=K&0x40? FC:BC;
      *P++=K&0x20? FC:BC; *P++=K&0x10? FC:BC;
      *P++=K&0x08? FC:BC; *P++=K&0x04? FC:BC;
      *P++=K&0x02? FC:BC; *P++=K&0x01? FC:BC;
    }
    if(++J&7) T-=32;
  }
  if(!SpritesOFF)
    if(ScrMode==2) Sprites(Y1,Y2);
    else ColorSprites(Y1,Y2);
}


void RefreshScr3(byte Y1,byte Y2)
{
  byte X,Y,J,M,C1,C2;
  byte *P,*T,*C;

  if(Y1==0) memset(ScreenBuf,Pal[BGColor],WIDTH*HEIGHT);
  if(!ScreenON) return;

  P = ScreenBuf + WIDTH * (HEIGHT - 192) / 2 + (WIDTH - 256) / 2 + Y1 * WIDTH;
  P-=((VDP[18]+8)&15)-8-(VDP[27]&7)+((((VDP[18]>>4)+8)&15)-8)*WIDTH;

  for(Y = Y1; Y <= Y2; Y++, P += WIDTH - 8 * 32) {
    C = ChrTab + (((long)Y & 0xf8) << 2);
    for(X = 0; X < 32; X++) {
      T = ChrGen + ((long)*C << 3) + ((Y >> 2) & 0x07);
      C1 = Pal[*T >> 4]; C2 = Pal[*T & 15];
      *P++ = C1; *P++ = C1; *P++ = C1; *P++ = C1;
      *P++ = C2; *P++ = C2; *P++ = C2; *P++ = C2;
      C++;
    }
  }
  if(!SpritesOFF) Sprites(Y1,Y2);
}



void RefreshScr5(byte Y1,byte Y2)
{
  byte X,Y,J,C;
  byte *P,*T,*Tab;

  if(Y1==0) memset(ScreenBuf,Pal[BGColor],WIDTH*HEIGHT);
  if(!ScreenON) return;

  P=ScreenBuf+WIDTH*(HEIGHT-192)/2+Y1*WIDTH+(WIDTH-256)/2;
  P-=((VDP[18]+8)&15)-8-(VDP[27]&7)+((((VDP[18]>>4)+8)&15)-8)*WIDTH;
  if(EVENPAGE) Tab=ChrTab-0x8000; else Tab=ChrTab;
  J=VDP[23]+Y1; T=ChrTab+((word)J<<7);

  for(Y=Y1;Y<=Y2;Y++,J++,P+=WIDTH-256) {
    if(!J) T=Tab;
    for(X=0;X<128;X++,T++) {
      *P++=Pal[*T>>4]; *P++=Pal[*T&0x0F];
    }
  }
  if(!SpritesOFF) ColorSprites(Y1,Y2);
}


void RefreshScr6(byte Y1,byte Y2)
{
  byte X,Y,J,C;
  byte *P,*T,*Tab;

  if(Y1==0) memset(ScreenBuf,Pal[BGColor],WIDTH*2*HEIGHT);
  if(!ScreenON) return;

  P=ScreenBuf+WIDTH*2*(HEIGHT-192)/2+Y1*WIDTH*2+(WIDTH*2-512)/2;
  P-=(((VDP[18]+8)&15)-8-(VDP[27]&7)+((((VDP[18]>>4)+8)&15)-8)*WIDTH)*2;
  if(EVENPAGE) Tab=ChrTab-0x8000; else Tab=ChrTab;
  J=VDP[23]+Y1; T=Tab+((word)J<<7);

  for(Y=Y1;Y<=Y2;Y++,J++,P+=WIDTH*2-512) {
    if(!J) T=Tab;
    for(X=0;X<128;X++,T++) {
      *P++=Pal[(*T>>6)&0x03]; *P++=Pal[(*T>>4)&0x03];
      *P++=Pal[(*T>>2)&0x03]; *P++=Pal[*T&0x03];
    }
  }
  if(!SpritesOFF) ColorSprites512(Y1,Y2);
}


void RefreshScr7(byte Y1,byte Y2)
{
  int X;
  byte Y,J,C;
  byte *P,*T,*Tab;

  if(Y1==0) memset(ScreenBuf,Pal[BGColor],WIDTH*2*HEIGHT);
  if(!ScreenON) return;

  P=ScreenBuf+WIDTH*2*(HEIGHT-192)/2+Y1*WIDTH*2+(WIDTH*2-512)/2;
  P-=(((VDP[18]+8)&15)-8-(VDP[27]&7)+((((VDP[18]>>4)+8)&15)-8)*WIDTH)*2;
  if(EVENPAGE) Tab=ChrTab-0x10000; else Tab=ChrTab;
  J=VDP[23]+Y1; T=Tab+((word)J<<8);

  for(Y=Y1;Y<=Y2;Y++,J++,P+=WIDTH*2-512) {
    if(!J) T=Tab;
    for(X=0;X<256;X++,T++) {
      *P++=Pal[*T>>4]; *P++=Pal[*T&0x0F];
    }
  }
  if(!SpritesOFF) ColorSprites512(Y1,Y2);
}


void RefreshScr8(byte Y1,byte Y2)
{
  byte Y,*P,*T,J,*Tab;
  int x;

  if(Y1==0) memset(ScreenBuf,Pal[BGColor],WIDTH*HEIGHT);
  if(!ScreenON) return;

  P=ScreenBuf+WIDTH*(HEIGHT-192)/2+Y1*WIDTH+(WIDTH-256)/2;
  P-=((VDP[18]+8)&15)-8-(VDP[27]&7)+((((VDP[18]>>4)+8)&15)-8)*WIDTH;
  if(EVENPAGE) Tab=ChrTab-0x10000; else Tab=ChrTab;
  J=VDP[23]+Y1; T=ChrTab+((word)J<<8);

  for(Y=Y1;Y<=Y2;Y++,J++,P+=WIDTH) {
    if(!J) T=Tab;
    memcpy(P,T,256); T+=256;
  }
  if(!SpritesOFF) ColorSprites(Y1,Y2);
}


