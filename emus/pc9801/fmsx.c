/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                          fMSX.c                         **/
/**                                                         **/
/** This file contains generic main() procedure statrting   **/
/** the emulation.                                          **/
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
#include <signal.h>
#include "MSX.h"

#ifdef PC98
#include "pc98.h"
#endif
#ifdef PCAT
#include "pcat.h"
#endif

enum opt {
  VERBOSE,IFREQ,IPERIOD,UPERIOD,HELP,PRINTER,SHM,NOSHM,_RAM,_VRAM,
  TRAP,MSX1,MSX2,MSX2P,NODISK,NOKANJI,NOFM,NOSCC,PATH,
  ROM,DISKA,DISKB,DOS2,TAPE,ROMPATH,DISKPATH,TAPEPATH,
  SHORTV,SHORTI,SHORTU,SHORTA,SHORTB,SHORTT,ROMEXT
#ifdef PC98
  ,SB,SB16,OPNV,OPL3V,PSGVOL,WIDE,SHORTW,CDRIVE
  ,DISP21,DISPDR,DISPWAB,DISPPW
#endif
#ifdef PCAT
  ,OPL3V,WIDE,SHORTW,JOYSWAP
#endif
};

char *Options[] = {
  "-verbose","-ifreq","-iperiod","-uperiod","-help",
  "-printer","-shm","-noshm","-ram","-vram",
  "-trap","-msx1","-msx2","-msx2+","-nodisk",
  "-nokanji", "-nofm","-noscc","-path",
  "-rom","-diska","-diskb","-dos2","-tape",
  "-rpath","-dpath","-tpath","-v","-i","-u","-a","-b","-t",
  "-romext",
#ifdef PC98
  "-sb","-sb16","-opnv","-opl3v","-psgvol","-wide","-w","-cdrive",
  "-21","-dr","-wab","-pw",
#endif
#ifdef PCAT
  "-opl3v","-wide","-w","-joyswap",
#endif
  NULL
};

byte Verbose     = 0;        /* Debug msgs ON/OFF      */
byte MSXVersion  = 2;        /* 0=MSX1,1=MSX2,2=MSX2+  */
byte IFreq       = 60;       /* Interrupts/sec.        */
byte UPeriod     = 3;        /* Interrupts/scr. update */
dword IPeriod    = 7000;     /* Instructions/intr.     */
char *sysPath    = NULL;     /* Path to system .ROM files */
char *romPath    = NULL;     /* Path to .ROM files */
char *diskPath   = NULL;     /* Path to disk image files */
char *tapePath   = NULL;     /* Path to tape image files */

byte IntSync     = 0;        /* 1 if sync interrupt with real time */
volatile byte IntSyncWait = 0; /* 1 if wait for real time intr. */
dword Cnt        = 0;        /* Executed instructions since last int. */

byte UseDisk     = 1;        /* 1 if use disk drive(s) */
byte UseTape     = 0;        /* 1 if use tape devise   */
byte UseRS232    = 0;        /* 1 if use RS232         */
byte UseDOS2     = 0;        /* 1 if use MSX-DOS2      */
byte UseFM       = 1;        /* 1 if use FM BIOS ROM   */
byte UseSCC      = 1;        /* 1 if use SCC           */
byte UseKanjiROM = 1;        /* 1 if use Kanji ROM     */

int Argc;
char **Argv;
char **Env;

#define CFGNUM 512
#define CFGSIZ 32768

int main(int argc,char *argv[],char *env[])
{
  FILE *rfile,*fCfg;
  int N,I,i,j,Buf;
  enum opt J;
  char *p;
  char c;
  char comment;
  char *cfgFileName = "fmsx.cfg";         /* config file name */

  Argc=argc; Argv=argv; Env=env;

  printf("%s",titleStr);
  printf("fMSX by Marat Fayzullin    (C)FMS 1994,1995\n");

  /*** add items in config file into argv ***/
  if ((fCfg = fopen(cfgFileName, "rt")) != NULL) {
    printf("Find %s: Reading...", cfgFileName);
    Argv=malloc( CFGNUM * sizeof(Argv[0]) );
    p=malloc(CFGSIZ);
    Argv[0]=argv[0];
    Argv[1]=p;
    N=1;
    comment=FALSE;
    while((c=fgetc(fCfg))!=EOF) {
      if(comment) {
        if(c=='\n') comment=FALSE;
      } else {
        switch(c) {
          case ';':
            if(p==Argv[N]) comment=TRUE;
            else *p++=c;
            break;
          case '\n':
          case ' ':
            *p='\0';
            if(strlen(Argv[N])!=0) Argv[++N]=++p;
            break;
          default:
            *p++=c;
            break;
        }
      }
    }
    *p='\0';
    if(strlen(Argv[N])!=0) N++;

    for(i=1,j=N;i<argc;i++,j++) {
      Argv[j]=argv[i];
    }
    Argc+=N-1;
    printf("OK\n");
  }

  for(N=1,I=0;N<Argc;N++) {
    if(*Argv[N]=='-') {

      for(J=0;Options[J];J++)
        if(!strcmp(Argv[N],Options[J])) break;
      switch(J) {

  case VERBOSE:
  case SHORTV:
     N++;
     if(N<Argc)
     { sscanf(Argv[N],"%x",&Buf); Verbose=Buf; }
     else printf("%s: No verbose value supplied\n",Argv[0]);
     break;
  case IFREQ:
     N++;
     if (N >= Argc) {
       printf("%s: No interrupt frequency supplied\n", Argv[0]);
     } else {
       /* IPeriod=(dword)-1; */
       IFreq = atoi(Argv[N]);
       if (IFreq < 20 || IFreq > 1000) {
         IFreq = 60;
       }
       IntSync = 1;
     }
     break;
  case IPERIOD:
  case SHORTI:
     N++;
     if (N >= Argc)
       printf("%s: No interrupt period supplied\n", Argv[0]);
     else {
       IPeriod = atoi(Argv[N]);
       if (IPeriod < 100) IPeriod = 7000;
     }
     break;
  case UPERIOD:
  case SHORTU:
     N++;
     if (N >= Argc)
       printf("%s: No screen update period supplied\n", Argv[0]);
     else {
       UPeriod = atoi(Argv[N]);
       if (UPeriod < 1 || UPeriod > 200) UPeriod = 3;
     }
     break;
  case HELP:
    printf("Usage: fmsx [-option] [filename1] [filename2]\n");
    printf("[filename1] = name of file to load as cartridge A\n");
    printf("[filename2] = name of file to load as cartridge B\n");
    printf("[-option]   = -verbose/v <level> -trap/t <address>\n");
    printf("              -ifreq <frequency>\n");
    printf("              -iperiod/i <period> -uperiod/u <period>\n");
    printf("              -diska/a <filename> -diskb/b <filename>\n");
    printf("              -tape <filename> -printer <filename>\n");
    printf("              -path/rpath/dpath/tpath <pathname>\n");
    printf("              -ram <pages> -vram <pages>\n");
    printf("              -msx1/msx2/msx2+\n");
    printf("              -nodisk -nofm -nokanji -noscc\n");
    printf("              -rom <romtype>\n");
    printf("              -help\n");
#ifdef PC98
    printf("              -cdrive -wide/w [<n>] -sb <n> -psgvol <n>\n");
#endif
#ifdef PCAT
    printf("              -sb <n> -wide/w -joyswap <1/2>\n");
#endif
    return 0;

#ifdef PC98
  case SB16:
  case SB:
    N++;
    if(N>=Argc || !isdigit(Argv[N][0])) {
      N--;
      UseSB16=1;
    } else {
      UseSB16=atoi(Argv[N]);
      if (UseSB16>3) UseSB16=3;
    }
    break;
  case OPNV:
    N++;
    if(N>=Argc || !isdigit(Argv[N][0])) {
      N--;
      printf("%s: No OPN voice No. specified.\n",Argv[0]);
    } else {
      i=atoi(Argv[N]);
      if(i>=OPN_NO_MAX) {
        printf("%s: Too large OPN voice No. specified.\n",Argv[0]);
      } else {
        N++;
        if(N>=Argc) {
          N--;
          printf("%s: No OPN voice data specified.\n",Argv[0]);
        } else {
          for(p=Argv[N],j=0;j<OPN_DATA_MAX;j++,p+=2) {
            OPNVoice[i][j]=(ATOX(*p)<<4) + ATOX(*(p+1));
          }
        }
      }
    }
    break;
  case OPL3V:
    N++;
    if(N>=Argc || !isdigit(Argv[N][0])) {
      N--;
      printf("%s: No voice No. specified.\n",Argv[0]);
    } else {
      i=atoi(Argv[N]);
      if(i>=OPL3_NO_MAX) {
        printf("%s: Too large voice No. specified.\n",Argv[0]);
      } else {
        N++;
        if(N>=Argc) {
          N--;
          printf("%s: No voice data specified.\n",Argv[0]);
        } else {
          for(p=Argv[N],j=0;j<OPL3_DATA_MAX;j++,p+=2) {
            OPL3Voice[i][j]=(ATOX(*p)<<4) + ATOX(*(p+1));
          }
        }
      }
    }
    break;

  case PSGVOL:
    N++;
    if(N>=Argc || !isdigit(Argv[N][0])) {
      N--;
      printf("%s: No offset of PSG volume supplied\n",Argv[0]);
    } else {
      PSGVolOffset=atoi(Argv[N]);
      if(PSGVolOffset>15) PSGVolOffset=15;
    }
    break;
  case DISP21:
    dispDrv=1; break;
  case DISPDR:
    dispDrv=2; break;
  case DISPWAB:
    dispDrv=3; break;
  case DISPPW:
    dispDrv=4; break;

  case WIDE:
  case SHORTW:
    dispDrv=0;
    N++;
    if(N>=Argc || !isdigit(Argv[N][0])) {
      scrHeight=200; N--;
    } else {
      scrHeight=atoi(Argv[N]);
      if(scrHeight<200) scrHeight=200;
      if(scrHeight>240) scrHeight=240;
      RefreshLine=(scrHeight<=212)? 24*4: \
        (scrHeight<=236)? (236-scrHeight)*4:0;
    }
    break;
  case CDRIVE:
    UseCDrive=1;
    break;
#endif

#ifdef PCAT
  case WIDE:
  case SHORTW:
    RefreshMode=1;
    break;
  case OPL3V:
    N++;
    if(N>=Argc || !isdigit(Argv[N][0])) {
      N--;
      printf("%s: No voice No. specified.\n",Argv[0]);
    } else {
      i=atoi(Argv[N]);
      if(i>=OPL3_NO_MAX) {
        printf("%s: Too large voice No. specified.\n",Argv[0]);
      } else {
        N++;
        if(N>=Argc) {
          N--;
          printf("%s: No voice data specified.\n",Argv[0]);
        } else {
          for(p=Argv[N],j=0;j<OPL3_DATA_MAX;j++,p+=2) {
            OPL3Voice[i][j]=(ATOX(*p)<<4) + ATOX(*(p+1));
          }
        }
      }
    }
    break;
  case JOYSWAP:
    N++;
    if(N>=Argc || !isdigit(Argv[N][0])) {
      N--;
      printf("%s: No device No. specified.\n",Argv[0]);
    } else {
      i = atoi(Argv[N]);
      JoySwap1 = (i == 1 || i == 12 || i == 21)? 1:0;
      JoySwap2 = (i == 2 || i == 12 || i == 21)? 1:0;
    }
    break;
#endif

  case PRINTER:
     N++;
     if(N<Argc) PrnName=Argv[N];
     else printf("%s: No file for printer redirection\n",Argv[0]);
     break;
  case _RAM:
    N++;
    if(N>=Argc)
      printf("%s: No number of RAM pages supplied\n",Argv[0]);
    else
    RAMPages=atoi(Argv[N]);
    break;
  case _VRAM:
    N++;
    if(N>=Argc)
      printf("%s: No number of VRAM pages supplied\n",Argv[0]);
    else
      VRAMPages=atoi(Argv[N]);
    break;

#ifdef DEBUG
  case TRAP:
  case SHORTT:
    N++; Verbose|=1; Trace=1;
    sscanf(Argv[N],"%X",&Trap);
    break;
#endif

  case MSX1:  MSXVersion=0;break;
  case MSX2:  MSXVersion=1;break;
  case MSX2P: MSXVersion=2;break;

  case NODISK:  UseDisk=0;     break;
  case NOKANJI: UseKanjiROM=0; break;
  case NOFM:    UseFM=0;       break;
  case NOSCC:   UseSCC=0;      break;
  case DOS2:    UseDOS2=1;     break;

  case PATH: N++;
    if(N>=Argc) printf("%s: No system path name\n",Argv[0]);
    else sysPath=Argv[N];
    break;
  case ROMPATH: N++;
    if(N>=Argc) printf("%s: No ROM file path name\n",Argv[0]);
    else romPath=Argv[N];
    break;
  case DISKPATH: N++;
    if(N>=Argc) printf("%s: No disk file path name\n",Argv[0]);
    else diskPath=Argv[N];
    break;
  case TAPEPATH: N++;
    if(N>=Argc) printf("%s: No tape file path name\n",Argv[0]);
    else tapePath=Argv[N];
    break;

  case ROM:
    N++;
    if (N >= Argc) {
      printf("%s: No ROM mapper type supplied\n",Argv[0]);
    } else {
      if (ROMType[1][0] == 255) {
        ROMType[1][0] = atoi(Argv[N]);
      } else {
        ROMType[2][0] = atoi(Argv[N]);
      }
    }
    break;

  case DISKA:
  case SHORTA:
    N++;
    if(N<Argc) DiskA=Argv[N];
    else printf("%s: No file for drive A\n",Argv[0]);
    UseDisk=2; break;
  case DISKB:
  case SHORTB:
    N++;
    if(N<Argc) DiskB=Argv[N];
    else printf("%s: No file for drive B\n",Argv[0]);
    UseDisk=2; break;
  case TAPE:
    N++;
    if(N<Argc) TapeFile=Argv[N];
    else printf("%s: No file for tape\n",Argv[0]);
    UseTape=1; break;

  default: printf("%s: Wrong option '%s'\n",Argv[0],Argv[N]);

      }
    } else {
      switch(I++) {
        case 0: CartA=Argv[N];break;
        case 1: CartB=Argv[N];break;
        default: printf("%s: Excessive filename '%s'\n",Argv[0],Argv[N]);
      }
    }
  }

  if(InitMachine()) {
    StartMSX();
    TrashMSX();
  } else {
    if(Verbose) printf("Unsuccessfully terminated. Try [fmsx -v 1]\n");
  }
  TrashMachine();
  return 0;
}

