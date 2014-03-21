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

 Make Boot: to make an UZIX disk bootable.
 Usage:	mkboot [-y] d: primary secondary image
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
#include ".\include\stdio.h"
#include ".\include\stdlib.h"
#include ".\include\ctype.h"
#else
#include <c:\tc\include\stdio.h>
#include <c:\tc\include\stdlib.h>
#include <c:\tc\include\ctype.h>
#endif

#define IMAGE	(0x7000/512)

int _yes = 0;

dev_t dev;
filesys_t filsys;

char *daread __P((uint blk));
void dwrite __P((uint blk, void *addr));
int da_read __P((dev_t,uint,void *));
int da_write __P((dev_t,uint,void *));

int da_read(dev, blk, addr)
	dev_t dev;
	uint blk;
	void *addr;
{
	bufptr buf = bread(dev, blk, 0);

	if (buf == NULL)
		return 0;
	bcopy(buf, addr, BUFSIZE);
	bfree(buf, 0);
	return BUFSIZE;
}

int da_write(dev, blk, addr)
	dev_t dev;
	uint blk;
	void *addr;
{
	bufptr buf = bread(dev, blk, 1);

	if (buf == NULL)
		return 0;
	bcopy(addr, buf, BUFSIZE);
	bfree(buf, 1);
	return BUFSIZE;
}

char *daread(blk)
	uint blk;
{
	static char buf[BUFSIZE];

	if (da_read(dev, blk, buf) != BUFSIZE) {
		PF("Read of block %d failed.\n", blk);
		abort();
	}
	return (buf);
}

void dwrite(blk, addr)
	uint blk;
	void *addr;
{
	if (da_write(dev, blk, addr) != BUFSIZE) {
		PF("Write of block %d failed.\n", blk);
		abort();
	}
}

void _pass(char *fn, char *descr, uint from, uint to) {
	FILE *fd = fopen(fn, "rb");
	bufptr buf;
	uint i;

	if (fd == NULL) {
		fprintf(stderr, "Can't find %s %s\n", descr, fn);
		xexit(1);
	}
	i = from;
	while (i <= to) {
		if ((buf = bread(dev, i, 2)) == NULL) {
			fprintf(stderr, "Get block %d error.\n", i);
			xexit(1);
		}
		if (fread(buf, 1, 512, fd) == 0) {
			bfree(buf, 0);
			break;
		}
		bfree(buf, 2);
		if (feof(fd))
			break;
		++i;
	}
	fclose(fd);
	if (i == from) {
		fprintf(stderr, "Can't read %s %s\n", descr, fn);
		xexit(1);
	}
}

/* 1 - write primary bootstrap */
void pass1(char *fn) {
	FILE *fd = fopen(fn, "rb");
	char diskpar[30];
	static char bootdata[256];
	bufptr buf;

	if (fd == NULL) {
		fprintf(stderr, "Can't find primary bootstrap %s\n", fn);
		xexit(1);
	}
	if ((buf = bread(dev, 0, 0)) == NULL) {
		fprintf(stderr, "Get block 0 error.\n");
		xexit(1);
	}
	bcopy(buf, diskpar, 30);
	bcopy(&(buf->bf_data[256]), bootdata, 256);
	bfree(buf, 0);
	if ((buf = bread(dev, 0, 2)) == NULL) {
		fprintf(stderr, "Get block 0 error.\n");
		xexit(1);
	}
	if (fread(buf, 1, 512, fd) == 0) {
		bfree(buf, 0);
		fprintf(stderr, "Can't read primary bootstrap %s\n", fn);
		xexit(1);
	}
	bcopy(buf, diskpar, 11);
	bcopy(diskpar, buf, 30);
	bcopy(bootdata, &(buf->bf_data[256]), 256);
	bfree(buf, 2);
	fclose(fd);
}

/* 2 - write secondary bootstrap */
void pass2(char *fn) {
	_pass(fn, "secondary bootstrap", SUPERBLOCK+1, SUPERBLOCK+1+4-1);
}

/* 3 - write image */
void pass3(char *fn) {
	_pass(fn, "image", SUPERBLOCK+1+5-1, SUPERBLOCK+1+5+55-1);
}

void main(argc, argv)
	int argc;
	char *argv[];
{
	char *p = argv[1];
	int ix = 1;
	bufptr buf;

#ifdef _MSX_DOS
	initenv();
#endif
	if (--argc > 0 && *p == '-') {
		if (p[1] != 'y' && p[1] != 'Y') {
			fprintf(stderr, "Illegal switch %s\n", p);
			xexit(-1);
		}
		++_yes;
		++ix;
		--argc;
	}
	if ((argc != 4) || (argv[ix][1] != ':') || !isalpha(argv[ix][0])) {
		fprintf(stderr,"usage: mkboot [-y] d: primary secondary image\n");
		xexit(0);
	}
	dev = ((argv[ix][0] & 223) - 65);
	if (dev >= 8) {
		fprintf(stderr,"Invalid drive %c.\n",dev+65);
		xexit(1);
	}
#ifdef _MSX_DOS
	if (!_yes) {
		PF("Insert disk and press RETURN: ");	FF;
		while (getchar() != '\n')
			;
		cursor(0);
	}
#endif
	bufinit();
	if (d_init() || d_open(dev)) {
		fprintf(stderr,"Can't open device number %x\n", dev);
		xexit(1);
	}
	/* Read in the super block. */
	if ((buf = bread(dev,SUPERBLOCK,0)) == NULL) {
		fprintf(stderr,"Can't read device %x superblock\n", dev);
		xexit(1);
	}
	bcopy(buf, &filsys, sizeof(filesys_t));
	bfree(buf, 0);
	if (filsys.s_mounted != SMOUNTED) {
		fprintf(stderr, "Drive %c has invalid magic number %d\n",
			dev+65, filsys.s_mounted);
		xexit(1);
	}
	if (filsys.s_reserv-(SUPERBLOCK+1) != IMAGE+4) {
		fprintf(stderr, "Drive %c has invalid number of reserved blocks (%d)\n",
			dev+65, filsys.s_reserv - (SUPERBLOCK+1));
		xexit(1);
	}
	PF("Installing boot to disk in drive %c: ", dev+65);	FF;
	pass1(argv[++ix]);	PF("primary, ");	FF;
	pass2(argv[++ix]);	PF("secondary, ");	FF;
	pass3(argv[++ix]);	PF("image.\n");		FF;
	bufsync();
	d_close(dev);
	PF("Done.\n");
	exit(0);
}

