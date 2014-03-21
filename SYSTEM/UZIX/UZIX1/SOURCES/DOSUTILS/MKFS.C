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

 Make Filesystem: to make an UZIX disk.
 Usage:	mkfs [-yfqv] d: fsize isize [rsize]
**********************************************************/

/* The device is given as drive letter.
 * Major device is always 0 (FDD), minor device is 0..7 (drives A..H)
 */

#define __MAIN__COMPILATION
#define NEED__DEVIO

#include "utildos.h"

#ifdef SEPH
#include "sys\ioctl.h"
#include "sys\stat.h"
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

char bootblock[512] = {
	0xEB, 0xFE, 0x90, 'U',	'Z',  'I',  'X',  'd',
	'i',  's',  'k',  0x00, 0x02, 0x02, 0x01, 0x00,
	0x00, 0x00, 0x00, 0xA0, 0x05, 0xF9, 0x00, 0x00,
	0x09, 0x00, 0x02, 0x00, 0x00, 0x00, 0xD0, 0x36,
	0x56, 0x23, 0x36, 0xC0, 0x31, 0x1F, 0xF5, 0x11,
	0x4A, 0xC0, 0x0E, 0x09, 0xCD, 0x7D, 0xF3, 0x0E,
	0x08, 0xCD, 0x7D, 0xF3, 0xFE, 0x1B, 0xCA, 0x22,
	0x40, 0xF3, 0xDB, 0xA8, 0xE6, 0xFC, 0xD3, 0xA8,
	0x3A, 0xFF, 0xFF, 0x2F, 0xE6, 0xFC, 0x32, 0xFF,
	0xFF, 0xC7, 0x57, 0x41, 0x52, 0x4E, 0x49, 0x4E,
	0x47, 0x21, 0x07, 0x0D, 0x0A, 0x0A, 0x54, 0x68,
	0x69, 0x73, 0x20, 0x69, 0x73, 0x20, 0x61, 0x6E,
	0x20, 0x55, 0x5A, 0x49, 0x58, 0x20, 0x64, 0x69,
	0x73, 0x6B, 0x2C, 0x20, 0x6E, 0x6F, 0x6E, 0x20,
	0x62, 0x6F, 0x6F, 0x74, 0x61, 0x62, 0x6C, 0x65,
	0x2E, 0x0D, 0x0A, 0x55, 0x73, 0x69, 0x6E, 0x67,
	0x20, 0x69, 0x74, 0x20, 0x75, 0x6E, 0x64, 0x65,
	0x72, 0x20, 0x4D, 0x53, 0x58, 0x44, 0x4F, 0x53,
	0x20, 0x63, 0x61, 0x6E, 0x20, 0x64, 0x61, 0x6D,
	0x61, 0x67, 0x65, 0x20, 0x69, 0x74, 0x2E, 0x0D,
	0x0A, 0x0A, 0x48, 0x69, 0x74, 0x20, 0x45, 0x53,
	0x43, 0x20, 0x66, 0x6F, 0x72, 0x20, 0x42, 0x41,
	0x53, 0x49, 0x43, 0x20, 0x6F, 0x72, 0x20, 0x61,
	0x6E, 0x79, 0x20, 0x6B, 0x65, 0x79, 0x20, 0x74,
	0x6F, 0x20, 0x72, 0x65, 0x62, 0x6F, 0x6F, 0x74,
	0x2E, 0x24, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
};

/* This makes a filesystem */
dev_t dev;
direct_t dirbuf[DIRECTPERBLOCK] = {
	{ ROOTINODE, "." },
	{ ROOTINODE, ".."}
};
dinode_t inode[DINODESPERBLOCK];

uchar _fmt = 0; 	/* do low level formatting */
uchar _yes = 0; 	/* yes to all questions */
uchar _quick = 0;	/* quick initialization */
uchar _verb = 0;	/* be verbose */

void dwrite __P((uint, void *));
int yes __P((char *));
void mkfs __P((uint, uint,uint));
void doformatting __P((void));

void dwrite(blk, addr)
	uint blk;
	void *addr;
{
	char *buf = bread(dev, blk, 2);

	if (buf == NULL) {
		printf("mkfs: disk is not MS(X)DOS compatible, device or drive error\n");
		xexit(1);
	}
	bcopy(addr, buf, BUFSIZE);
	bfree((bufptr)buf, 2);
}

int yes(p)
	char *p;
{
	char line[20];

	fputs(p,stdout);
	FF;
	if (_yes)
		fputs("Y\n", stdout);
	else if (fgets(line, sizeof(line), stdin) == NULL ||
		 (*line != 'y' && *line != 'Y'))
		return (0);
	return (1);
}

void mkfs(fsize, isize, rsize)
	uint fsize, isize, rsize;
{
	uint j, lm;
	filesys_t fs;
	char zeroed[BUFSIZE];
	char *buf = bread(dev, 0, 0);

	if (buf == NULL) {
		printf("mkfs: disk is not MS(X)DOS compatible, device or drive error\n");
		xexit(1);
	}
	if (_verb) {
		PF("Creating boot block...\n");	FF;
	}
	/* Preserve disk data (number of sectors, format type, etc) */
	for (j = 11; j < 30; j++) bootblock[j] = buf[j];
	/* Preserve other relevant data (we just use first 256 bytes) */
	for (j = 256; j < 512; j++) bootblock[j] = buf[j];
	/* Write new boot block */
	bfree((bufptr)buf, 0);
	bootblock[0x10] = rsize;
	dwrite(0,bootblock);
	/* Zero out the blocks */
	bzero(zeroed, BUFSIZE);
	if (_verb) {
		PF("Initializing inodes, be patient...\n"); FF;
	}
	if (_quick) {
		dwrite(fsize-1,zeroed); 	/* Last block */
		lm = SUPERBLOCK+1+rsize+isize;	/* Super+Reserv+Inodes */
	}
	else	lm = fsize;			/* All blocks of filesys */
	j = 1;
	while (j < lm) {
		if (_verb && j % 9 == 0) {
			PF("Blk #%d\r", j); FF;
		}
		dwrite(j++, zeroed);
	}
	if (_verb) {
		PF("Blk #%d\n",--j); FF;
	}
	/* Initialize the super-block */
	if (_verb) {
		PF("Creating super-block...\n"); FF;
	}
	bzero(&fs,sizeof(fs));
	fs.s_mounted = SMOUNTED;	/* Magic number */
	fs.s_reserv = SUPERBLOCK+1+rsize;
	fs.s_isize = isize;
	fs.s_fsize = fsize;
	fs.s_tinode = DINODESPERBLOCK * isize - 2;
	/* Free each block, building the free list */
	j = fsize - 1;
	while (j > SUPERBLOCK+1+rsize+isize) {
		if (fs.s_nfree == FSFREEBLOCKS) {
			dwrite(j, (char *) &fs.s_nfree);
			fs.s_nfree = 0;
			bzero(fs.s_free,sizeof(fs.s_free));
		}
		fs.s_tfree++;
		fs.s_free[fs.s_nfree++] = j--;
	}
	/* The inodes are already zeroed out */
	/* create the root dir */
	inode[ROOTINODE].i_mode = S_IFDIR | 0755;
	inode[ROOTINODE].i_nlink = 3;
	inode[ROOTINODE].i_size = sizeof(direct_t)*2;
	inode[ROOTINODE].i_addr[0] = SUPERBLOCK+1+rsize+isize;
	/* Reserve reserved inode */
	inode[0].i_nlink = 1;
	inode[0].i_mode = ~0;
	/* Free inodes in first inode block */
	j = ROOTINODE+1;
	while (j < DINODESPERBLOCK) {
		if (fs.s_ninode == FSFREEINODES)
			break;
		fs.s_inode[fs.s_ninode++] = j++;
	}
	dwrite(SUPERBLOCK+1+rsize, inode);
	dwrite(SUPERBLOCK+1+rsize+isize, dirbuf);
	/* Write out super block */
	dwrite(SUPERBLOCK, &fs);
}

void doformatting() {
#ifdef _MSX_DOS
	if (_verb) {
		PF("Low level formatting:\n"); FF;
	}
	asm("	push ix");
	asm("	push iy");
	asm("	ld ix,0147h");		/* FORMAT function (it asks user) */
	asm("	ld iy,(0fcc0h)");	/* ROM BIOS slot */
	asm("	call 001Ch");
	asm("	pop iy");
	asm("	pop ix");
#else
	fprintf(stderr, "Use FORMAT for low level formatting!\n");
#endif
}

void main(argc, argv)
	int argc;
	char *argv[];
{
	uint fsize, isize, rsize = 0, ap = 1;
	uchar *p;

#ifdef _MSX_DOS
	initenv();
#endif
	while (*(p = (uchar *)argv[ap]) == '-') {
		++p;
		++ap;
		--argc;
		while (*p) {
			switch (*p++) {
			case 'y': case 'Y':	_yes = 1;	break;
			case 'f': case 'F':	_fmt = 1;	break;
			case 'q': case 'Q':	_quick = 1;	break;
			case 'v': case 'V':	_verb = 1;	break;
			default:
				fprintf(stderr, "Illegal switch %s\n", p);
				xexit(-1);
			}
		}
	}
	if ((argc < 4) || (argv[ap+0][1] != ':') || !isalpha(argv[ap+0][0])) {
		/* parameters order agree with FSCK */
		fprintf(stderr, "usage: mkfs [-yfqv] d: fsize isize [rsize]\n");
		xexit(-1);
	}
	dev = ((argv[ap+0][0] & 223) - 65);
	fsize = (uint) atoi(argv[ap+1]);
	isize = (uint) atoi(argv[ap+2]);
	if (argc > 4)
		rsize = (uint) atoi(argv[ap+3]);
	if (dev >= 8) {
		fprintf(stderr,"Invalid drive %c:.\n",dev+65);
		xexit(-1);
	}
	if (fsize < 100 || isize >= fsize/30 || rsize > 100) {
		fprintf(stderr,"Bad parameter values\n");
		xexit(-1);
	}
	PF("\nMaking filesystem on drive %c, fsize %u, isize %u, rsize %u. ",
	       dev+65, fsize, isize, rsize); FF;
	if (!yes("Confirm? "))
		xexit(-1);
#ifdef _MSX_DOS
	if (!_yes) {
		PF("Insert disk and press RETURN: ");	FF;
		getchar();
	}
#endif
	PF("\n");
	if (_fmt)
		doformatting();
	bufinit();
	if (d_init() || d_open(dev)) {
		fprintf(stderr, "Can't open device %x",dev);
		xexit(-1);
	}
	mkfs(fsize, isize, rsize);
	d_close(dev);
	bufsync();
	if (_verb)
		PF("Filesystem on drive %c successfully initialized!\n", dev+65);
	exit(0);
}

