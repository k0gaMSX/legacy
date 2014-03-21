/*
 * UZIX - UNIX Implementation for MSX
 * (c) 1997-2001 Arcady Schekochikhin
 *		 Adriano C. R. da Cunha
 *
 * UZIX is based on UZI (UNIX Zilog Implementation)
 * UZI is a UNIX kernel clone written for Z-80 systems.
 * All code is public domain, not being based on any AT&T code.
 *
 * The author, Douglas Braun, can be reached at:
 *	7696 West Zayante Rd.
 *	Felton, CA 95018
 *	oliveb!intelca!mipos3!cadev4!dbraun
 *
 * This program is under GNU GPL, read COPYING for details
 *
 */

/**********************************************************
 UZIX utilities:

 Block dump: to examine disk.
 Usage:	bd d: blkstart [blkend]
**********************************************************/

/* The device is given as drive letter.
 * Major device is always 0 (FDD), minor device is 0..7 (drives A..H)
 */

#define __MAIN__COMPILATION
#define NEED__DEVIO

#include "utildos.h"
#ifdef SEPH
#include "sys\ioctl.h"
#endif
#ifdef _MSX_DOS
#include "..\include\stdio.h"
#include "..\include\stdlib.h"
#include "..\include\ctype.h"
#else
#include <c:\tc\include\stdio.h>
#include <c:\tc\include\stdlib.h>
#include <c:\tc\include\ctype.h>
#endif

char buf[BUFSIZE];

void dread(int dev, uint blk, char *addr);

void dread(dev, blk, addr)
	int dev;
	uint blk;
	char *addr;
{
	char *buf = bread(dev, blk, 0);
	if (buf == NULL) {
		printf("bd: disk is not MSXDOS compatible, device or drive error\n");
		xexit(1);
	}
	bcopy(buf, addr, BUFSIZE);
	bfree((bufptr)buf, 0);
}

void main(argc, argv)
	int argc;
	char *argv[];
{
	int i, j, k, dev;
	unsigned blkno, blkend;
	long addr;

#ifdef _MSX_DOS
	initenv();
#endif
	if (argc < 3 || !isalpha(argv[1][0]) || (argv[1][1] != ':')) {
		fprintf(stderr, "usage: bd d: blkstart [blkend|-blkno]\n");
		xexit(1);
	}
	dev = ((argv[1][0] & 223) - 65);
	blkno = (unsigned)atol(argv[2]);
	if (argc < 4)
		blkend = blkno;
	else {
		if (argv[3][0] == '-')
			blkend = blkno + (unsigned)atol(argv[3]+1) - 1;
		else	blkend = (unsigned)atol(argv[3]);
	}
#ifdef _MSX_DOS
	printf("Insert disk and press RETURN: ");
	while (getchar() != '\n')
		;
	cursor(0);
#endif
	bufinit();
	d_init();
	d_open(dev);
	printf("Device %x, blocks %u..%u (0x%X..0x%X)\n\n",
		dev,blkno,blkend,blkno,blkend);
	addr = (long)blkno * BUFSIZE;	/* starting address */
	while (blkno <= blkend) {
		printf("Block %u (0x%X)\n", blkno, blkno);
		dread(dev, blkno++, buf);
		for (i = 0; i < BUFSIZE / 16; ++i, addr += 16) {
			printf("%02x%04x\t", (uint)(addr >> 16), (uint)addr);
			for (j = 0; j < 16; ++j) {
				k = buf[(i<<4)+j] & 0xFF;
				printf("%02X ", k);
			}
			printf(" |");
			for (j = 0; j < 16; ++j) {
				k = buf[(i<<4)+j] & 0xFF;
				if (k < ' ' || k == 0177 || k == 0377)
					k = '.';
				printf("%c", k);
			}
			printf("|\n");
		}
		printf("\n");
		fflush(stdout);
	}
#ifdef _MSX_DOS
	cursor(255);
#endif
	exit(0);
}

