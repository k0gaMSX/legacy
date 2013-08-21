#include <stdio.h>
#include <string.h>
#include "tape.h"
#include "svi.h"

#define TapeExtension ".CAS"
#define MAX_TAPE_LEN 524288

extern short cycles;

int tapeStatus;  // 0=stop, 1=play
int tapePos;
int tapeLen;
int cts=0;
byte tapedata[MAX_TAPE_LEN];

char tapeName[64]="";
char tapePath[64]="";

void ejectTape()
{
	*tapeName=0;
}

void setTapeName(char *name)
{
	strcpy(tapeName,fixFileName(name,TapeExtension));
	strupr(tapeName);
}

char* getTapeName(void)
{
	return tapeName;
}

void setTapePath(char *name)
{
	strcpy(tapePath,name);
}

char* getTapePath(void)
{
	return tapePath;
}

int getTapeStatus(void)
{
	//return tapeStatus;
	return 1;
}

int openTape(void)
{
	FILE *f;
	int ret=-1;
	char s[256];
	tapeStatus=cts=0;	
	if (*tapeName)	
	{
		if (strstr(tapeName,".\\")!=tapeName)
		{
			strcpy(s,tapePath);
			strcat(s,tapeName);
			if (f=fopen(s,"rb"))
			{
				strcpy(tapeName,s);
				fclose(f);
			}		
		}		
		if (!(f=fopen(tapeName,"rb")))
			ret=0;
		else
		{
			ret=1;
			tapeLen=fread(tapedata,1,MAX_TAPE_LEN,f);
			fclose(f);
			tapeStatus=1;
		}
		tapePos=0;
	}
	return ret;
}

void createTape(void)
{
	FILE *f;
	char s[256];
	if (strstr(tapeName,".\\")!=tapeName)
	{
		strcpy(s,tapePath);
		strcat(s,tapeName);
		strcpy(tapeName,s);
	}		
	if (f=fopen(tapeName,"wb"))
	{
		tapeStatus=1;
		fclose(f);
	}
}

void saveTape(void)
{
	FILE *f;
	if (*tapeName)
	{
		f=fopen(tapeName,"wb");
		fwrite(tapedata,1,tapeLen,f);
		fclose(f);
	}
}		

void rewindTape(void)
{
	tapePos=0;
}

void windTape(void)
{
	tapeFindProg();
	tapeFindProg();
	cycles-=2000;
}


void updateTape(void)
{
	if ((cts>0)&&(!--cts))
		saveTape();
}

void closeTape(void)
{
	saveTape();
	ejectTape();
	tapeStatus=0;
}

int tapeWrite(int value)
{	
	if (tapeStatus)
	{
		cycles+=120;
		tapedata[tapePos++]=value&0xFF;
		if (tapePos>=tapeLen)
			tapeLen=tapePos;
		if (tapePos>=MAX_TAPE_LEN)
		{
			tapePos--;
			tapeLen--;
		}
		cts=50;		
		return 0;
	}
	else
		return 256;
}

int tapeRead(void)
{
	cycles+=120;	
	return (tapeStatus&&(tapePos<tapeLen))?tapedata[tapePos++]:256;
}

int tapeFindProg(void)
{
	int count=0,done=0;
	cycles+=1000;
	while ((tapePos<tapeLen)&&(!done))
	{
		switch (tapedata[tapePos++])
		{
			case 0x7F : done=count>=10; break;
			case 0x55 : count++; break;
			default		: count=0; break;
		}
	}
	return done?0:256;
}

int tapeFirstProg(void)   // 1 => cload, 2 => bload, (3 => run), 0 => no executables on tape
{	
	int i;
	tapePos=0;
	if ((!tapeStatus)||tapeFindProg())
		return 0;
	i=tapedata[tapePos];
	tapePos=0;
	return (i==0xD3)?1:(i==0xD0)?2:0;
}