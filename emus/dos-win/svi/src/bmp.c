#include <stdio.h>
#include "svi.h"

extern byte* palptr[];

const char ID[2] = {'B','M'};

typedef struct
	{
		int filesize;  // Filesize
		int reserved;  // Reserved
		int BOF;       // Offset of bitmap in file
		int lenBMIH;   // Length of BitMapInfoHeader
		int width;     // X-width
		int height;    // Y-height
		short planes;  // Number of planes
		short BPP;     // Bits per pixel
		int comptype;  // Compression type
		int picsize;   // Size of picture in bytes
		int hres;      // Horizontal resolution
		int vres;      // Vertical resolution
		int cols;      // Number of used colors
		int icols;     // Important colors
	} headerT;
	
void createBMP(char *filename, int xsize, int ysize, byte *pic)
{
	headerT h;
	byte pal[256][4];
	int i,j;
	FILE *f;
	
	h.filesize=2+sizeof(h)+sizeof(pal)+xsize*ysize;
	h.reserved=0;
	h.BOF=0x0436;
	h.lenBMIH=0x0028;
	h.width=xsize;
	h.height=ysize;
	h.planes=1;
	h.BPP=8;
	h.comptype=0;
	h.picsize=xsize*ysize;
	h.hres=1;
	h.vres=1;
	h.cols=0;
	h.icols=0;

	memset(pal,0,sizeof(pal));	
	for(i=0;i<16;i++)
	{
		for(j=0;j<3;j++)
			pal[i][j]=pal[i+16][j]=(*palptr)[i*3+2-j];
		pal[i][3]=pal[i+16][3]=0;
	}
	
	if (f=fopen(filename,"wb"))
	{
		fwrite(ID,1,sizeof(ID),f);
		fwrite(&h,1,sizeof(h),f);
		fwrite(pal,1,sizeof(pal),f);
		i=xsize*ysize;
		while (i>0)
		{
			i-=xsize;
			fwrite(pic+i,1,xsize,f);
		}
		fclose(f);
	}
}
