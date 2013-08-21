/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                       VDP.c                             **/
/**                                                         **/
/** This file contains implementation for the VDP(V9938)    **/
/** commands.                                               **/
/**  HMMC,YMMM,HMMM,HMMV,LMMC,LMCM,LMMM,LMMV,               **/
/**  LINE,SRCH,PSET,POINT                                   **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1994,1995          **/
/** fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            **/
/**     You are not allowed to distribute this software     **/
/**     commercially. Please, notify me, if you make any    **/
/**     changes to this file.                               **/
/*************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <pc.h>
#include "MSX.h"

/******** VDP ********/
byte *VRAM=NULL,*RAM[8];            /* Main and Video RAMs    */
dword VAddrMask  = 0x1ffff;         /* VRAM address mask      */

byte *ChrGen,*ChrTab,*ColTab;       /* VDP tables [screens]   */
byte *SprGen,*SprTab,*SprCol;       /* VDP tables [sprites]   */
byte Palette[16][3] = {             /* Palette registers      */
  {0x00,0x00,0x00},{0x00,0x00,0x00},{0x20,0xC0,0x20},{0x60,0xE0,0x60},
  {0x20,0x20,0xE0},{0x40,0x60,0xE0},{0xA0,0x20,0x20},{0x40,0xC0,0xE0},
  {0xE0,0x20,0x20},{0xE0,0x60,0x60},{0xC0,0xC0,0x20},{0xC0,0xC0,0x80},
  {0x20,0x80,0x20},{0xC0,0x40,0xA0},{0xA0,0xA0,0xA0},{0xE0,0xE0,0xE0},
};
dword VAddr=0;           /* Storage for VRAM addresses in VDP */
byte VKey=1,PKey=1;                 /* Status keys for VDP    */
byte FGColor=0,BGColor=0;           /* Colors                 */
byte XFGColor,XBGColor;             /* Second set of colors   */
byte ScrMode=0;                     /* Current screen mode    */
byte VDPStatus[16] = { 0x80,0x20,0x4C,0,0,0,0,0,0,0,0,0,0,0,0,0 };
byte VDP[64] = {                    /* VDP registers          */
  0x00,0x30,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
};
byte MMCMode;                       /* LMMC,LMCM,HMMC status  */
byte _Mask,_Diff,_LogOp,_Shift[4];
int _SX,_SY,_DX,_DY,_NX,_NY,_N;
int _TX,_TY,_AX,_AY,_BX,_BY,_Line;

/****************************************************************/
/*** Write number into given VDP register.                    ***/
/****************************************************************/
void VDPOut(byte R,byte V)
{
  byte *P,I;
  byte J;

  switch(R)
  {
    case  0:
    case  1: J=ScrMode;
             if(!R) I=((V&0x0E)>>1)|(VDP[1]&0x18);
             else I=((VDP[0]&0x0E)>>1)|(V&0x18);
             switch(I) {
               case 0x10: J=0;break;
               case 0x00: J=1;break;
               case 0x01: J=2;break;
               case 0x08: J=3;break;
               case 0x02: J=4;break;
               case 0x03: J=5;break;
               case 0x04: J=6;break;
               case 0x05: J=7;break;
               case 0x07: J=8;break;
               case 0x12: J=MAXSCREEN+1;break;
             }
             if(J!=ScrMode) {
               ChrTab=VRAM+((VDP[2]&SCR[J].R2)<<((J>6)? 11:10));
               ChrGen=VRAM+((VDP[4]&SCR[J].R4)<<11);
               ColTab=VRAM+((VDP[3]&SCR[J].R3)<<6)+(VDP[10]<<14);
               SprTab=VRAM+((VDP[5]&SCR[J].R5|((J>3)? 4:0))<<7)+(VDP[11]<<15);
               SprGen=VRAM+(VDP[6]<<11);
               SCR[ScrMode=J].Init();
             }
             break;
    case  2: ChrTab=VRAM+((V&SCR[ScrMode].R2)<<((ScrMode>6)? 11:10));
             break;
    case  3: ColTab=VRAM+((V&SCR[ScrMode].R3)<<6)+(VDP[10]<<14);
             break;
    case  4: ChrGen=VRAM+((V&SCR[ScrMode].R4)<<11);
             break;
    case  5: SprTab=
               VRAM+((V&SCR[ScrMode].R5|((ScrMode>3)? 4:0))<<7)+(VDP[11]<<15);
             break;
    case  6: V&=0x3F;SprGen=VRAM+(V<<11);
             break;
    case  7: FGColor=V>>4;BGColor=V&0x0F;
             Pal[0]=SolidColor0? 0:BGColor;
             if(!VDP[13]) { XBGColor=BGColor;XFGColor=FGColor; }
             SCR[ScrMode].Colors(0xff);
             break;
    case  8: Pal[0]=(V&0x20)? 0:BGColor;
             break;
    case  9: InterLaceMode=(V&0x08)? 1:0;
             break;
    case 10: V&=0x07;
             ColTab=VRAM+((VDP[3]&SCR[ScrMode].R3)<<6)+(V<<14);
             break;
    case 11: V&=0x03;
             SprTab=
               VRAM+((VDP[5]&SCR[ScrMode].R5|((ScrMode>3)? 4:0))<<7)+(V<<15);
             break;
    case 13: if(!V&&(ScrMode==0||ScrMode==MAXSCREEN+1))
               { XBGColor=BGColor;XFGColor=FGColor; }
             break;
    case 14: V&=0x07;break;
    case 15: V&=0x0F;break;
    case 16: V&=0x0F;break;
    case 17: V&=0xBF;break;
    case 33:
    case 37:
    case 41: V&=0x01;break;
    case 35:
    case 39:
    case 43: V&=0x03;break;
    case 44: if(MMCMode==1) {
               *(VRAM+_BY+_BX)=V;
               _BX+=_TX;
               if(!--_N) {
                 if(Verbose&0x08) putchar('.');
                 _N=_NX; _BX=_DX;
                 _DY+=_TY; _BY=_DY<<_Line;
                 if(!--_NY) {
                   if(Verbose&0x08) printf("OK\n");
                   MMCMode=0; VDPStatus[2]&=0x7e;
                   VDP[38]=_DY&0xff; VDP[39]=_DY>>8;
                   VDP[42]=_NY&0xff; VDP[43]=_NY>>8;
                 }
               }
             } else if(MMCMode==2) {
               J=V&_Mask;
               P=VRAM+_BY+_BX/_Diff;
               I=_Shift[_BX%_Diff];
               *P=(*P&~(_Mask<<I))|((Oper(J,*P>>I,_LogOp)&_Mask)<<I);
               _BX+=_TX;
               if(!--_N) {
                 if(Verbose&0x08) putchar('.');
                 _N=_NX; _BX=_DX;
                 _DY+=_TY; _BY=_DY<<_Line;
                 if(!--_NY) {
                   if(Verbose&0x08) printf("OK\n");
                   MMCMode=0; VDPStatus[2]&=0x7e;
                   VDP[38]=_DY&0xff; VDP[39]=_DY>>8;
                   VDP[42]=_NY&0xff; VDP[43]=_NY>>8;
                }
               }
             }
             break;
    case 46: if(MSXVersion&&5<=ScrMode&&ScrMode<=8) DoVDP(V);
             break;
  }
  VDP[R]=V;return;
}



/****************************************************************/
/*** This function is used by DoVDP() for operations on       ***/
/*** pixels.                                                  ***/
/****************************************************************/
inline byte Oper(byte A,byte B,byte N)
{
  switch(N)
  {
    case  0:  B= A; break;        /*  IMP */
    case  1:  B&=A; break;        /*  AND */
    case  4:  B=~A; break;        /*  NOT */
    case  8:  if(A) B =A;  break; /* TIMP */
    case  9:  if(A) B&=A;  break; /* TAND */
    case  2:                      /*  OR  */
    case 10:  B|=A; break;        /* TOR  */
    case  3:                      /*  EOR */
    case 11:  B^=A; break;        /* TEOR */
    case 12:  if(A) B=~A;  break; /* TNOT */
  }
  return(B);
}



/****************************************************************/
/*** Perform given V9938 operation.                           ***/
/****************************************************************/
void DoVDP(byte V)
{
  int SX,SY,DX,DY,NX,NY,TX,TY,AX,AY,BX,BY,N;
  byte *T,*P;
  byte SM,I,J;

  const byte Shift[4][4] = { {4,0,0,0},{6,4,2,0},{4,0,0,0},{0,0,0,0} };
  const byte Diff[4]     = { 2,4,2,1 };
  const byte Mask[4]     = { 0x0F,0x03,0x0F,0xFF };
  const int Width[4]     = { 256,512,512,256 };
  const int Height[4]    = { 1024,1024,512,512 };
  const int XMask[4]     = { 0x1fe,0x1fc,0x1fe,0x1ff };
  const byte Line[4]     = { 7,7,8,8 };
  
  byte ps,ws;
  byte *s,*d;
  int x,lx,ly,ax,bx;

  if((Verbose&0x08)&&MMCMode)
    printf("Warning! made new VDP command while executing last one.\n");

  SM=ScrMode-5;

  SX=(VDP[32]+((dword)VDP[33]<<8))&0x1ff;
  SY=(VDP[34]+((dword)VDP[35]<<8))&0x3ff;
  DX=(VDP[36]+((dword)VDP[37]<<8))&0x1ff;
  DY=(VDP[38]+((dword)VDP[39]<<8))&0x3ff;
  NX=(VDP[40]+((dword)VDP[41]<<8))&0x1ff;
  NY=(VDP[42]+((dword)VDP[43]<<8))&0x3ff;

  switch(V&0xF0)
  {
    /*** Stop ***/
    case 0x00: if(Verbose&0x08) printf("Cmd STOP\n");
               MMCMode=0; VDPStatus[2]&=0x7e; break;

    /*** POINT ***/
    case 0x40: P=VRAM+((dword)SY<<Line[SM])+SX/Diff[SM];
               VDPStatus[7]=(*P>>Shift[SM][SX%Diff[SM]])&Mask[SM];
               if(Verbose&0x08) printf("Cmd POINT: SX:%d SY:%d L:%1X -> C:%d\n"
                 ,SX,SY,V,VDPStatus[7]);
               break;
    /*** PSET ***/
    case 0x50: J=VDP[44]&Mask[SM]; V&=0x0F; if(!J&&(V>7)) break;
               if(Verbose&0x08) printf("Cmd PSET: DX:%d DY:%d C:%d L:%1X\n"
                 ,DX,DY,J,V);
               P=VRAM+((dword)DY<<Line[SM])+DX/Diff[SM];
               I=Shift[SM][DX%Diff[SM]];
               *P=(*P&~(Mask[SM]<<I))|((Oper(J,*P>>I,V)&Mask[SM])<<I);
               break;
    /*** SRCH ***/
    case 0x60: VDP[44]&=Mask[SM]; TX=(VDP[45]&0x04)? -1:1;
               P=VRAM+((dword)SY<<Line[SM]); I=VDP[45]&0x02;
               if(Verbose&0x08)
                 printf("Cmd SRCH: SX:%d SY:%d C:%d TX:%d EQ:%s "
                 ,SX,SY,VDP[44],TX,I? "find not C":"find C");
               VDPStatus[8]=VDPStatus[9]=0; VDPStatus[2]&=0x7e;
               for(;SX>=0&&SX<Width[SM];SX+=TX) {
                 T=P+SX/Diff[SM];
                 J=(*T>>Shift[SM][SX%Diff[SM]])&Mask[SM];
                 if((J==VDP[44]&&!I)||(J!=VDP[44]&&I)) {
                   VDPStatus[8]=SX&0xFF;VDPStatus[9]=(SX>>8)|0xFE;
                   VDPStatus[2]|=0x10;
                   break;
                 }
               }
               if(Verbose&0x08) printf("-> %s at X:%d \n"
                 ,(VDPStatus[2]&0x10)? "Found":"Not found",SX);
               break;
    /*** LINE ***/
    case 0x70: if(Verbose&0x08)
                 printf("Cmd LINE: DX:%d DY:%d NX:%d NY:%d D:%d C:%d L:%1X\n"
                   ,DX,DY,NX,NY,VDP[45],VDP[44]&0x0f,V&0x0f);
               J=VDP[44]&Mask[SM]; V&=0x0F; if(!J&&(V>7)) break;
               TX=VDP[45]&0x04? -1:1;
               TY=VDP[45]&0x08? -1:1;
               if(VDP[45]&0x01) { BX=TX; BY=TX=0; }
               else { BY=TY; BX=TY=0; }
               AX=NX++; N=(AX+1)/2;
               for(;NX--;DX+=TX,DY+=TY) {
                 P=VRAM+((dword)DY<<Line[SM])+DX/Diff[SM];
                 I=Shift[SM][DX%Diff[SM]];
                 *P=(*P&~(Mask[SM]<<I))|((Oper(J,*P>>I,V)&Mask[SM])<<I);
                 N+=NY; if(N>AX) { N-=AX; DY+=BY; DX+=BX; }
               }
               VDP[38]=DY&0xff; VDP[39]=DY>>8;
               break;
    /*** LMMV ***/
    case 0x80: J=VDP[44]&Mask[SM]; V&=0x0f; if(!J&&(V>7)) break;
               if(VDP[45]&0x04) {
			     TX=-1; if(NX>DX+1) NX=DX+1;
			   } else {
			     TX=1; if(NX>Width[SM]-DX) NX=Width[SM]-DX;
			   }
			   if(VDP[45]&0x08) {
				 TY=-1; if(NY>DY+1) NY=DY+1;
		       } else {
				 TY=1; if(NY>Height[SM]-DY) NY=Height[SM]-DY;
			   }
               if(!NX) NX=Width[SM]; if(!NY) NY=Height[SM];
               if(Verbose&0x08)
                 printf("Cmd LMMV: D:%3d,%3d N:%3d,%3d C:%2d L:%1X D:%c %c\n"
                   ,DX,DY,NX,NY,J,V,(TX<0)? '<':'>',(TY<0)? '^':'v');
               for(;NY--;DY+=TY) {
				 BY=DY<<Line[SM]; BX=DX;
				 for(N=NX;N--;BX+=TX) {
                   P=VRAM+BY+BX/Diff[SM];
                   I=Shift[SM][BX%Diff[SM]];
                   *P=(*P&~(Mask[SM]<<I))|((Oper(J,*P>>I,V)&Mask[SM])<<I);
                 }
			   }
               VDP[38]=DY&0xff; VDP[39]=DY>>8;
               VDP[42]=NY&0xff; VDP[43]=NY>>8;
               break;
    /*** LMMM ***/
    case 0x90: V&=0x0f;
               TX=(VDP[45]&0x04)? -1:1;
               TY=(VDP[45]&0x08)? -1:1;
               if(Verbose&0x08)
                 printf(
                   "Cmd LMMM: S:%3d,%3d D:%3d,%3d N:%3d,%3d D:%c %c L:%1X\n"
                     ,SX,SY,DX,DY,NX,NY,(TX<0)? '<':'>',(TY<0)? '^':'v',V);
               ws=Line[SM];
               ps=Diff[SM];
               if(NX==0) NX=Width[SM];
               if(NY==0) NY=Height[SM];
               if(TX>0) {
                 lx=(SX+NX>Width[SM])? Width[SM]-SX:NX;
                 lx=(DX+lx>Width[SM])? Width[SM]-DX:lx;
               } else {
                 lx=(SX-NX<0)? SX+1:NX;
                 lx=(DX-lx<0)? DX+1:lx;
               }
               if(TY>0) {
                 ly=(SY+NY>Height[SM])? Height[SM]-SY:NY;
                 ly=(DY+ly>Height[SM])? Height[SM]-DY:ly;
               } else {
                 ly=(SY-NY<0)? SY+1:NY;
                 ly=(DY-ly<0)? DY+1:ly;
               }
               for(;ly>0;ly--) {
                 for(ax=SX,bx=DX,x=lx;x>0;x--) {
                   s=VRAM+(SY<<ws)+(ax>>(ps/2));
                   d=VRAM+(DY<<ws)+(bx>>(ps/2));
                   J=(*s>>Shift[SM][ax&(ps-1)])&Mask[SM];
                   I=     Shift[SM][bx&(ps-1)];
                   *d=(*d&~(Mask[SM]<<I))|((Oper(J,*d>>I,V)&Mask[SM])<<I);
                   ax+=TX; bx+=TX;
                 }
                 SY+=TY; DY+=TY;
               }
               NY=ly;
               VDP[34]=SY&0xff; VDP[35]=SY>>8;
               VDP[38]=DY&0xff; VDP[39]=DY>>8;
               VDP[42]=NY&0xff; VDP[43]=NY>>8;
               break;
    /*** LMCM ***/
    case 0xA0: VDPStatus[2]|=0x81;
               if(VDP[45]&0x04) {
			     _TX=-1;
			    
			     if(NX>SX+1) NX=SX+1;
			   } else {
			     _TX=1;
				 if(NX>Width[SM]-SX) NX=Width[SM]-SX;
			   }
			   if(VDP[45]&0x08) {
				 _TY=-1;
				 if(NY>SY+1) NY=SY+1;
		       } else {
				 _TY=1;
				 if(NY>Height[SM]-SY) NY=Height[SM]-SY;
			   }
               if(!NX) NX=Width[SM]; if(!NY) NY=Height[SM];
               if(Verbose&0x08)
                 printf("Cmd LMCM: SX:%d SY:%d NX:%d NY:%d ",SX,SY,NX,NY);
               _AX=_SX=SX; _SY=SY; _AY=SY<<Line[SM];
               _N =_NX=NX; _NY=NY;
               MMCMode=3;
               _Diff=Diff[SM]; _Mask=Mask[SM]; _Line=Line[SM];
               memcpy(_Shift,Shift[SM],4);
               break;
    /*** LMMC ***/
    case 0xB0: VDPStatus[2]|=0x81;
               if(VDP[45]&0x04) {
			     _TX=-1;
			     if(NX>DX+1) NX=DX+1;
			   } else {
			     _TX=1;
				 if(NX>Width[SM]-DX) NX=Width[SM]-DX;
			   }
			   if(VDP[45]&0x08) {
				 _TY=-1;
				 if(NY>DY+1) NY=DY+1;
		       } else {
				 _TY=1;
				 if(NY>Height[SM]-DY) NY=Height[SM]-DY;
			   }
               if(!NX) NX=Width[SM]; if(!NY) NY=Height[SM];
               if(Verbose&0x08)
                 printf("Cmd LMMC: DX:%d DY:%d NX:%d NY:%d L:%1X "
                   ,DX,DY,NX,NY,V&0x0f);
               _BX=_DX=DX; _DY=DY; _BY=DY<<Line[SM];
               _N =_NX=NX; _NY=NY;
               MMCMode=2; _Line=Line[SM];
               _Diff=Diff[SM]; _Mask=Mask[SM]; _LogOp=V&0x0f;
               memcpy(_Shift,Shift[SM],4);
               VDPOut(44,VDP[44]);
               break;
    /*** HMMV ***/
    case 0xC0: V=VDP[44];
               TX=(VDP[45]&0x04)? -1:1;
               TY=(VDP[45]&0x08)? -1:1;
               if(Verbose&0x08)
                 printf("Cmd HMMV: D:%3d,%3d N:%3d,%3d C:%2X D:%c %c\n"
                   ,DX,DY,NX,NY,V,(TX<0)? '<':'>',(TY<0)? '^':'v');

               ws=Line[SM];
               ps=Diff[SM];
               lx=NX/ps;
               if(lx==0) lx=(1<<ws);
               if(NY==0) NY=Height[SM];
               if(TX>0) {
                 lx=((DX/ps+NX/ps)>(1<<ws))? (1<<ws)-DX/ps:lx;
               } else {
                 lx=((DX/ps-NX/ps)<0)? DX/ps+1:lx;
               }
               if(TY>0) {
                 ly=(DY+NY>Height[SM])? Height[SM]-DY:NY;
               } else {
                 ly=(DY-NY<0)? DY+1:NY;
               }
               
               d=VRAM;
               d+=(TY>0)? DY<<ws:(DY-ly)<<ws;
               d+=(TX>0)? DX/ps:DX/ps-lx;
               for(;ly>0;ly--) {
                 memset(d,V,lx);
                 d+=(1<<ws);
               }

               DY+=ly; NY=ly;
               VDP[38]=DY&0xff; VDP[39]=DY>>8;
               VDP[42]=NY&0xff; VDP[43]=NY>>8;
               break;
    /*** HMMM ***/
    case 0xD0: TX=(VDP[45]&0x04)? -1:1;
               TY=(VDP[45]&0x08)? -1:1;
               if(Verbose&0x08)
                 printf("Cmd HMMM: S:%3d,%3d D:%3d,%3d N:%3d,%3d D:%c %c\n"
                   ,SX,SY,DX,DY,NX,NY,(TX<0)? '<':'>',(TY<0)? '^':'v');
               ws=Line[SM];
               ps=Diff[SM];
               lx=NX/ps;
               if(lx==0) lx=(1<<ws);
               if(NY==0) NY=Height[SM];
               if(TX>0) {
                 lx=((DX/ps+NX/ps)>(1<<ws))? (1<<ws)-DX/ps:lx;
                 lx=((SX/ps+lx   )>(1<<ws))? (1<<ws)-SX/ps:lx;
               } else {
                 lx=((DX/ps-NX/ps)<0)? DX/ps+1:lx;
                 lx=((SX/ps-lx   )<0)? SX/ps+1:lx;
               }
               if(TY>0) {
                 ly=(DY+NY>Height[SM])? Height[SM]-DY:NY;
                 ly=(SY+ly>Height[SM])? Height[SM]-SY:ly;
               } else {
                 ly=(DY-NY<0)? DY+1:NY;
                 ly=(SY-ly<0)? SY+1:ly;
               }

               for(;ly>0;ly--) {
                 s=VRAM+(SY<<ws)+SX/ps;
                 d=VRAM+(DY<<ws)+DX/ps;
                 for(x=lx;x>0;x--) {
                   *d=*s;
                   d+=TX; s+=TX;
                 }
                 SY+=TY; DY+=TY;
               }
               NY=ly;
               VDP[34]=SY&0xff; VDP[35]=SY>>8;
               VDP[38]=DY&0xff; VDP[39]=DY>>8;
               VDP[42]=NY&0xff; VDP[43]=NY>>8;
               break;
    /*** YMMM ***/
    case 0xE0: if(VDP[45]&0x04) {
			     TX=-1; NX=DX+1;
			   } else {
			     TX=1; NX=Width[SM]-DX;
			   }
			   if(VDP[45]&0x08) {
				 TY=-1;
				 if(NY>SY+1) NY=SY+1;
				 if(NY>DY+1) NY=DY+1;
		       } else {
				 TY=1;
				 if(NY>Height[SM]-DY) NY=Height[SM]-DY;
				 if(NY>Height[SM]-SY) NY=Height[SM]-SY;
			   }
               if(Verbose&0x08)
                 printf("Cmd YMMM: S:---,%3d D:%3d,%3d N:---,%3d D:%c %c\n"
                   ,SY,DX,DY,NY,(TX<0)? '<':'>',(TY<0)? '^':'v');
               DX/=Diff[SM]; NX/=Diff[SM];
               for(;NY--;DY+=TY,SY+=TY) {
				 AY=SY<<Line[SM]; BY=DY<<Line[SM];
				 BX=DX;
                 for(N=NX;N--;BX+=TX)
                   *(VRAM+BY+BX)=*(VRAM+AY+BX);
               }
               VDP[34]=SY&0xff; VDP[35]=SY>>8;
               VDP[38]=DY&0xff; VDP[39]=DY>>8;
               VDP[42]=NY&0xff; VDP[43]=NY>>8;
               break;
    /*** HMMC ***/
    case 0xF0: VDPStatus[2]|=0x81;
               if(VDP[45]&0x04) {
			     _TX=-1; if(NX>DX+1) NX=DX+1;
			   } else {
			     _TX=1; if(NX>Width[SM]-DX) NX=Width[SM]-DX;
			   }
			   if(VDP[45]&0x08) {
				 _TY=-1; if(NY>DY+1) NY=DY+1;
		       } else {
				 _TY=1; if(NY>Height[SM]-DY) NY=Height[SM]-DY;
			   }
               if(!NX) NX=Width[SM]; if(!NY) NY=Height[SM];
               DX/=Diff[SM]; NX/=Diff[SM];
               if(Verbose&0x08)
                 printf("Cmd HMMC: D:%3d,%3d N:%3d,%3d D:%c %c"
                   ,DX,DY,NX,NY,(_TX<0)? '<':'>',(_TY<0)? '^':'v');
               _BX=_DX=DX; _DY=DY; _BY=DY<<Line[SM];
               _N =_NX=NX; _NY=NY;
               MMCMode=1; _Line=Line[SM];
               VDPOut(44,VDP[44]);
               break;
    default: printf("Unimplemented V9938 operation %X\n",V);
  }
}
