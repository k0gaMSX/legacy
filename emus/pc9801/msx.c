/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                           MSX.c                         **/
/**                                                         **/
/** This file contains implementation for the MSX-specific  **/
/** hardware: slots, memory mapper, PPIs, clock, etc.       **/
/** Initialization code and definitions needed for the      **/
/** machine-dependent drivers are also here.                **/
/** implementation for VDP is  included in VDP.c file.      **/
/**                                                         **/
/** Copyright (C) Marat Fayzullin 1994,1995                 **/
/** Copyright (C) MURAKAMI Reki 1995,1996                   **/
/**     You are not allowed to distribute this software     **/
/**     commercially. Please, notify me, if you make any    **/
/**     changes to this file.                               **/
/*************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <fcntl.h>
#include <pc.h>
#include "MSX.h"

#define PATCH(addr) {*(addr)=0xed;*(addr+1)=0xfd;*(addr+2)=0xc9;}

/******** MSX system cotrol ********/
byte ResetStatus = 0x80;            /* MSX2+ Reset Status     */
byte EnableSysSelect = 0;           /* TurboR system select   */

byte IOReg;                         /* Storage for AAh port   */
byte PPIReg;                        /* PPI control            */

byte SaveCMOS    = 0;               /* Save CMOS.ROM on exit  */
byte RTCReg=0,RTCMode=0;            /* RTC numbers            */
byte RTC[4][13];                    /* RTC registers          */

/******* Slot and memory *******/
byte PSL[4],SSL[4];
byte PSLReg,SSLReg[4];   /* Storage for A8h port and (FFFFh)  */

byte *MemMap[4][4][8];   /* Memory maps [PPage][SPage][Addr]  */

byte RAMPages    = 4;               /* Number of RAM pages    */
byte VRAMPages   = 8;               /* Number of VRAM pages   */

byte *RAMMap[256];                  /* Blocks for RAM mapper  */
byte RAMMapper[4];                  /* RAM Mapper state       */
byte *ROMMap[4][4][256];            /* Blocks for ROM mappers */
byte ROMType[4][4] = {              /* MEGA ROM type          */
  {255,255,255,255},{255,255,255,255},
  {255,255,255,255},{255,255,255,255}
};
byte EnWrite[4]  = { 0,0,0,0 };     /* 1 if write enabled     */
byte *NoRAMSlot  = NULL;            /* Dummy slot             */

char *CartA      = "CARTA.ROM";     /* Cartridge A ROM file   */
char *CartB      = "CARTB.ROM";     /* Cartridge B ROM file   */

/******* Disk *******/
char *DiskA      = "DRIVEA.DSK";    /* Drive A disk image     */
char *DiskB      = "DRIVEB.DSK";    /* Drive B disk image     */
int  Drives[2]   = { -1,-1 };       /* Disk image files       */
int  Disks[40];                     /* Other disk image files */
char DiskNo[0]   = { -1,-1 };       /* Disk image file No.    */

/******** Other devices ********/
byte KeyMap[16]  =                  /* Keyboard map           */
{
  0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
  0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
};

char *TapeFile   = "TAPE.TAP";      /* Tape image             */
FILE *Tape       = NULL;            /* Tape image file        */

char *PrnName    = NULL;            /* Printer redirect. file */
FILE *PrnStream  = NULL;

/******** Sound ********/
byte PSGReg      = 0;               /* PSG number             */
byte OPLLReg     = 0;               /* OPLL number            */
byte PSG[16]     = { 0 };           /* PSG registers          */
byte OPLL[56]    = { 0 };           /* OPLL registers         */
byte SCC[16]     = { 0 };           /* SCC registers          */

/******* Kanji ********/
byte *KanjiFont  = NULL;            /* Kanji ROM table addr.  */
word KanjiCode   = 0;               /* Number of Kanji code   */
byte KanjiLine   = 0;               /* Line number of font    */



char pathBuf[BUFSIZ];

char *MakePath(char *dir,char *fileName)
{
  char p;

  if( dir && !strchr(fileName,'\\') && !strchr(fileName,'/') ) {
    strcpy(pathBuf,dir);
    p=pathBuf[strlen(pathBuf)-1];
    if( p!='\\' || p!='/' ) strcat(pathBuf,"/");
    strcat(pathBuf,fileName);
    return pathBuf;
  } else
    return fileName;
}



/****************************************************************/
/*** Write number into given IO port.                         ***/
/****************************************************************/
void DoOut(byte Port,byte Value)
{
  static byte xPal,Addr;     /* Palette and address buffers */
  byte I,J,K,L,*P;

  switch(Port)
  {

case 0x7C: OPLLReg=Value;return;
case 0x7D: OPLLOut(OPLLReg,Value);return;

case 0x8C:
case 0x8D: break; /* MODEM */

case 0x91: Printer(Value);break;

case 0x88:
case 0x98: VAddr++;
           VAddr&=VAddrMask;
           *(VRAM+VAddr)=Value;
           return;
case 0x89:
case 0x99: if(!VKey) {
             VKey=1;
             if(Value&0x80) {
               VDPOut(Value&0x3f,Addr); return;
             } else {
               VAddr=Addr|(Value&0x3F)<<8|VDP[14]<<14;
               if(Value&0x40) { VAddr--; VAddr&=VAddrMask; }
               return;
             }
           }
           Addr=Value; VKey=0;
           return;
case 0x8a:
case 0x9A: if(PKey) { xPal=Value;PKey--; }
           else
           {
             PKey++;J=VDP[16];
             VDP[16]=(VDP[16]+1)&0x0F;
             Palette[J][0]=(xPal&0x70)<<1;
             Palette[J][1]=(Value&0x07)<<5;
             Palette[J][2]=(xPal&0x07)<<5;
             SCR[ScrMode].Colors(J);
           }
           return;
case 0x8B:
case 0x9B: J=VDP[17]&0x3F;
           if(J!=17) VDPOut(J,Value);
           if(!(VDP[17]&0x80)) VDP[17]=(J+1)&0x3F;
           return;

case 0xA0: PSGReg=Value&0x0F;return;
case 0xA1: PSGOut(PSGReg,Value);return;

case 0xA4: /* PCM? */
case 0xA5: break;
case 0xA6: /* Timer */ break;
case 0xA7: /* LED indicator */ break;

case 0xA8: if(Value!=PSLReg)
           {
             PSLReg=Value;
             for(I=0;I<8;I+=2) {
               J=(Value>>I)&0x03;
               if(J!=PSL[I>>1]) {
                 PSL[I>>1]=J; L=SSL[I>>1]=(SSLReg[J]>>I)&0x03;
                 RAM[I]  =(P=MemMap[J][L][I])? P:NoRAMSlot;
                 RAM[I+1]=(P=MemMap[J][L][I+1])? P:NoRAMSlot;
                 EnWrite[I>>1]=(J==3&&L==0)? 1:0;
               }
             }
             *(RAM[7]+0x1fff)=~SSLReg[PSL[3]];
           }
           break;
case 0xAA: IOReg=Value;return;
case 0xAB: if(Value&0x80) PPIReg=Value;
           else
             if(Value&0x01) IOReg|=1<<(7&(Value>>1));
             else           IOReg&=~(1<<(7&(Value>>1)));
           break;

case 0xB0:
case 0xB1:
case 0xB2:
case 0xB3: break; /* extend memory */

case 0xB4: RTCReg=Value&0x0F;break;
case 0xB5: if(RTCReg<13)
           {
             J=RTCMode&0x03;RTC[J][RTCReg]=Value;
             if(J>1) SaveCMOS=1;
           }
           else if(RTCReg==13) RTCMode=Value;
           break;

case 0xB8:
case 0xBA:
case 0xBB: break; /* light pen */

case 0xBC:
case 0xBD:
case 0xBE:
case 0xBF: break; /* VHD control */

case 0xC0:
case 0xC1: break; /* MSX-Audio */

case 0xD8:
case 0xDA: KanjiCode=(Value&0x3f)|(KanjiCode&0x0fc0);
           KanjiLine=0;
           break;
case 0xD9:
case 0xDB: KanjiCode=((Value&0x3f)<<6)|(KanjiCode&0x003f);
           KanjiLine=0;
           break;

case 0xE4: if(Value==0x06) EnableSysSelect=1;
           break;
case 0xE5: /* system select */
           break;

case 0xF4: ResetStatus=Value;
           break;

case 0xF5: break; /* device enable */
case 0xF6: break; /* color bus I/O */
case 0xF7: break; /* AV control */

case 0xFC:
case 0xFD:
case 0xFE:
case 0xFF: I=(Port-0xFC)<<1; P=RAMMap[Value];
           MemMap[3][0][I  ]=P? P       :NoRAMSlot;
           MemMap[3][0][I+1]=P? P+0x2000:NoRAMSlot;
           RAMMapper[I>>1]=Value;
           if(PSL[I>>1]==3&&SSL[I>>1]==0)
           {
             EnWrite[I>>1]=P? 1:0;
             RAM[I  ]=MemMap[3][0][I  ];
             RAM[I+1]=MemMap[3][0][I+1];
           }
           return;
  }
}



/****************************************************************/
/*** Read number from given IO port.                          ***/
/****************************************************************/
byte DoIn(byte Port)
{
  switch(Port)
  {

case 0x90: return(0xFD);                     /* Printer READY signal */
case 0x98: Port=*(VRAM+VAddr++);               /* VRAM read port       */
           VAddr&=VAddrMask;
           return(Port);
case 0x99: Port=VDPStatus[VDP[15]];          /* VDP status registers */
           switch(VDP[15])
           {
             case 0: VDPStatus[0]&=0x5f; break;
             case 1: VDPStatus[1]&=0xfe; break;
             case 2: VDPStatus[2]^=0x20; break;
             case 7: if(MMCMode==3) {
                       Port=VDPStatus[7]=(*(VRAM+_AY+_AX/_Diff)
                         >>_Shift[_AX%_Diff])&_Mask;
                       _AX+=_TX;
                       if(!--_N) {
                         if(Verbose&0x08) putchar('.');
                         _N=_NX; _AX=_SX;
                         _SY+=_TY; _AY=_SY<<_Line;
                         if(!--_NY) {
                           if(Verbose&0x08) printf("OK\n");
                           MMCMode=0; VDPStatus[2]&=0x7e;
                           VDP[32]=_SY&0xff; VDP[33]=_SY>>8;
                           VDP[42]=_NY&0xff; VDP[43]=_NY>>8;
                        }
                       }
                     }
           }
           return(Port);
case 0xA2: return(PSGIn(PSGReg));            /* PSG registers        */
case 0xA8: return(PSLReg);                   /* Primary slot state   */
case 0xA9: return(KeyMap[IOReg&0x0F]);       /* Keyboard port        */
case 0xAA: return(IOReg);                    /* General IO  */
case 0xAB: return(PPIReg);                   /* PPI control */
case 0xB5: return(RTCIn(RTCReg));            /* RTC registers        */

case 0xD9: return(UseKanjiROM? *(KanjiFont+        ((dword)KanjiCode<<5)
             +KanjiLine++):NORAM);
case 0xDB: return(UseKanjiROM? *(KanjiFont+0x20000+((dword)KanjiCode<<5)
             +KanjiLine++):NORAM);

case 0xF4: return(ResetStatus);
case 0xFC:                                   /* Mapper page at 0000h */
case 0xFD:                                   /* Mapper page at 4000h */
case 0xFE:                                   /* Mapper page at 8000h */
case 0xFF: return(RAMMapper[Port-0xFC]|0xF0);/* Mapper page at C000h */
default:   return(NORAM);                    /* If no port, ret FFh  */

  }
}



/****************************************************************/
/*** Switch ROM Mapper pages. This function is supposed to be ***/
/*** to be called when ROM page registers are written to.     ***/
/****************************************************************/
void MapROM(word Addr,byte Value)
{
  byte        *P, I, J, K;
  static byte SCCMode = 0,
              extSCCMode = 0;
  byte        BankIs8K = 0;

  K = Addr >> 14; I = PSL[K]; J = SSL[K];

  switch (ROMType[I][J]) {
    case  3:                                         /* KONAMI */
      K = (Addr >> 13) - 2; if (K > 3) return;
      BankIs8K = 1; break;

    case  1:                                         /* MSX-DOS2 ROM */
      if (Addr < 0x6000 || Addr > 0x7fff) return;
      K = 0; BankIs8K = 0;
      break;

    case  6:                                         /* 'Shin-10-bai' */
      if (0xb000 <= Addr && Addr < 0xc000) {
        if (MemMap[I][J][5] == ROMMap[I][J][0x10] ||
            MemMap[I][J][5] == ROMMap[I][J][0x11]) {
          *(MemMap[I][J][5] + (Addr & 0x0fff)) =
          *(MemMap[I][J][5] + (Addr & 0x0fff) + 0x1000) = Value;
        }
        return;
      }
      if (Value & 0x10)
        Value = (Value & 0x20) ? 0x11 : 0x10;
      else
        Value &= 0x0f;

      K = (Addr >> 13) - 2;
      switch (Addr >> 12) {
        case 0x6: break;
        case 0x8: break;
        case 0xa: break;
        default: return;
      }
      BankIs8K = 1;
      break;

    case  0:                                     /* KONAMI  8k (SCC) */
    case  2:                                     /* KONAMI5 8k (SCC) */
      K = (Addr >> 13) - 2;
      switch ((Addr >> 8) & 0xf8) {
        case 0x50: break;
        case 0x70: break;
        case 0x90:
          SCCMode = (UseSCC && (Value & 0x3f) == 0x3f) ? 1 : 0;
          break;
        case 0x98:
          if (SCCMode) {
             SCCOut(Addr-0x9880, Value);
             return;
          }
        case 0xb0: break;
        default: return;
      }
      BankIs8K = 1;
      break;

    case 4:                                           /* ASCII 8K */
      K = (Addr >> 11) - 12; if ( K > 3) return;
      BankIs8K = 1; break;
    case 5:                                           /* ASCII 16K */
      switch (Addr >> 12) {
        case 0x06: K = 0; break;
        case 0x07: K = 2; break;
        default: return;
      }
      BankIs8K = 0; break;
    case 95:                                          /* 'R-TYPE' */
      if (Addr >> 12 != 0x7) return;
      BankIs8K = 0; K = 2; break;
    case 93:                                          /* Panasonic */
      return;
    case 255: return;                                 /* normal ROM */
    default:
      if (Verbose) printf("Unknown MegaROM\n");
      return;
  }
  if (Verbose & 0x02)
    printf("Slot:%d-%d Type:%d Addr:%04x Bank:%02x\n",
      I, J, ROMType[I][J], Addr, Value);

  if (!BankIs8K) {
    Value <<= 1;
    MemMap[I][J][K + 3] = RAM[K + 3] =
      (P = ROMMap[I][J][Value + 1]) ? P : NoRAMSlot;
  }
  MemMap[I][J][K + 2] = RAM[K + 2] =
    (P = ROMMap[I][J][Value    ]) ? P : NoRAMSlot;
}

/****************************************************************/
/*** Switch secondary memory slots. This function is supposed ***/
/*** to be called when value in (FFFFh) changes.              ***/
/****************************************************************/
void SSlot(byte Value)
{
  byte I,J,K,L,*P;

  J=PSL[3];
  if(J==1||J==2||SSLReg[J]==Value) return;

  SSLReg[J]=Value;
  for(I=0;I<8;I+=2) {
    L=(Value>>I)&0x03; J=PSL[I>>1];
    if(L!=SSL[I>>1]&&J==PSL[3]) {
      SSL[I>>1]=L;
      RAM[I]  =(P=MemMap[J][L][I])? P:NoRAMSlot;
      RAM[I+1]=(P=MemMap[J][L][I+1])? P:NoRAMSlot;
      EnWrite[I>>1]=(J==3&&L==0)? 1:0;
    }
  }
  *(RAM[7]+0x1fff)=~SSLReg[PSL[3]];
}



/****************************************************************/
/*** Allocate memory, load ROM images, initialize mapper, VDP ***/
/*** CPU and start the emulation. This function returns 0 in  ***/
/*** the case of failure.                                     ***/
/****************************************************************/
int StartMSX(void)
{
  char buf[BUFSIZ];
  word A;
  FILE *F;
  int *T,I,J,K,L;
  reg R;
  byte *P;

  /*** MSX versions:                ***/
  static char *Versions[] = { "MSX","MSX2","MSX2+" };
  /*** CMOS ROM default values:     ***/
  static byte RTCInit[4][13]  =
  {
    { 0,0,0,0,0,0,0,0,0,0,0,0,0 },
    { 0,0,0,0,0,0,0,0,0,0,0,0,0 },
    { 0,0,0,0,40,80,15,4,4,0,0,0,0 },
    { 0,0,0,0,0,0,0,0,0,0,0,0,0 }
  };

  /*** STARTUP CODE starts here: ***/

  for(I=0;I<256;I++) RAMMap[I]=NULL;
  for(I=0;I<4;I++)
    for(J=0;J<4;J++) {
      for(K=0;K<256;K++)
        ROMMap[I][J][K]=NULL;
      for(K=0;K<8;K++)
        MemMap[I][J][K]=NULL;
    }

  if(MSXVersion>2) MSXVersion=2;
  if(UseDOS2&&RAMPages==4) RAMPages=8;
  L=(!RAMPages)? 256:(RAMPages>127)? 128:(RAMPages>63)? 64:(RAMPages>32)? 32:
    (RAMPages>15)? 16:(RAMPages>7)? 8:4;
  VRAMPages=MSXVersion? 8:2;
  VAddrMask=MSXVersion? 0x1ffff:0x3fff;

  if(Verbose) printf("Allocating 8kB for dummy address space...");
  if((NoRAMSlot=malloc(PAGESIZE/2))==NULL) return 0;
  memset(NoRAMSlot,NORAM,PAGESIZE/2);
  if(Verbose) printf("OK\nAllocating %dkB for VRAM...",VRAMPages*16);
  if((VRAM=malloc(VRAMPages*PAGESIZE))==NULL) return 0;
  if(Verbose) printf("OK\nAllocating %dx16kB RAM pages...",RAMPages);
  memset(VRAM,0xff,VRAMPages*PAGESIZE);
  for(J=0;J<L;J++) if((RAMMap[J]=malloc(PAGESIZE))==NULL) return 0;
  for(L--,J=0;J<256;J++) RAMMap[J]=RAMMap[J&L];

  if(Verbose) printf("OK\nAllocating graphic buffer...");
  if((ScreenBuf=(byte *)malloc(WIDTH*HEIGHT*2*2))==NULL) return 0;

  if(Verbose) printf("OK\nLoading %s ROMs:\n",Versions[MSXVersion]);

  switch(MSXVersion)
  {
    case 2:
      VDPStatus[1]=0x04;
      if( LoadROM(MakePath(sysPath,"MSX2P.ROM"),0,0,0)
        && LoadROM(MakePath(sysPath,"MSX2PEXT.ROM"),3,1,0) ) break;
      if(Verbose) printf("  Using MSX2 system ROM files.\n");
    case 1:
      VDPStatus[1]=0x02;
      if( LoadROM(MakePath(sysPath,"MSX2.ROM"),0,0,0)
        && LoadROM(MakePath(sysPath,"MSX2EXT.ROM"),3,1,0) ) break;
      if(Verbose) printf("  Using MSX system ROM files.\n");
    case 0:
      VDPStatus[1]=0x00;
      if(LoadROM(MakePath(sysPath,"MSX.ROM"),0,0,0)) break;
      if(Verbose) printf("  Not found any system ROM files.\n");
      return 0;
  }

  /*** Panasonic kanji patch ***/
  P=MemMap[0][0][0];
  if(*(P+0x146c)==0x2f) {
    *(P+0x146c)=0xc9;
    if(Verbose) printf("  Found Panasonic FS-A1WX/WSX's MainROM.\n");
  }

  if(UseDisk&&(LoadROM(MakePath(sysPath,"DISK.ROM"),3,2,1)!=NULL)) {
    if(Verbose) printf("  Patched DiskROM.\n");
    P=MemMap[3][2][2];
    PATCH(P+0x0010); PATCH(P+0x0013); PATCH(P+0x001c);

    /*** Panasonic disk patch ***/
    P=MemMap[3][2][3];
    if(!memcmp(P+0x1e2c,"MSX_03",6)) {
      *(P+0x1992)=0xc9;
      if(Verbose) printf("  Found Panasonic FS-A1WX/WSX's DiskROM.\n");
    }

    /* load DOS2 ROM */
    if (UseDOS2) {
      ROMType[0][1] = 1;
      if (LoadROM(MakePath(sysPath, "MSXDOS2.ROM"), 0, 1, 1) == NULL) {
        UseDOS2 = 0; ROMType[0][1] = 255;
      }
    }

    for(I=K=0,L=0;L<2;L++) {
      P=(L==0)? DiskA:DiskB;
      while(*P) {
        J=0; while(*P!=';'&&*P!='\0') buf[J++]=*P++; buf[J]='\0';
        if(*P==';') P++;
        if(strchr(buf,'.')==NULL) strcat(buf,".dsk");
        strcpy(buf,MakePath(diskPath,buf));
        if((Disks[I]=open(buf,O_RDWR|O_BINARY))>=0) {
          if(I==K) DiskNo[L]=I;
          if(Verbose)
            printf("Using `%s' as drive %c disk #%d.\n",buf,'A'+L,I);
          I++;
        } else if(Verbose)
          printf("Can't find `%s', assigned real drive.\n",buf);
      }
      K=I;
    }
    Disks[I]=-1;
    for(J=0;J<2;J++) {
      if(DiskNo[J]==-1) DiskNo[J]=I;
      Drives[J]=Disks[DiskNo[J]];
    }
  }

  if(UseTape) {
    if(!(Tape=fopen(MakePath(tapePath,TapeFile),"rb+"))) {
      if(Verbose) printf("Can't find '%s'. Using new file.\n",TapeFile);
      Tape=fopen(MakePath(tapePath,TapeFile),"wb+");
    } else if(Verbose)
        printf("Using %s as tape device.\n  Patched Tape BIOS.\n"
          ,TapeFile);
    P=MemMap[0][0][0];
    PATCH(P+0xe1); PATCH(P+0xe4); PATCH(P+0xea); PATCH(P+0xed);
  }

  if(UseKanjiROM&&(F=fopen(MakePath(sysPath,"KANJI.ROM"),"rb"))) {
    if(Verbose) printf("Found KANJI.ROM: allocating memory...");
    if(KanjiFont) free(KanjiFont);
    if(KanjiFont=malloc(0x40000)) {
      if(Verbose) printf("loading...");
      if(fread(KanjiFont,1,0x40000,F)!=0x40000) {
        PRINTFAILED; free(KanjiFont); KanjiFont=0;
      } else PRINTOK;
      fclose(F);
    } else PRINTFAILED;
    LoadROM(MakePath(sysPath,"KNJDRV.ROM"),3,1,1);
  } else UseKanjiROM=0;

  if(UseFM)
    LoadROM(MakePath(sysPath,"FMBIOS.ROM"),3,3,1);
  if(UseRS232)
    LoadROM(MakePath(sysPath,"RS232.ROM"),0,2,1);

  LoadROM(MakePath(romPath,CartA),1,0,255);
  LoadROM(MakePath(romPath,CartB),2,0,255);

  if(!PrnName) PrnStream=stdout;
  else
  {
    if(Verbose) printf("Redirecting printer output to %s...",PrnName);
    if(!(PrnStream=fopen(PrnName,"wb")))
    { PrnStream=stdout; PRINTFAILED; }
    else PRINTOK;
  }

  if(F=fopen(MakePath(sysPath,"CMOS.ROM"),"rb"))
  {
    if(Verbose) printf("Found CMOS.ROM: loading...");
    if(fread(RTC,1,sizeof(RTC),F)!=sizeof(RTC))
    { PRINTFAILED;fclose(F);F=0; }
  }

  if(F) { fclose(F);PRINTOK; }
  else memcpy(RTC,RTCInit,sizeof(RTC));

  PSLReg=0;
  for(J=0;J<4;J++) {
    PSL[J]=0; SSLReg[J]=0; SSL[J]=0;
    RAMMapper[J]=3-J;
    MemMap[3][0][J<<1]    =RAMMap[RAMMapper[J]];
    MemMap[3][0][(J<<1)+1]=RAMMap[RAMMapper[J]]+0x2000;
  }
  for(J=0;J<8;J++)
    RAM[J]=MemMap[0][0][J];

  if(Verbose) printf("Initializing VDP,PSG,SCC,OPLL and CPU...");

  for(J=0;J<16;J++)
    PSG[J]=SCC[J]=0;
  for(J=0;J<56;J++)
    OPLL[J]=0;
  Cnt=IPeriod; VKey=PKey=1;
  ChrTab=ColTab=SprTab=SprGen=ChrGen=VRAM;
  FGColor=BGColor=ScrMode=0;
  R.PC.W=0x0000; R.SP.W=0xf000; R.IFF=0;

  if(Verbose) printf("OK\nRUNNING ROM CODE...\n");
  A=Z80(R);

  if(Verbose) printf("EXITED at PC = %Xh.\n",A);
  return(1);
}



/****************************************************************/
/*** Free memory allocated with StartMSX().                   ***/
/****************************************************************/
void TrashMSX(void)
{
  int I,J,K;
  FILE *F;

  if(NoRAMSlot) free(NoRAMSlot);
  if(VRAM) free(VRAM);
  if(ScreenBuf) free(ScreenBuf);

  for(I=0;I<256;I++)
    if(RAMMap[I]) free(RAMMap[I]);
  for(I=0;I<4;I++)
    for(J=0;J<4;J++) {
      for(K=0;K<256;K++)
        if(ROMMap[I][J][K]) free(ROMMap[I][J][K]);
      for(K=0;K<8;K++)
        if(MemMap[I][J][K]) free(MemMap[I][J][K]);
    }

  for(I=0;I<40;I++) if(Disks[I]!=-1) close(Disks[I]);

  if(Tape!=NULL) {
    fseek(Tape,0,SEEK_END); fclose(Tape);
  }

  if(SaveCMOS)
  {
    if(Verbose) printf("Writing CMOS.ROM: ");
    if(F=fopen(MakePath(sysPath,"CMOS.ROM"),"wb"))
      if(fwrite(RTC,1,sizeof(RTC),F)!=sizeof(RTC))
      { fclose(F);F=0; }
    if(F) { fclose(F);PRINTOK; }
    else PRINTFAILED;
  }

  if(PrnStream&&(PrnStream!=stdout)) fclose(PrnStream);
  if(Drives[0]>=0) close(Drives[0]);
  if(Drives[1]>=0) close(Drives[1]);
}



/****************************************************************/
/*** Load a ROM page from the file F into slot P, subslot S,  ***/
/*** page A. Return memory address of a page or 0 if failed.  ***/
/****************************************************************/
byte *LoadROM(char *fileName,int P,int S,int A)
{
  FILE *F;             /* file desc. of ROM imege file */
  byte sHead[4];       /* temporary of ROM header */
  int  I,J,C;
  byte orgRomType[] = {
    0, 4, 5, 93, 3, 95, 6, 97, 1
  };                   /* RomType conversion from fMSX98 to fMSX */

  if ((F = fopen(fileName, "rb")) == NULL) {
    if (Verbose && A != 255) printf(" Can't find '%s'.\n", fileName);
    return NULL;
  }

  /* check ROMType */
  if (A == 255) {                      /* if page isn't specified */
    fread(sHead, 4, 1, F);
    rewind(F);
    switch (ROMType[P][S]) {
      case 95: /* breakthrough */
      case 97: A = 1; break;           /* top of ROM image isn't 'AB' */
      case 255:                        /* no -rom option is specified */
        if ('A' <= sHead[0] && sHead[0] <= 'A' + 8) {
          ROMType[P][S] = orgRomType[sHead[0] - 'A'];
          sHead[0] = 'A';              /* RomType check */
        } else sHead[0] = ' '; /* breakthrough */
      default:
        if (sHead[0] != 'A' || sHead[1] != 'B') {
          fclose(F);
          if(Verbose) printf("Bad header of %s.\n",fileName);
          return NULL;
        }
        A = (sHead[3] >> 6) & 3;
    }
  }

  if(Verbose)
    printf("Slot %d-%d Page %d: %s  loading...",P,S,A,fileName);

  /* read ROM image file */
  for (I = 0; I < 256; I++) {
    if ((C = fgetc(F)) == EOF) break;
    ungetc(C, F);
    if (ROMMap[P][S][I] = malloc(PAGESIZE / 2))
      fread(ROMMap[P][S][I], 1, PAGESIZE/2, F);
    else PRINTFAILED;
  }
  fclose(F);
  if (Verbose) printf("%d blocks loaded.\n", I);

  /* if MegaROM */
  if (I > 4) {
    I = 4;
    *ROMMap[P][S][0] = 'A';            /* patch old type of ROMType */

    if (Verbose) printf("  Mapper type is ");
    switch (ROMType[P][S]) {
      case  0: if (Verbose) printf("KONAMI 8k(SCC)"); break;
      case  2: if (Verbose) printf("KONAMI5 8k(SCC)"); break;
      case  4: if (Verbose) printf("ASCII 8k"); break;
      case  5: if (Verbose) printf("ASCII 16k"); break;
      case 93: if (Verbose) printf("Panasonic(unsupported)"); break;
      case  3: if (Verbose) printf("KONAMI 8k"); break;
      case 95:
        if (Verbose) printf("'R-TYPE'(unsupported)");
        MemMap[P][S][2] = ROMMap[P][S][30];
        MemMap[P][S][3] = ROMMap[P][S][31];
        break;
      case  6:
        if (Verbose) printf("'Shin-10-bai'");
        if (I == 0x10) {
          ROMMap[P][S][0x10] = (byte *)malloc(PAGESIZE);
          ROMMap[P][S][0x11] = ROMMap[P][S][0x10] + (PAGESIZE / 2);
        }
        break;
      case  1: if (Verbose) printf("'MSX-DOS2'"); break;
      default: printf("Unknown[%xh]", ROMType[P][S]);
    }
    if (Verbose) printf(" mapper.\n");

  } else ROMType[P][S] = 255;       /* normal 32k ROM */

  for (J = 0; J < I; J++) {
    MemMap[P][S][(A << 1) + J] = ROMMap[P][S][J];
  }

  return MemMap[P][S][A << 1];
}


/****************************************************************/
/*** Send a character to the printer.                         ***/
/****************************************************************/
void Printer(byte V) { fputc(V,PrnStream); }


/****************************************************************/
/*** Read number from given RTC register.                     ***/
/****************************************************************/
byte RTCIn(byte R)
{
  byte J;
  time_t T;
  char *S;

  /*** ctime() returns "DDD MMM dd hh:mm:ss YYYYn0" ***/
  static byte RTable[13] =
  { 18,17,15,14,12,11,25,9,8,25,25,23,22 };
  static char *Days[7] =
  { "Sun","Mon","Tue","Wed","Thu","Fri","Sat" };
  static char *Months[12] =
  {
    "Jan","Feb","Mar","Apr","May","Jun",
    "Jul","Aug","Sep","Oct","Nov","Dec"
  };

  J=RTCMode&0x03;
  if(R>12) J=(R==13)? RTCMode:NORAM;
  else
    if(J) J=RTC[J][R];
    else
    {
      time(&T);S=ctime(&T);
      switch(R)
      {
        case 6:  for(J=0;(J<7)&&strncmp(S,Days[J],3);J++);
                 J=(J==7)? 0:J+1;break;
        case 9:  for(J=0;(J<12)&&strncmp(S+4,Months[J],3);J++);
                 J=(J==12)? 0:(J+1)%10;break;
        case 10: for(J=0;(J<12)&&strncmp(S+4,Months[J],3);J++);
                 J=(J==12)? 0:(J+1)/10;break;
        case 11: S[24]='\0';J=(atoi(S+20)-1980)%10;break;
        case 12: S[24]='\0';J=((atoi(S+20)-1980)/10)%10;break;
        default: J=S[RTable[R]]-'0';
      }
    }
  return(J|0xF0);
}



/****************************************************************/
/*** Set sound parameters, refresh screen, check keyboard and ***/
/*** sprites. Call this function on each interrupt.           ***/
/****************************************************************/
word Interrupt(void)
{
  static char flgBlink = 0;
  static byte cntBlink = 0,
              cntRefresh = 1,
              topLine = 0,
              bottomLine,
              scanLine,
              enableRefresh = 0;

  if (VDPStatus[2] & 0x40) {                /* if Vsync period */
    VDPStatus[2] &= 0xbf;                   /* Vsync period ended */
    Cnt = IPeriod / 2;
    return 0;
  }

  if (Verbose & 0x04)
    printf("[%05X] (%03d-) R#19:%02X R#23:%02X (%s)\n"
      ,ChrTab-VRAM,topLine,VDP[19],VDP[23],(enableRefresh)? "refresh":"pass");

  scanLine = VDP[19] - VDP[23];            /* current scanline */
  bottomLine = ScanLines212 ? 211 : 191;

  if ((VDP[0] & 0x10) &&                   /* enable scanline intr. */
      (topLine <= scanLine) && (scanLine < bottomLine)) {
                                           /* scanline intr. occur */
    bottomLine = (scanLine + 2 < bottomLine) ? scanLine + 2 : bottomLine;
    if (enableRefresh)
      SCR[ScrMode].Refresh(topLine, bottomLine);
    VDPStatus[0] &= 0x7f;                  /* isn't Vsync intr. */
    VDPStatus[1] |= 0x01;                  /* this is scanline intr. */
    topLine = scanLine + 2;
    Cnt = 300;                             /* next intr. to be soon */
    return 0x38;
  }

  /* this is vsync intr. */
  if (IntSync == 1) {
    while (IntSyncWait != 0);                     /* waiting timer intr. */
    IntSyncWait = 1;
  }

  if(enableRefresh) {
    enableRefresh = 0;
    SCR[ScrMode].Refresh(topLine, bottomLine);
    PutImage(ScreenBuf);
  }

  Keyboard();
  CheckSprites();

  if (!cntRefresh--) {
    enableRefresh = 1;
    cntRefresh = UPeriod - 1;
  }

  /* Blinking for text 80 mode */
  if (!cntBlink--) {
    flgBlink = !flgBlink;
    cntBlink = 10 * (flgBlink ? VDP[13] >> 4 : VDP[13] & 0x0f);
    if (cntBlink > 0) {
      if (flgBlink) {
        XFGColor = VDP[12] >> 4;
        XBGColor = VDP[12] & 0x0F;
      } else {
        XFGColor = FGColor;
        XBGColor = BGColor;
      }
    }
  }

  VDPStatus[2] |= 0x40;        /* Vsync period starts now */
  topLine = 0;
  Cnt = IPeriod / 2;

  if (VDP[1] & 0x20) {         /* if enable Vsync */
    VDPStatus[0] |= 0x80;      /* this is Vsync intr. */
    VDPStatus[1] &= 0xfe;      /* isn't scanline intr. */
    return 0x38;
  }

  return 0;
}



void BIOSEmulate(reg *R)
{
  char buf[17];
  byte *P,I,J,K;
  reg R2;
  const byte DPB[6][18] = {
    { 0xf8,0,2,0x0f,4,1,2,1,0,2,0x70,0x0c,0,0x63,0x01,0x02,0x05,0 },
    { 0xf9,0,2,0x0f,4,1,2,1,0,2,0x70,0x0e,0,0xca,0x02,0x03,0x07,0 },
    { 0xfa,0,2,0x0f,4,1,2,1,0,2,0x70,0x08,0,0x3c,0x01,0x01,0x03,0 },
    { 0xfb,0,2,0x0f,4,1,2,1,0,2,0x70,0x0c,0,0x7b,0x02,0x02,0x05,0 },
    { 0xf0,0,2,0x00,0,0,0,1,0,2,0xe0,0x00,0,0x41,0x0b,0x09,0x12,0 },
    { 0xfe,0,4,0x00,0,0,0,1,0,2,0xc0,0x00,0,0x00,0x00,0x03,0x05,0 }
  };

  switch(R->PC.W-2) {

    case 0x4010:                                        /* Disk PHYDIO */
      Disk(R);
      break;

    case 0x4013:                                        /* Disk read DPB */
      R2.HL.W=*(word *)(RAM[7]+0x134d);
      R2.DE.W=1; R2.BC.B.h=1; R2.BC.B.l=R->BC.B.l;
      R2.AF.B.l=0;  R2.AF.B.h=R->AF.B.h;
      Disk(&R2);                                        /* Read sec.1 */
      R->AF.W=R2.AF.W;
      if(R->AF.B.l&0x01) break;                         /* Read error */
      R->BC.B.h=*(RAM[R2.HL.W>>13]+(R2.HL.W&0x1fff));
      for(I=0;I<6;I++)
        if(DPB[I][0]==R->BC.B.h) break;
      if(I==6)                                          /* Media check */
      { R->AF.W=0x0a01; break; }
      for(J=0;J<18;J++)
        *( RAM[(R->HL.W+J+1)>>13]+((R->HL.W+J+1)&0x1fff) )=DPB[I][J];
      R->AF.B.l=0;
      R->BC.B.h=(R->BC.B.h==R->BC.B.l)? 0:0xff;
      break;

    case 0x401c:                                        /* Disk format */
      break;

    case 0x00e1:                                        /* Tape read header */
      if(!UseTape) { R->AF.B.l=0x01; break; }
      fflush(Tape);
      fseek(Tape,0,SEEK_CUR);
      R->AF.B.l=1; I=strlen(TAPEHEADER);
      memset(buf,' ',I); buf[I]='\0';
      while(!feof(Tape)) {
        buf[I-1]=fgetc(Tape);
        if(!strcmp(buf,TAPEHEADER)) {
          R->AF.B.l=0; break;
        }
        for(J=0;J<I;J++) buf[J]=buf[J+1];
      }
      if(R->AF.B.l) {
        if(Verbose&0x10) printf("Can't find a tape header. rewinded.\n");
        rewind(Tape);
      }
      break;
    case 0x00e4:                                        /* Tape read */
      if(!UseTape) { R->AF.B.l=0x01; break; }
      R->AF.B.l=0;
      if(feof(Tape)) {
        R->AF.B.l=1; rewind(Tape);
        if(Verbose&0x10) printf("End of tape. rewinded.\n");
      } else R->AF.B.h=fgetc(Tape);
      break;
    case 0x00ea:                                        /* Tape write header */
      if(!UseTape) { R->AF.B.l=0x01; break; }
      fflush(Tape);
      fseek(Tape,0,SEEK_CUR);
      fputs("_________",Tape);
      fputs(TAPEHEADER,Tape); break;
    case 0x00ed:                                        /* Tape write */
      if(!UseTape) { R->AF.B.l=0x01; break; }
      R->AF.B.l=0; fputc(R->AF.B.h,Tape); break;
  }
}



void Disk(reg *R)
{
  word A;
  byte J,PS,SS,buf[512];
  char *mes;
  int I,F;

  if(Verbose&0x10)
    printf("Disk %s: Drive:%c Sector:%04d Length:%02d Buffer Address:%04xh\n",
      R->AF.B.l&C_FLAG? "write":"read ",
      R->AF.B.h+'A',R->DE.W,R->BC.B.h,R->HL.W);
  PS=PSLReg;SS=SSLReg[PSL[3]];
  DoOut(0xA8,0xFF);SSlot(0x00);
  if((F=Drives[R->AF.B.h&0x01])<0)
    RealDisk(R);
  else {
    A=R->HL.W;
    if(lseek(F,R->DE.W*512,SEEK_SET)!=R->DE.W*512)
      R->AF.W=(R->AF.B.l&C_FLAG)? 0x0901:0x0801;
    else {
      if(R->AF.B.l&C_FLAG)
        while(R->BC.B.h) {
          for(I=0;I<512;I++)
            buf[I]=*(RAM[A>>13]+(A++&0x1fff));
          if(write(F,buf,512)!=512) break;
          R->BC.B.h--;
        }
      else
        while(R->BC.B.h) {
          if(read(F,buf,512)!=512) break;
          for(I=0;I<512;I++)
            *(RAM[A>>13]+(A++&0x1fff))=buf[I];
          J=buf[8]; buf[8]='\0';
          if(!strcmp(buf,ERRORSEC)) break;
          R->BC.B.h--;
        }
      if(R->BC.B.h!=0) {
        R->AF.B.h=(R->AF.B.l&C_FLAG)? 0x0b:J;
        R->AF.B.l=0x01;
      } else R->AF.W=0x0000;
    }
  }

  DoOut(0xA8,PS); SSlot(SS);

  if(R->AF.B.h&&(Verbose&0x10)) {
    switch (R->AF.B.h) {
      case 0x00:
      case 0x01:
        mes="Disk write protected"; break;
      case 0x02:
      case 0x03:
        mes="Not ready"; break;
      case 0x04:
      case 0x05:
        mes="Data CRC error"; break;
      case 0x06:
      case 0x07:
        mes="Seek error"; break;
      case 0x08:
      case 0x09:
        mes="Record not found"; break;
      case 0x0a:
        mes="Unsupported media"; break;
      case 0x0b:
        mes="Write fault"; break;
      case 0x80:
        mes="Bad FAT"; break;
      default:
        mes="Other error";
    }
    printf("%s\n",mes);
  }
}



void ChgDisk(byte drv)
{
  DiskNo[drv] = (Drives[drv] == -1) ? 0 : DiskNo[drv] + 1;
  Drives[drv] = Disks[DiskNo[drv]];
  if(Verbose) {
    if(Drives[drv] == -1) {
      printf("  Drive %c : [real drive]\n", 'A' + drv);
    } else {
      printf("  Drive %c : [disk #%d]\n", 'A' + drv, DiskNo[drv]);
    }
  }
}
