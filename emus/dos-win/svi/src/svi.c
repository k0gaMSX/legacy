#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos.h>
#include <conio.h>

#include "allegro.h"
#include "svi.h"
#include "psg.h"
#include "tape.h"
#include "bmp.h"

#define RomExtension ".ROM"
#define ImageExtension ".IMG"
#define PSGExtension ".PSG"
#define SMPExtension ".SMP"
#define PRINT_FAILED { puts("FAILED"); exit(1); }
#define MAXCONFIG 128

#define DEFAULT_TRACEIO		0
#define DEFAULT_TRACEPSG	0
#define DEFAULT_TRACEVDP	0
#define DEFAULT_SHOWFPS		0
#define DEFAULT_SPEED 		1
#define DEFAULT_JOY1			1
#define DEFAULT_JOY2			2
#define DEFAULT_SOUND 		1
#define DEFAULT_SPRITE    0
#define DEFAULT_PALETTE   0
#define DEFAULT_MODEL			328
#define DEFAULT_RAM16			0
#define DEFAULT_VIDEO			0

#define smpfreq 22000
#define smpbufsize 440

typedef struct
	{
		word cycles;
		dword imode;
		word rFA,rBC,rDE,rHL,rIX,rIY,rPC,rSP;
		word rsFA,rsBC,rsDE,rsHL;
		byte rI,rR,rIFF;
	} Z80regsT;

typedef struct
	{
		int n;
		int used;
		char name[64];
		char list[33][32];
		char* plist[33];
	} cfgT;

extern int emZ80(void);
extern void resetZ80(void);
extern void setZ80regs(Z80regsT*);
extern void getZ80regs(Z80regsT*);
extern byte Bank01[],Bank11[],Bank21[],Bank31[];
extern byte Bank02[],Bank12[],Bank22[],Bank32[],EmptyBank[];
extern byte* BankSelect[];
extern byte BankROM[],vscr[];
extern short cycles,rPC;
extern byte rI,rR,rIFF;
extern byte cloadptr[],bloadptr[],vramptr[];

short traceIO 	= DEFAULT_TRACEIO;
short tracePSG	= DEFAULT_TRACEPSG;
short traceVDP	= DEFAULT_TRACEVDP;
short showFPS	 	= DEFAULT_SHOWFPS;
short speed  	 	= DEFAULT_SPEED;
short joy1   		= DEFAULT_JOY1;
short joy2			= DEFAULT_JOY2;
short snd				=	DEFAULT_SOUND;
byte  chkfifth  = DEFAULT_SPRITE?0:32;
short pal				= DEFAULT_PALETTE;
short video			= DEFAULT_VIDEO;
short model			= DEFAULT_MODEL;
short ram16     = DEFAULT_RAM16;
short ram64[6]	= {0,0,0,0,0,0};

const char emuVersion[] = "0.3";

volatile int syncFlag=1,fps=0,curFPS=0;

int brk;
short trace,emuActive,videoseg;
short quit=0,joyDis[2];

char cartPath[64]="";
char psgPath[64]="";
char smpPath[64]="";
char imgPath[64]="";
char cartName[64]="";
char psgName[64]="";
char smpName[64]="";
char imgName[64]="";
char ROMName[64]="SVI.ROM";
char *binFile=NULL;
long binAddr;

int noCfgs;
int defcfg=-1;
cfgT cfg[MAXCONFIG];

int autorun=0;

const int keyTransTbl[11][8] =
	{
	{0x008,0x007,0x006,0x005,0x004,0x003,0x002,0x00B},
	{0x035,0x034,0x00D,0x033,0x028,0x027,0x00A,0x009},
	{0x022,0x021,0x012,0x020,0x02E,0x030,0x01E,0x00C},
	{0x018,0x031,0x032,0x026,0x025,0x024,0x017,0x023},
	{0x011,0x02F,0x016,0x014,0x01F,0x013,0x010,0x019},
	{0x148,0x00E,0x01B,0x056,0x01A,0x02C,0x015,0x02D},
	{0x14B,0x01C,0x046,0x001,0x179,0x038,0x01D,0x02A},
	{0x150,0x152,0x147,0x03F,0x03E,0x03D,0x03C,0x03B},
	{0x14D,0x000,0x151,0x149,0x03A,0x153,0x00F,0x039},
	{0x047,0x04D,0x04C,0x04B,0x051,0x050,0x04F,0x052},
	{0x053,0x000,0x135,0x037,0x04A,0x04E,0x049,0x048}};

const byte KeyMap[]={
	0xFF,0x64,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x10,0x11,0x00,0x20,0x15,0x56,0x81,
	0x41,0x47,0x25,0x42,0x44,0x51,0x45,0x31,0x37,0x40,0x53,0x55,0x66,0x61,0x21,0x43,
	0x24,0x26,0x27,0x30,0x32,0x33,0x34,0x12,0x13,0xFF,0x60,0xFF,0x52,0x50,0x23,0x46,
	0xFF,0x36,0x35,0x14,0x16,0x17,0x53,0xA4,0x62,0x80,0x83,0x70,0x71,0x72,0x73,0x74,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x65,0x97,0xA0,0xA1,0xA3,0x94,0x95,0x96,0xA2,0x91,
	0x92,0x93,0x90,0xA7,0xFF,0xFF,0x54,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,

	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x66,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x63,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x75,0x57,0x84,0xFF,0x67,0xFF,0x87,0xFF,0xFF,
	0x77,0x85,0x76,0x82,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF};

const int joyKey[3][5]=
	{
	{0x00,0x00,0x00,0x00,0x00},
	{0x39,0x48,0x50,0x4B,0x4D},
	{0x52,0x48,0x50,0x4B,0x4D}};
const int joyKeyM[3][5]=
	{
	{0x00,0x00,0x00,0x00,0x00},
	{KB_NORMAL,KB_EXTENDED,KB_EXTENDED,KB_EXTENDED,KB_EXTENDED},
	{KB_NORMAL,KB_NORMAL,KB_NORMAL,KB_NORMAL,KB_NORMAL}};
const int joyKeyDis[2][5]=
	{
	{0x80,0x57,0x77,0x67,0x87},
	{0x90,0xA0,0x92,0x94,0x96}};

byte VRAM[0x4000];
word VRAMptr;
byte VRAMflag;
byte VDP[64];
byte intrq;
byte intflag;
byte sprcoll;
byte spr5th;
byte spr5thno;

const int bankT[8] = {1,1,0,0,0,1,0,0};
int bankE[8];
int bank02flag;
int bank1,bank2;
int totalRAM;

byte PSGreg;
byte capsLock;
byte PSGbuf[1500][14];
byte smpbuf[smpbufsize];
AUDIOSTREAM *audioptr;

byte IOreg;
byte keyMatrix[16];

long frames=0,PSGframes=-1;

//
// SVI-318/328 hardware emulation (VDP & PSG)
//

void doOut(int port,int value)
{
	int VDPreg,arg;
	static int first=0;
	switch (port)
	{
		case 0x80 : VRAM[((VRAMptr&0x4000)?VRAMptr++:++VRAMptr)&0x3FFF]=value;
								VRAMflag=0;
								break;
		case 0x81 : VRAMptr=(VRAMflag^=1)?
									(VRAMptr&0xFF00)+value:
									(VRAMptr&0x00FF)+(value<<8);
								if ((VRAMptr&0x8000U)&&(!VRAMflag)) {
									VDPreg=(VRAMptr>>8)&0x3F;
									arg=VRAMptr&0xFF;
									if (traceVDP) printf("%7d  VDP[%d] = %2x\n",frames,VDPreg,arg);
									VDP[VDPreg]=arg;
									if (!(VDP[1]&0x20)) intrq=0;
								}
								break;
		case 0x88 : PSGreg=value;
								if (tracePSG) printf("%7d  PSGreg=%d\n",frames,value);
								break;
		case 0x8C : AYWriteReg(PSGreg,value);
								value=AYReadReg(PSGreg);
								if (tracePSG) printf("%7d  PSG[%d]=%02x\n",frames,PSGreg,value);
								if (PSGreg==15)
								{
									setBank(value);
									if ((value&32)!=capsLock) updateCapsLock();
								}
								break;
		case 0x96 : IOreg=value&0x0F;
								break;
		default		:	if (traceIO) printf("%7d  out (%02X),%02X\n",frames,port,value);
	}
}

int doIn(int port)
{
	int ret=0xFF;
	switch (port)
	{
		case 0x84 : ret=VRAM[((VRAMptr&0x4000)?++VRAMptr:VRAMptr++)&0x3FFF];
								VRAMflag=0;
								break;
		case 0x85	: ret=(intflag<<7)+(spr5th<<6)+(sprcoll<<5)+(spr5thno&0x1F);
								intflag=intrq=sprcoll=0;
								break;
		case 0x90 : ret=PSGin(PSGreg);
								break;
		case 0x98 : ret=0x7F-
									((key[joyKey[joy1][0]]&joyKeyM[joy1][0])<<4)-
									((key[joyKey[joy2][0]]&joyKeyM[joy2][0])<<5)-
									(getTapeStatus()<<6);
								break;
		case 0x99 : ret=keyMatrix[IOreg];
								break;
		case 0x9A : ret=IOreg;
								break;
		default		:	if (traceIO) printf("%7d  in (%02X)\n",frames,port);
	}
	if (port!=0x9A) IOreg=0x08;
	return ret;
}

void updateCapsLock(void)
{
	capsLock=AYReadReg(15)&32;
	outp(0x60,0xED);
	outp(0x60,capsLock>>3);
}

int PSGin(int PSGreg)
{
	#define joy1(n) ((key[joyKey[joy1][n]]&joyKeyM[joy1][n])>0)
	#define joy2(n) ((key[joyKey[joy2][n]]&joyKeyM[joy2][n])>0)

	int ret;
	static int j1h=0,j1v=0,j2h=0,j2v=0;

	ret=AYReadReg(PSGreg);
	if (PSGreg==14)
	{
		ret=0xFF;
		if (joy1>0)
		{
			ret=ret-joy1(1)-(joy1(2)<<1)-(joy1(3)<<2)-(joy1(4)<<3);
			if (joy1(1)&&joy1(2)) ret+=j1v; else j1v=joy1(1)+(joy1(2)<<1);
			if (joy1(3)&&joy1(4)) ret+=j1h; else j1h=(joy1(3)<<2)+(joy1(4)<<4);
		}
		if (joy2>0)
		{
			ret=ret-(joy2(1)<<4)-(joy2(2)<<5)-(joy2(3)<<6)-(joy2(4)<<7);
			if (joy2(1)&&joy2(2)) ret+=j2v; else j2v=(joy2(1)<<4)+(joy2(2)<<5);
			if (joy2(3)&&joy2(4)) ret+=j2h; else j2h=(joy2(3)<<6)+(joy2(4)<<7);
		}
	}
	if (tracePSG) printf("in PSG[%d] (%02x)\n",PSGreg,ret);
	return ret;
}

void setBank(int v)
{
	int i,j;
	i=(v&1)?(v&2)?(v&8)?0:3:2:1;
	j=(v&4)?(v&16)?0:3:2;
	if (bankE[i])
	{
		BankSelect[0]=Bank01+0x8000*i;
		BankSelect[1]=Bank01+0x8000*i+0x4000;
		BankROM[0]=BankROM[1]=bankT[i];
	}
	else
	{
		BankSelect[0]=BankSelect[1]=EmptyBank;
		BankROM[0]=BankROM[1]=1;
	}
	if (bankE[j+4])
	{
		BankSelect[2]=Bank02+0x8000*j;
		BankSelect[3]=Bank02+0x8000*j+0x4000;
		BankROM[2]=BankROM[3]=bankT[j+4];
		if (!j&&!bank02flag)
		{
			BankSelect[2]=EmptyBank;
			BankROM[2]=1;
		}
		if ((i==1)&&(v&0xC0!=0xC0))
		{
			BankSelect[2]=(v&0x80)?EmptyBank:Bank12+0x4000;
			BankSelect[3]=(v&0x40)?EmptyBank:Bank12;
			BankROM[2]=BankROM[3]=1;
		}
	}
	else
	{
		BankSelect[2]=BankSelect[3]=EmptyBank;
		BankROM[2]=BankROM[3]=1;
	}
	bank1=i;
	bank2=j;
}

//
// Interrupt functions - executed at 50hz (if -speed 1)
//

void interrupt(void)
{
	int i,j,v,b;
	void *p;

	while (!syncFlag&&speed&&(!key[0x2B]));
	syncFlag=0;

	updateVideo();
	updateTape();

	if (curFPS&&showFPS)
	{
		gotoxy(1,1);
		printf("%3d%%",curFPS*2);
		fflush(stdout);
	}

	frames++;
	fps++;

	if (*psgName&&(PSGframes>=0))
	{
		if (!(++PSGframes%1500))
			savePSGbuf(1500);
		for(i=0;i<14;i++)
			PSGbuf[(PSGframes-1)%1500][i]=AYReadReg(i);
	}

	AYUpdate();
	if (*smpName) saveSMPbuf();
	if (snd&&voice_check(audioptr->voice))
		if (!speed|key[0x2B])
		{
			if (p=get_audio_stream_buffer(audioptr))
			{
				memcpy(p,smpbuf,smpbufsize);
				free_audio_stream_buffer(audioptr);
			}
		}
		else		{			
			while(!(p=get_audio_stream_buffer(audioptr))&&!(key[KEY_F12]&KB_NORMAL));
			if (p)
			{
				memcpy(p,smpbuf,smpbufsize/speed);
				free_audio_stream_buffer(audioptr);
			}
		}

	if (key[KEY_F6] & KB_NORMAL) rewindTape();
	if (key[KEY_F7] & KB_NORMAL)
	{
		windTape();
		key[KEY_F7]&=KB_EXTENDED;
	}
	//if ((key[KEY_F8] & KB_NORMAL)&&(PSGframes<0)) PSGframes=0;
	if (key[KEY_F9] & KB_NORMAL) trace=1;
	if (key[KEY_F10] & KB_NORMAL) mainmenu();
	if ((key[KEY_F11] & KB_NORMAL)&&(*imgName))
	{
		saveImage(imgName);
		key[KEY_F11]&=KB_EXTENDED;
	}
	quit|=(key[KEY_F12] & KB_NORMAL);

	for(i=0;i<=10;i++)
	{
		v=0;
		for(j=0;j<8;j++)
		{
			b=keyTransTbl[i][j];
			v=(v<<1)+((key[b&0xFF]&((b&0x100)?KB_EXTENDED:KB_NORMAL))>0);
		}
		keyMatrix[i]=v^0xFF;
	}
	if (key[0x36]&KB_NORMAL) keyMatrix[6]&=0xFE;
	if (key[0x1C]&KB_EXTENDED) keyMatrix[6]&=0xBF;

	for(i=0;i<2;i++)
		if (joyDis[i])
			for(j=0;j<5;j++)
			{
				v=joyKeyDis[i][j];
				keyMatrix[v>>4]|=1<<(v&0x0F);
			}

	intflag=1;
	intrq=VDP[1]&0x20;
}

void savePSGbuf(int l)
{
	FILE* f;
	f=fopen(psgName,"ab");
	fwrite(PSGbuf,14,l,f);
	fclose(f);
}

void saveSMPbuf(void)
{
	FILE* f;
	if (f=fopen(smpName,"ab"))
	{
		fwrite(smpbuf,1,smpbufsize,f);
		fclose(f);
	}
}

void syncHandler()
{
	syncFlag=1;
}

void fpsHandler()
{
	curFPS=fps;
	fps=0;
}

//
// Switching between emu mode on/off
//

void setEmuMode(int mode)
{
	int i;
	if (emuActive=mode)
	{
		initVMode();
		key_led_flag=0;
		clear_keybuf();
		install_keyboard();
		updateCapsLock();
		if (snd)
		{
			if ((i=allocate_voice(NULL))==-1)
				snd=0;
			else
			{
				deallocate_voice(i);
				audioptr=play_audio_stream(smpbufsize/(speed>0?speed:1),8,smpfreq,255,128);
			}
		}
		AYInit(smpfreq,smpbufsize/(speed>0?speed:1),smpbuf);
	}
	else
	{
		exitVMode();
		textmode(LASTMODE);
		clear_keybuf();
		remove_keyboard();
		if (snd) stop_audio_stream(audioptr);
	}
}

//
// Main menu
//

void mainmenu()
{
	float mhz;
	int i,resume=0;
	char s[256],*p;
	FILE *f;

	setEmuMode(0);
	textmode(C80);
	mhz=3.579545*(speed?speed:curFPS/50.0);

	do
	{
		clrscr();
		textcolor(15);
		textbackground(1);
		cprintf("SVI-318/328 emulator v%-5s                 copyright (C) 1998 by Jimmy M†rdell \n",emuVersion);
		textbackground(0);
		textcolor(7);

	 	gotoxy(50,3);
		printf("Emulating system\n");
		gotoxy(52,4);
		printf("SVI-%d at %0.2f MHz\n",model,mhz);
		gotoxy(52,5);
		printf("ROM file: %s\n",cutext(ROMName));
		gotoxy(52,6);
		printf("%dk RAM + 16k VRAM\n",totalRAM);
		gotoxy(52,7);
		printf("80-column card:    NO\n");
		gotoxy(52,8);
		printf("RS 232 interface:  NO\n");

		gotoxy(50,10);
		printf("Cartridge: %s\n",*cartName?cutext(cartName):"-");
		gotoxy(50,11);
		printf("Tape:      %s\n",*getTapeName()?cutext(getTapeName()):"-");
		gotoxy(50,12);
		printf("Disk A:    -\n");
		gotoxy(50,13);
		printf("Disk B:    -\n");

		gotoxy(50,15);
		printf("RAM image: %s\n",cutext(imgName));
		gotoxy(50,16);
		printf("PSG image: %s\n",*psgName?cutext(psgName):"-");
		gotoxy(50,17);
		printf("SMP image: %s\n",*smpName?cutext(smpName):"-");


		gotoxy(5,3);
		printf("      MAIN MENU\n");
		gotoxy(5,5);
		printf("1. Change tape image\n");
		gotoxy(5,6);
		printf("2. Change RAM image\n");
		gotoxy(5,7);
		printf("3. Change PSG image\n");
		gotoxy(5,8);
		printf("4. Change SMP image\n");
		gotoxy(5,10);
		textcolor(*psgName?7:8);
		if (PSGframes<0)
			cprintf("5. Start PSG recording\n");
		else
			cprintf("5. Stopp PSG recording\n");
		textcolor(7);
		gotoxy(5,11);
		printf("6. Screenshot\n");
		gotoxy(5,12);
		printf("7. Load image\n");
		gotoxy(5,13);
		printf("8. Save image\n");
		gotoxy(5,14);
		printf("9. Resume emulation\n");
		gotoxy(4,15);
		printf("10. Quit emulator\n");

		do
		{
			clearrow(8,17);
			gotoxy(5,17);
			printf("--> ");
			gets(s);
			i=atoi(s);
		} while ((i<1)||(i>10));
		switch (i)
		{
			case 1 	: p=selectImage("tape");
								closeTape();								
								if (*p)
								{
									setTapeName(p);
									gotoxy(5,18);
									printf("%s\n",getTapeName());
									if (!openTape())
									{
										gotoxy(5,17);										
										printf("Tape doesn't exist. Create new? (Y/N) ");
										fflush(stdout);
										if (query())
											createTape();
										else
										{
											ejectTape();
										}
										clearrow(5,17);
									}
								}
								break;
			case 2  : p=selectImage("RAM");
								if (*p)
									strcpy(imgName,fixFileName(p,ImageExtension));									
								else
									strcpy(imgName,fixFileName("quick",ImageExtension));
								break;
			case 3	:	if ((*psgName)&&(PSGframes>=0)) savePSGbuf(PSGframes%1500);
								PSGframes=-1;
								p=selectImage("PSG");
								if (*p)
								{
									strcpy(psgName,fixFileName(p,PSGExtension));
									if (!(f=fopen(psgName,"wb")))
										*psgName=0;
									else
										fclose(f);
								}
								else
									*psgName=0;
								break;
			case 4	: p=selectImage("SMP");
								if (*p)
									strcpy(smpName,fixFileName(p,SMPExtension));
								else
									*smpName=0;
								break;
			case 5	: if (*psgName)
									if (PSGframes<0)
										PSGframes=0;
									else
									{
										savePSGbuf(PSGframes%1500);
										PSGframes=-1;
									}
								break;
			case 6	: i=0;
								sprintf(s,"svi%03d.bmp",i);
								while (f=fopen(s,"rb"))
								{
									fclose(f);
									sprintf(s,"svi%03d.bmp",++i);
								}
								createBMP(s,256,192,vscr);
								break;
			case 7	: saveImage("image.tmp");
								if (!loadImage(imgName))
								{
									gotoxy(5,17);
									printf("Couldn't load image!");
									fflush(stdout);
									getch();
									loadImage("image.tmp");
								}
								remove("image.tmp");
								break;									
			case 8  : saveImage(imgName);
								break;
			case 9	: resume=1; break;
			case 10	: resume=quit=1; break;
		}
	} while (!resume);
	setEmuMode(1);
}

int query()
{
	char c;
	while (1)
	{
		c=getch();
		if ((c=='Y')||(c=='y')) return 1;
		if ((c=='N')||(c=='n')) return 0;
	}
}

void clearrow(int x, int y)
{
	int i;
	gotoxy(x,y);
	for(i=x;i<50;i++)
		printf(" ");
	printf("\n");
}

char *selectImage(char *t)
{
	static char s[256];
	gotoxy(5,17);
	printf("Select new %s image:\n",t);
	gotoxy(5,18);
	gets(s);
	clearrow(5,17);
	clearrow(5,18);
	return s;
}

char* cutext(char *s)
{
	char *p;
	p=s;
	while (*s)
		if (*s++=='\\')
			p=s;
	return p;
}

void autoRunProg(void)
{
	int i,t;
	const byte v[8]={0x00,0xF0,0x00,0xFF,0x01,0x36,0x07,0xF4};
	const byte cloadtxt[10]={0x2F,0x4B,0x43,0x4C,0x4F,0x41,0x44,0x52,0x55,0x4E};
	const byte bloadtxt[13]={0x42,0x4C,0x4F,0x41,0x44,0x02,0x43,0x41,0x53,0x1A,0x02,0x0C,0x52};
	byte *p;
	if (t=tapeFirstProg())
	{
		resetSVI();
		for(i=0;i<8;i++)
			bankE[i]=1;
		p=(t==1)?cloadptr:bloadptr;
		memcpy(Bank02+0x7000,p,0x1000);
		memset(Bank02,0,3);
		setZ80regs((Z80regsT*)(p+0x1000));
		memcpy(VRAM,vramptr,0x4000);
		if (t==1)
		{
			Bank02[0x4000]=0x00;
			Bank02[0x4001]=0x00;
			memcpy(VRAM+0x01,cloadtxt,2);
			memcpy(VRAM+0x29,cloadtxt+2,5);
			memcpy(VRAM+0xA1,cloadtxt+7,3);
			VRAM[0x51]=0xBF;
		}
		else
		{
			memcpy(VRAM+0x01,bloadtxt,13);
			VRAM[0x29]=0xBF;
		}
		memcpy(VDP,v,8);
		VRAMptr=0x40CA;
		VRAMflag=intrq=intflag=0;
		AYWriteReg(0,0x55);
		AYWriteReg(7,0xB8);
		AYWriteReg(14,0xFF);
	}
}

//
// Routines for saving/loading images
//

void saveImage(char *imgName)
{
	#define fwriteByte(f,i) fwrite(&i,1,sizeof(byte),f)
	#define fwriteWord(f,i) fwrite(&i,1,sizeof(word),f)

	FILE *f;
	Z80regsT r;

	f=fopen(imgName,"wb");
	fwrite(Bank02,1,0x8000,f);
	fwrite(Bank21,1,0x8000,f);
	fwrite(Bank22,1,0x8000,f);
	fwrite(Bank31,1,0x8000,f);
	fwrite(Bank32,1,0x8000,f);

	fwrite(VRAM,1,0x4000,f);
	fwrite(VDP,1,0x40,f);
	fwriteWord(f,VRAMptr);
	fwriteByte(f,VRAMflag);
	fwriteByte(f,intrq);
	fwriteByte(f,intflag);

	fwrite(AYPSGptr(),1,sizeof(AY8910),f);
	fwriteByte(f,PSGreg);

	fwrite(keyMatrix,1,0x10,f);

	fwriteByte(f,IOreg);

	getZ80regs(&r);
	fwrite(&r,1,sizeof(r),f);

	fclose(f);
}

int loadImage(char *imgName)
{
	#define freadByte(f,i) fread(&i,1,sizeof(byte),f)
	#define freadWord(f,i) fread(&i,1,sizeof(word),f)

	FILE *f;
	Z80regsT r;
	int ok=1;

	if ((f=fopen(imgName,"rb"))==NULL) return 0;
	ok&=(fread(Bank02,1,0x8000,f)==0x8000);
	ok&=(fread(Bank21,1,0x8000,f)==0x8000);
	ok&=(fread(Bank22,1,0x8000,f)==0x8000);
	ok&=(fread(Bank31,1,0x8000,f)==0x8000);
	ok&=(fread(Bank32,1,0x8000,f)==0x8000);

	ok&=(fread(VRAM,1,0x4000,f)==0x4000);
	ok&=(fread(VDP,1,0x40,f)==0x40);

	ok&=(freadWord(f,VRAMptr)==sizeof(word));
	ok&=(freadByte(f,VRAMflag)==sizeof(byte));
	ok&=(freadByte(f,intrq)==sizeof(byte));
	ok&=(freadByte(f,intflag)==sizeof(byte));

	ok&=(fread(AYPSGptr(),1,sizeof(AY8910),f)==sizeof(AY8910));
	ok&=(freadByte(f,PSGreg)==sizeof(byte));

	ok&=(fread(keyMatrix,1,0x10,f)==0x10);

	ok&=(freadByte(f,IOreg)==sizeof(byte));

	ok&=(fread(&r,1,sizeof(r),f)==sizeof(r));
	setZ80regs(&r);

	fclose(f);

	updateCapsLock();
	setBank(AYReadReg(15));

	return ok;
}

//
// Parsing arguments
//

void parseArg(int noArg, char *arg[])
{
	#define CheckLastPar if (i+1==noArg) parErr=1
	int i=1,j,opt,parErr=0,found;
	char *options[]=
		{"-traceio","-showspeed","-sound","-cart","-image","-joy1","-joy2",
		 "-tape","-rom","-bin","-pal","-psg","-tracepsg","-speed","-smp","-sprite",
		 "-tracevdp","-model","-ram16","-ram64","-tapa","-video",NULL};
	while ((i<noArg)&&(!parErr))
	{
		j=opt=0;
		while(options[j])
			if (!stricmp(arg[i],options[j++])) opt=j;
		switch (opt)
		{
			case 0 	: if (arg[i][0]!='-')
									parErr=2;
								else
								{
									found=0;
									for(j=0;j<noCfgs;j++)
										if (!stricmp(arg[i]+1,cfg[j].name))
										{
											found=1;
											if (!cfg[j].used)
											{
												cfg[j].used=found=1;
												parseArg(cfg[j].n,cfg[j].plist);
											}
										}
									if (!found) parErr=2;
								}
								break;
			case 1 	: traceIO=1; break;
			case 2 	: showFPS=1; break;
			case 3 	: CheckLastPar; else snd=atoi(arg[++i]); break;
			case 4 	: CheckLastPar; else strcpy(cartName,arg[++i]); break;
			case 5 	: CheckLastPar; else strcpy(imgName,arg[++i]); break;
			case 6 	: CheckLastPar; else joy1=atoi(arg[++i]); break;
			case 7 	: CheckLastPar; else joy2=atoi(arg[++i]); break;
			case 8 	: CheckLastPar; else setTapeName(arg[++i]); autorun=0; break;
			case 9	: CheckLastPar; else strcpy(ROMName,arg[++i]); break;
			case 10	: if (i+2>=noArg)
									parErr=1;
								else
								{
									binFile=arg[++i];
									binAddr=readHex(arg[++i]);
								}
								break;
			case 11 : CheckLastPar; else pal=atoi(arg[++i]); break;
			case 12 : CheckLastPar; else strcpy(psgName,arg[++i]); break;
			case 13	: tracePSG=1; break;
			case 14	: CheckLastPar; else speed=atoi(arg[++i]); break;
			case 15 : CheckLastPar; else strcpy(smpName,arg[++i]); break;
			case 16 : CheckLastPar; else chkfifth=atoi(arg[++i])?0:32; break;
			case 17 : traceVDP=1; break;
			case 18 : CheckLastPar; else model=atoi(arg[++i]); break;
			case 19 : ram16=1; break;
			case 20 : CheckLastPar; else extraRAM(arg[++i]); break;
			case 21 : CheckLastPar; else setTapeName(arg[++i]); autorun=1; break;
			case 22 : CheckLastPar; else video=atoi(arg[++i]); break;
		}
		i++;
	}
	if (parErr==1)
	{
		printf("Missing parameter: %s\n",arg[i-1]);
		exit(1);
	}
	else if (parErr==2)
	{
		printf("Wrong option: %s\n",arg[i-1]);
		exit(1);
	}
}

void adjustParameters(void)
{
	if ((joy1<0)||(joy1>4)) joy1=DEFAULT_JOY1;
	if ((joy2<0)||(joy2>4)) joy2=DEFAULT_JOY1;
	joyDis[0]=((joy1==3)||(joy2==3));
	joyDis[1]=((joy1==4)||(joy2==4));
	if (joy1>2) joy1-=2;
	if (joy2>2) joy2-=2;

	if ((model!=318)&&(model!=328)) model=DEFAULT_MODEL;
	if ((speed!=0)&&(speed!=1)&&(speed!=2)&&(speed!=4)) speed=DEFAULT_SPEED;
	if ((pal<0)||(pal>2)) pal=DEFAULT_PALETTE;
	if ((video<0)||(video>1)) video=DEFAULT_VIDEO;
	setPalette(pal);

	strcpy(ROMName,fixFileName(ROMName,RomExtension));
	if (*cartName) strcpy(cartName,fixFileName(cartName,RomExtension));
	if (*ROMName) strcpy(ROMName,fixFileName(ROMName,RomExtension));
	if (*imgName) strcpy(imgName,fixFileName(imgName,ImageExtension));
	if (*psgName) strcpy(psgName,fixFileName(psgName,PSGExtension));
	if (*smpName) strcpy(smpName,fixFileName(smpName,SMPExtension));
}

void extraRAM(char *s)
{
	int i,j;
	char *p;
	p=s;
	while (*p&&p[1])
	{
		j=((*p)-48)*10+p[1]-48;
		if ((j!=21)&&(j!=31)&&(j!=2)&&(j!=22)&&(j!=32))
		{
			printf("Not a valid set of banks: %s\n",s);
			exit(1);
		}
		i=0;
		while (ram64[i]&&(ram64[i]!=j))
			i++;
		ram64[i]=j;
		p+=2;
		if (*p==';') p++;
	}
}

char *fixFileName(char *file, char *ext)
{
	static char str[200];
	char *p;
	strcpy(str,file);
	p=str;
	while (strchr(p,'\\'))
		p=strchr(p,'\\')+1;
	while (*p)
	{
		if (*p=='.') *p--=0;
		p++;
	}
	strcat(str,ext);
	strupr(str);
	return str;
}

long readHex(char *s)
{
	long res=0,i=0,j;
	strupr(s);
	while (*s)
	{
		if ((*s>='0')&&(*s<='9'))
			j=*s-'0';
		else if ((*s>='A')&&(*s<='F'))
			j=*s-'A'+10;
		else
			return 0;
		res=(res<<4)+j;
		i++;
		s++;
	}
	return (i>4)?0:res;
}


//
// Initializing SVI system
//

void resetSVI()
{
	memset(Bank02,0xFF,0x8000);
	memset(Bank21,0xFF,0x8000);
	memset(Bank22,0xFF,0x8000);
	memset(Bank31,0xFF,0x8000);
	memset(Bank32,0xFF,0x8000);
	memset(EmptyBank,0xFF,0x4000);

	resetZ80();
	VRAMptr=VRAMflag=0;
	memset(VDP,0,sizeof(VDP));
	memset(VRAM,0,sizeof(VRAM));

	PSGreg=0;
	intflag=intrq=sprcoll=spr5th=spr5thno=0;
	AYResetChip();
	AYWriteReg(15,0xDF);
	setBank(AYReadReg(15));
}

void init(void)
{
	FILE *f;
	int i,fsize;
	char s[256];

	videoseg = __dpmi_segment_to_descriptor(0xA000);

	printf("Initializing system... ");
	memset(Bank01,0xFF,0x8000);
	memset(Bank11,0xFF,0x8000);
	memset(Bank12,0xFF,0x8000);
	memset(bankE,0,sizeof(bankE));
	bankE[0]=bankE[4]=1;
	if (model==328) bankE[2]=1;
	bank02flag=((model==328)||(ram16));
	for(i=0;i<6;i++)
		switch(ram64[i])
		{
			case 21 : bankE[2]=1; break;
			case 31 : bankE[3]=1; break;
			case 02 : bankE[4]=bank02flag=1; break;
			case 22 : bankE[6]=1; break;
			case 32 : bankE[7]=1; break;
		}
	totalRAM=16+bank02flag*16+bankE[2]*32+bankE[3]*32+bankE[6]*32+bankE[7]*32;
	resetSVI();
	puts("OK");

	if (snd)
	{
		printf("Initializing sound... ");		
		if (install_sound(DIGI_AUTODETECT,MIDI_NONE,NULL)) PRINT_FAILED		
		//if ((i=allocate_voice(NULL))==-1) PRINT_FAILED
		//voice_start(i);
		audioptr=play_audio_stream(smpbufsize,8,smpfreq,0,128);
		//printf("%x\n",voice_check(i));
		//deallocate_voice(i);		
		//exit(0);
		if (!voice_check(audioptr->voice))
		{
			stop_audio_stream(audioptr);
			PRINT_FAILED
		}
		
		puts("OK");
	}

	printf("Loading ROM... ");
	if (!(f=fopen(ROMName,"rb"))) PRINT_FAILED
	if (fread(Bank01,1,0x8000,f)!=0x8000) PRINT_FAILED
	fclose(f);
	puts("OK");

	printf("Patching ROM... ");
	Bank01[0x2073]=0x01;   // Skip delay loop after save
	Bank01[0x20D0]=0x10;   // Write $55 only $10 times, instead
	Bank01[0x20D1]=0x00;   //   of $190
	Bank01[0x20E3]=0x00;   // Cancel instruction
	Bank01[0x20E4]=0x00;
	Bank01[0x20E5]=0x00;
	Bank01[0x20E6]=0xED;   // Patching tapeWrite
	Bank01[0x20E7]=0xFF;
	Bank01[0x210A]=0xED;   // Patching tapeFindProg
	Bank01[0x210B]=0xFD;
	Bank01[0x21A9]=0xED;   // Patching tapeRead
	Bank01[0x21AA]=0xFE;
/*
	Bank01[0x2084]=0xC3;
	Bank01[0x2085]=0x84;
	Bank01[0x2086]=0x20;
*/
	puts("OK");

	if (*cartName)
	{
		printf("Loading cartridge... ");

		if (strstr(cartName,".\\")!=cartName)
		{
			strcpy(s,cartPath);
			strcat(s,cartName);
			if (f=fopen(s,"rb"))
			{
				strcpy(cartName,s);
				fclose(f);
			}
		}
		if (!(f=fopen(cartName,"rb"))) PRINT_FAILED
		if (fread(Bank11,1,0x8000,f)==0x8000)
			fread(Bank12,1,0x8000,f);
		fclose(f);
		puts("OK");
		bankE[1]=bankE[5]=1;
	}


	if (*psgName)
	{
		printf("Creating PSG dumpfile... ");
		if (!(f=fopen(psgName,"wb"))) PRINT_FAILED
		fclose(f);
		puts("OK");
	}

	if (*smpName)
	{
		printf("Creating SMP dumpfile... ");
		if (!(f=fopen(smpName,"wb"))) PRINT_FAILED
		fclose(f);
		puts("OK");
	}

	if (*getTapeName())
	{
		printf("Loading tape image... ");
		if (openTape())
			puts("OK");
		else
			PRINT_FAILED
	}

	if (*imgName)
	{
		printf("Loading image... ");
		if (loadImage(imgName))
			puts("OK");
		else
			PRINT_FAILED
	}
	else	
		strcpy(imgName,fixFileName("quick",ImageExtension));

	if (autorun)
		autoRunProg();

	if (binFile)
	{
		printf("Loading binary file... ");
		if ((f=fopen(binFile,"rb"))==NULL)
			PRINT_FAILED
		else
		{
			fseek(f,0,SEEK_END);
			fsize=ftell(f);
			if ((binAddr<0x8000)||(binAddr+fsize>0x10000))
				PRINT_FAILED
			else
			{
				fseek(f,0,SEEK_SET);
				fread(Bank02+(binAddr&0x7FFF),1,fsize,f);
				puts("OK");
			}
			fclose(f);
		}
	}

	trace=0;
	brk=-1;

	if (speed)
		install_int(syncHandler,20/speed);
	if (showFPS||!speed)
		install_int(fpsHandler,1000);
}

void trashEmu(void)
{
	if ((*psgName)&&(PSGframes>=0)) savePSGbuf(PSGframes%1500);
	closeTape();
	printf("Emulation stopped after %d frames.\nUser abort.\n",frames);
}

//
// Read configuration file
//

void readconfig()
{
	#define PRINT_ERROR(s) { printf("\nLine %d: %s",line,s); err=1; }
	FILE *f;
	int section=0,line=0,err=0,i,j;
	char s[256],*p,*q;

	noCfgs=0;

	printf("Reading configuration file... ");
	if (f=fopen("svi.cfg","rt"))
	{
		while (!feof(f))
		{
			line++;
			fgets(s,256,f);
			if (feof(f))
				*s=0;
			*(strchr(s,0)-1)=0;
			p=trim(s);
			if ((*p=='[')&&(!*(strchr(p,']')+1)))
			{
				if (!stricmp(s,"[Paths]"))
					section=1;
				else if (!stricmp(s,"[Configurations]"))
					section=2;
				else
					PRINT_ERROR("Unknown section")
			}
			else if ((*p)&&(*p!=';')&&(*p!='#'))
			{
				if (!section)
					PRINT_ERROR("No section specified")
				else if (q=strchr(p,'='))
				{
					*q++=0;
					p=trim(p);
					q=trim(q);
					if (section==1)
					{
						if (*(strchr(q,0)-1)!='\\')
							q=strcat(q,"\\");
						if (!stricmp(p,"tape"))
							setTapePath(q);
						else if (!stricmp(p,"cart"))
							strcpy(cartPath,q);
						else if (!stricmp(p,"psg"))
							strcpy(psgPath,q);
						else if (!stricmp(p,"smp"))
							strcpy(smpPath,q);
						else if (!stricmp(p,"img"))
							strcpy(imgPath,q);
						else
							PRINT_ERROR("Unknown pathtype")
					}
					else
					{
						if (!*p)
							PRINT_ERROR("Missing configuration name")
						else
						{
							if (noCfgs>=MAXCONFIG)
								PRINT_ERROR("Too many configurations")
							strcpy(cfg[noCfgs].name,p);
							if (!stricmp(p,"default"))
								defcfg=noCfgs;
							i=1;
							while (*q)
							{
								p=q;
								if (q=strchr(q,' '))
								{
									*q++=0;
									q=trim(q);
								}
								else
									q=strchr(q,0);
								cfg[noCfgs].plist[i]=cfg[noCfgs].list[i];
								strcpy(cfg[noCfgs].list[i++],p);
							}
							cfg[noCfgs].used=0;
							cfg[noCfgs++].n=i;
						}
					}
				}
				else
					PRINT_ERROR("Missing =")
			}
		}
		if (err)
		{
			printf("\n");
			exit(1);
		}
		else
			puts("OK");
	}
	else
		printf("file not found!\n");

/*
	for(i=0;i<noCfgs;i++)
	{
		printf("%s\n",cfg[i].name);
		for(j=1;j<cfg[i].n;j++)
			printf("  %s\n",cfg[i].list[j]);
	}
*/
}

char* trim(char *s)
{
	char *p;
	while (*s==32)
		s++;
	p=strchr(s,0)-1;
	while ((*p==32)&&(p>=s))
		p--;
	*++p=0;
	return s;
}

//
// MAIN
//

int main(int argc, char *argv[])
{
	allegro_init();
	install_timer();
	printf("SVI-318/328 emulator v%s\n",emuVersion);
	printf("Copyright (C) 1998  Jimmy M†rdell\n\n");
	readconfig();
	if (defcfg>=0)
	{
		cfg[defcfg].used=1;
		parseArg(cfg[defcfg].n,cfg[defcfg].plist);
	}
	parseArg(argc,argv);
	adjustParameters();
	init();
	printf("Press ESC to cancel, any other key to start SVI emulation...\n");
	if (getch()!=27)
	{
		setEmuMode(1);
		emZ80();
		setEmuMode(0);
	}
	trashEmu();
	clear_keybuf();
	return 0;
}