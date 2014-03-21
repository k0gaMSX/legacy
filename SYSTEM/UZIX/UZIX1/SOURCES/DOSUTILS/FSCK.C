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

 Filesystem Check: to check an UZIX disk.
 Usage:	fsck [-y] d:
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
#include ".\include\string.h"
#else
#include <c:\tc\include\stdio.h>
#include <c:\tc\include\stdlib.h>
#include <c:\tc\include\ctype.h>
#include <c:\tc\include\string.h>
#endif

#define MAXDEPTH 33	/* Maximum depth of directory tree to search */
uint depth;

int _yes = 0;

dev_t	dev;
filesys_t filsys;
uint	ninodes;
blkno_t finode;

char	*bitmap;
uchar	*linkmap;

void ckdir __P((uint inum, uint pnum, char *name));
void mkentry __P((uint inum));
blkno_t getblkno __P((dinode_t *ino, blkno_t num));
void setblkno __P((dinode_t *ino, blkno_t num, blkno_t dnum));
blkno_t _blk_alloc __P((filesys_t *filsys));
char *daread __P((uint blk));
void dwrite __P((uint blk, void *addr));
void iread __P((uint ino, dinode_t *buf));
void iwrite __P((uint ino, dinode_t *buf));
void dirread __P((dinode_t *ino, uint j, direct_t *dentry));
void dirwrite __P((dinode_t *ino, uint j, direct_t *dentry));
int da_read __P((dev_t,uint,void *));
int da_write __P((dev_t,uint,void *));
int yes __P((void));

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

/* Pass 1 checks each inode independently for validity, zaps bad block
 * numbers in the inodes, and builds the block allocation map.
 */
void pass1(void) {
	uint n, mode, icount = 0;
	blkno_t b, bn, bno, *buf;
	dinode_t ino;

	n = ROOTINODE;
	while (n < ninodes) {
		iread(n, &ino);
		linkmap[n] = -1;
		if (ino.i_mode == 0)
			goto Cont;
		mode = ino.i_mode & S_IFMT;
		/* Check mode */
		if (mode != S_IFREG &&
		    mode != S_IFDIR &&
		    mode != S_IFLNK &&
		    mode != S_IFBLK &&
		    mode != S_IFCHR) {
			PF("Inode %d with mode 0%o is not of correct type. Zap? ",
			       n, ino.i_mode);
			if (yes()) {
				ino.i_mode = 0;
				ino.i_nlink = 0;
				iwrite(n, &ino);
				goto Cont;
			}
		}
		linkmap[n] = 0;
		++icount;
		/* Check blocks and build free block map */
		if (mode == S_IFREG || mode == S_IFDIR || mode == S_IFLNK) {
			/* Check singly indirect blocks */
			b = DIRECTBLOCKS;
			while (b <= DIRECTBLOCKS+INDIRECTBLOCKS) {
				bno = ino.i_addr[b];
				if (bno != 0 &&
				    (bno < finode ||
				     bno >= filsys.s_fsize)) {
					PF("Inode %d singly indirect "
					       "block %d is out of range "
					       "with value of %u. Zap? ",
					       n, b, bno);
					if (yes()) {
						ino.i_addr[b] = 0;
						iwrite(n, &ino);
					}
				}
				if (bno != 0 &&
				    (uint)(ino.i_size >> BUFSIZELOG) < DIRECTBLOCKS) {
					PF("Inode %d singly indirect block "
					       "%d is past end of file with "
					       "value of %u. Zap? ",
					       n, b, bno);
					if (yes()) {
						ino.i_addr[b] = 0;
						iwrite(n, &ino);
					}
				}
				if (bno != 0)
					bitmap[bno/8] |= 1 << (bno%8);
				++b;
			}
			/* Check the double indirect blocks */
			if (ino.i_addr[DIRECTBLOCKS+INDIRECTBLOCKS] != 0) {
				buf = (blkno_t *) daread(ino.i_addr[19]);
				b = 0;
				while (b < BUFSIZE/sizeof(blkno_t)) {
					bno = buf[n];
					if (bno != 0 &&
					    (bno < finode ||
					     bno >= filsys.s_fsize)) {
						PF("Inode %d doubly indirect "
						       "block %d is out of range "
						       "with value of %u. Zap? ",
						       n, b, bno);
						if (yes()) {
							buf[b] = 0;
							dwrite(b, (char *) buf);
						}
					}
					if (bno != 0)
						bitmap[bno/8] |= 1 << (bno%8);
					++b;
				}
			}
			/* Check the rest */
			b = 0;
			bn = (uint)(ino.i_size >> BUFSIZELOG);
			while (b <= bn) {
				bno = getblkno(&ino, b);
				if (bno != 0 &&
				    (bno < finode || bno >= filsys.s_fsize)) {
					PF("Inode %d block %d is out of "
					       "range with value of %u. Zap? ",
					       n, b, bno);
					if (yes()) {
						setblkno(&ino, b, 0);
						iwrite(n, &ino);
					}
				}
				if (bno != 0)
					bitmap[bno/8] |= 1 << (bno%8);
				++b;
			}
		}
Cont:		++n;
	}
	/* Fix free inode count in super block */
	b = ninodes - ROOTINODE - icount;
	if (filsys.s_tinode != b) {
		PF("Free inode count in super block is %u should be %u. Fix? ",
			filsys.s_tinode, b);
		if (yes()) {
			filsys.s_tinode = b;
			dwrite((blkno_t)1, (char *) &filsys);
		}
	}
}

/* Clear inode free list, rebuild block free list using bit map. */
void pass2(void) {
	blkno_t j, oldtfree = filsys.s_tfree;

	PF("        Rebuild free list? ");
	if (!yes())
		return;
	/* Initialize the super-block */
	filsys.s_ninode = 0;
	filsys.s_nfree = 1;
	filsys.s_free[0] = 0;
	filsys.s_tfree = 0;
	/* Free each block, building the free list */
	j = filsys.s_fsize - 1;
	while (j >= finode+filsys.s_isize) {
		if ((bitmap[j/8] & (1 << (j%8))) == 0) {
			if (filsys.s_nfree == FSFREEBLOCKS) {
				dwrite(j, (char *) &filsys.s_nfree);
				filsys.s_nfree = 0;
			}
			filsys.s_free[filsys.s_nfree] = j;
			++filsys.s_nfree;
			++filsys.s_tfree;
		}
		--j;
	}
	dwrite(SUPERBLOCK, (char *) &filsys);
	if (oldtfree != filsys.s_tfree) {
		PF("During free list regeneration s_tfree "
		       "was changed to %d from %d.\n",
			filsys.s_tfree, oldtfree);
		FF;
	}
}

/* Pass 3 finds and fixes multiply allocated blocks. */
void pass3(void) {
	uint n, mode;
	dinode_t ino;
	blkno_t b, bn, bno,newno;

	b = finode;
	while (b < filsys.s_fsize) {
		bitmap[b/8] &= ~(1 << (b%8));
		b++;
	}
	n = ROOTINODE;
	while (n < ninodes) {
		iread(n, &ino);
		mode = ino.i_mode & S_IFMT;
		if (mode != S_IFREG && mode != S_IFDIR && mode != S_IFLNK)
			goto Cont;
		/* Check singly indirect blocks */
		b = DIRECTBLOCKS;
		while (b <= DIRECTBLOCKS+INDIRECTBLOCKS) {
			bno = ino.i_addr[b];
			if (bno != 0) {
				if ((bitmap[bno/8] & (1 << (bno%8))) != 0) {
					PF("Indirect block %d in inode %u "
					       "value %u multiply allocated. "
					       "Fix? ", b, n, bno);
					if (yes()) {
						newno = _blk_alloc(&filsys);
						if (newno == 0) {
							PF("Sorry... "
							 "No more free blocks.\n");
							FF;
						}
						else {
							dwrite(newno,daread(bno));
							ino.i_addr[b] = newno;
							iwrite(n, &ino);
						}
					}
				}
				else	bitmap[bno/8] |= 1 << (bno%8);
			}
			++b;
		}
		/* Check the rest */
		b = 0;
		bn = (uint)(ino.i_size >> BUFSIZELOG);
		while (b <= bn) {
			bno = getblkno(&ino, b);
			if (bno == 0)
				goto Cont1;
			if ((bitmap[bno/8] & (1 << (bno%8))) != 0) {
				PF("Block %d in inode %u value %u "
				       "multiply allocated. Fix? ",
				       b, n, bno);
				if (yes()) {
					newno = _blk_alloc(&filsys);
					if (newno == 0) {
						PF("Sorry... "
						  "No more free blocks.\n");
						FF;
					}
					else {
						dwrite(newno, daread(bno));
						setblkno(&ino, b, newno);
						iwrite(n, &ino);
					}
				}
			}
			else	bitmap[bno/8] |= 1 << (bno%8);
Cont1:			++b;
		}
Cont:		++n;
	}
}

/* This recursively checks the directories */
void ckdir(inum, pnum, name)
	uint inum;
	uint pnum;
	char *name;
{
	dinode_t ino;
	direct_t dentry;
	uint j, i, nentries;
	char ename[150];

	iread(inum, &ino);
	if ((ino.i_mode & S_IFMT) != S_IFDIR)
		return;
	++depth;
	i = (uint)(ino.i_size) % sizeof(direct_t);
	if (i != 0) {
		PF("Directory inode %d has improper length (%d extra). Fix? ",
			inum, i);
		if (yes()) {
			ino.i_size &= ~(sizeof(direct_t) - 1);
			iwrite(inum, &ino);
		}
	}
	nentries = (uint)(ino.i_size / sizeof(direct_t));
	j = 0;
	while (j < nentries) {
		dirread(&ino, j, &dentry);
		if (dentry.d_ino == 0)
			goto Cont;
		if (dentry.d_ino < ROOTINODE ||
		    dentry.d_ino >= 8 * filsys.s_isize) {
			PF("Directory entry %s%-1.14s has out-of-range "
				"inode %u. Zap? ",
				name, dentry.d_name, dentry.d_ino);
			if (yes()) {
				dentry.d_ino = 0;
				dentry.d_name[0] = '\0';
				dirwrite(&ino, j, &dentry);
				goto Cont;
			}
		}
		if (dentry.d_ino && linkmap[dentry.d_ino] == (uchar)-1) {
			PF("Directory entry %s|%s points to "
				"bogus inode %u. Zap? ",
				name, dentry.d_name, dentry.d_ino);
			if (yes()) {
				dentry.d_ino = 0;
				dentry.d_name[0] = '\0';
				dirwrite(&ino, j, &dentry);
				goto Cont;
			}
		}
		if (linkmap[dentry.d_ino]++ == 254) {
			fprintf(stderr, "More than 254 links to inode %u.\n"
				"Not enough memory. FSCK aborted.\n",
				dentry.d_ino);
			xexit(1);
		}
		i = 0;
		while (i < DIRNAMELEN && dentry.d_name[i]) {
			if (dentry.d_name[i] == '/') {
				PF("Directory entry %s%-1.14s "
					"contains slash. Fix? ",
					name, dentry.d_name);
				if (yes()) {
					dentry.d_name[i] = '~';
					dirwrite(&ino, j, &dentry);
				}
			}
			++i;
		}
		if (strcmp((char *)dentry.d_name, ".") == 0 &&
		    dentry.d_ino != inum) {
			PF("'.' entry %s%-1.*s points to wrong place. Fix? ",
			       name, DIRNAMELEN, dentry.d_name);
			if (yes()) {
				dentry.d_ino = inum;
				dirwrite(&ino, j, &dentry);
			}
		}
		if (strcmp((char *)dentry.d_name, "..") == 0 &&
		    dentry.d_ino != pnum) {
			PF("'..' entry %s%-1.*s points to wrong place. Fix? ",
			       name, DIRNAMELEN, dentry.d_name);
			if (yes()) {
				dentry.d_ino = pnum;
				dirwrite(&ino, j, &dentry);
			}
		}
		if (dentry.d_ino != pnum &&
		    dentry.d_ino != inum &&
		    depth < MAXDEPTH) {
			strcpy(ename, name);
			strcat(ename, (char *)dentry.d_name);
			strcat(ename, "/");
			ckdir(dentry.d_ino, inum, ename);
		}
Cont:		++j;
	}
	--depth;
}

/* Pass 4 traverses the directory tree, fixing bad directory entries
 * and finding the actual number of references to each inode.
 */
void pass4(void) {
	depth = 0;
	linkmap[ROOTINODE] = 1;
	ckdir(ROOTINODE, ROOTINODE, "/");
	if (depth != 0)
		panic("Inconsistent depth");
}

/* This makes an entry in "lost+found" for inode n */
void mkentry(inum)
	uint inum;
{
	dinode_t rootino;
	direct_t dentry;
	uint d, ne;

	iread(ROOTINODE, &rootino);
	d = 0;
	ne = (uint)(rootino.i_size / sizeof(direct_t));
	while (d < ne) {
		dirread(&rootino, d, &dentry);
		if (dentry.d_ino == 0 && dentry.d_name[0] == '\0') {
			dentry.d_ino = inum;
			sprintf(dentry.d_name, "l_f%d", inum);
			dirwrite(&rootino, d, &dentry);
			return;
		}
		++d;
	}
	PF("Sorry... No empty slots in root directory.\n"); FF;
}

/* Pass 5 compares the link counts found in pass 4 with the inodes. */
void pass5(void) {
	uint n;
	dinode_t ino;

	n = ROOTINODE;
	while (n < ninodes) {
		iread(n, &ino);
		if (ino.i_mode == 0) {
			if (linkmap[n] != (uchar)-1)
				panic("Inconsistent linkmap");
			goto Cont;
		}
		if (linkmap[n] == (uchar)-1 && ino.i_mode != 0)
			panic("Inconsistent linkmap");
		if (linkmap[n] != (uchar)-1 && ino.i_nlink != linkmap[n]) {
			PF("Inode %d has link count %d should be %d. Fix? ",
			       n, ino.i_nlink, linkmap[n]);
			if (yes()) {
				ino.i_nlink = linkmap[n];
				iwrite(n, &ino);
			}
		}
		if (linkmap[n] == 0) {
			if (S_ISBLK(ino.i_mode) ||
			    S_ISCHR(ino.i_mode) ||
			    ino.i_size == 0) {
				PF("Useless inode %d with mode 0%o has "
				       "become detached. Link count is %d. Zap? ",
				       n, ino.i_mode, ino.i_nlink);
				if (yes()) {
					ino.i_nlink = 0;
					ino.i_mode = 0;
					iwrite(n, &ino);
					++filsys.s_tinode;
					dwrite(SUPERBLOCK, (char *) &filsys);
				}
			}
			else {
				PF("Inode %d has become detached. "
					"Link count is %d. Fix? ",
					n, ino.i_nlink);
				if (yes()) {
					ino.i_nlink = 1;
					iwrite(n, &ino);
					mkentry(n);
				}
			}
		}
Cont:		++n;
	}
}

/* Getblkno gets a pointer index, and a number of a block in the file.
 * It returns the number of the block on the disk.  A value of zero
 * means an unallocated block.
 */
blkno_t getblkno(ino, num)
	dinode_t *ino;
	blkno_t num;
{
	blkno_t indb;
	blkno_t dindb;
	blkno_t *buf;

	if (num < DIRECTBLOCKS) /* Direct block */
		return (ino->i_addr[num]);
	if (num < DIRECTBLOCKS + BUFSIZE/sizeof(blkno_t)) {	/* Single indirect */
		indb = ino->i_addr[DIRECTBLOCKS];
		if (indb == 0)
			return (0);
		buf = (blkno_t *) daread(indb);
		return (buf[num - DIRECTBLOCKS]);
	}
	/* Double indirect */
	indb = ino->i_addr[DIRECTBLOCKS+INDIRECTBLOCKS];
	if (indb == 0)
		return (0);
	buf = (blkno_t *) daread(indb);
	indb = (num - DIRECTPERBLOCK + BUFSIZE/sizeof(blkno_t));
	dindb = buf[indb >> 8];
	buf = (blkno_t *) daread(dindb);
	return (buf[indb & 0xFF]);
}

/* Setblkno sets the given block number of the given file to the given
 * disk block number, possibly creating or modifiying the indirect blocks.
 * A return of zero means there were no blocks available to create an
 * indirect block. This should never happen in fsck.
 */
void setblkno(ino, num, dnum)
	dinode_t *ino;
	blkno_t num;
	blkno_t dnum;
{
	blkno_t indb;
	blkno_t dindb;
	blkno_t *buf;

	if (num < DIRECTBLOCKS) /* Direct block */
		ino->i_addr[num] = dnum;
	else if (num < DIRECTBLOCKS + BUFSIZE/sizeof(blkno_t)) {	/* Single indirect */
		indb = ino->i_addr[DIRECTBLOCKS];
		if (indb == 0)
			panic("Missing indirect block");
		buf = (blkno_t *) daread(indb);
		buf[num - DIRECTBLOCKS] = dnum;
		dwrite(indb, (char *) buf);
	}
	else {			/* Double indirect */
		indb = ino->i_addr[DIRECTBLOCKS+INDIRECTBLOCKS];
		if (indb == 0)
			panic("Missing indirect block");
		buf = (blkno_t *) daread(indb);
		num -= DIRECTBLOCKS + BUFSIZE/sizeof(blkno_t);
		dindb = buf[num >> 8];
		if (dindb == 0)
			panic("Missing indirect block");
		buf = (blkno_t *) daread(dindb);
		buf[num & 0xFF] = num;
		dwrite(indb, buf);
	}
}

/* Blk_alloc allocates an unused block.
 * A returned block number of zero means no more blocks.
 */
blkno_t _blk_alloc(filsys)
	filesys_t *filsys;
{
	uint j;
	blkno_t *buf;
	blkno_t newno = filsys->s_free[--filsys->s_nfree];

	if (newno == 0) {
		++filsys->s_nfree;
		return (0);
	}
	/* See if we must refill the s_free array */
	if (filsys->s_nfree == 0) {
		buf = (blkno_t *) daread(newno);
		filsys->s_nfree = buf[0];
		j = 0;
		while (j < FSFREEBLOCKS) {
			filsys->s_free[j] = buf[j + 1];
			++j;
		}
	}
	--filsys->s_tfree;
	if (newno < finode || newno >= filsys->s_fsize) {
		PF("Free list is corrupt.  Did you rebuild it?\n");
		return (0);
	}
	dwrite(SUPERBLOCK, filsys);
	return (newno);
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

void iread(ino, buf)
	uint ino;
	dinode_t *buf;
{
	dinode_t *addr = (dinode_t *)daread((ino>>DINODESPERBLOCKLOG)+finode);

	bcopy(&addr[ino & (DINODESPERBLOCK-1)], buf, sizeof(dinode_t));
}

void iwrite(ino, buf)
	uint	ino;
	dinode_t *buf;
{
	dinode_t *addr = (dinode_t *)daread((ino>>DINODESPERBLOCKLOG)+finode);

	bcopy(buf, &addr[ino & (DINODESPERBLOCK-1)], sizeof(dinode_t));
	dwrite((ino >> DINODESPERBLOCKLOG) + finode, addr);
}

void dirread(ino, j, dentry)
	dinode_t *ino;
	uint j;
	direct_t *dentry;
{
	direct_t *buf;
	blkno_t blkno = getblkno(ino, (blkno_t) j / DIRECTPERBLOCK);

	if (blkno == 0)
		panic("Missing block in directory");
	buf = (direct_t *)daread(blkno);
	bcopy(buf+j % DIRECTPERBLOCK, dentry, sizeof(direct_t));
}

void dirwrite(ino, j, dentry)
	dinode_t *ino;
	uint j;
	direct_t *dentry;
{
	direct_t *buf;
	blkno_t blkno = getblkno(ino, (blkno_t) j / DIRECTPERBLOCK);

	if (blkno == 0)
		panic("Missing block in directory");
	buf = (direct_t *)daread(blkno);
	bcopy(dentry, buf+j % DIRECTPERBLOCK, sizeof(direct_t));
	dwrite(blkno, buf);
}

int yes(void) {
	char line[20];

	FF;
	if (_yes)
		PF("Y\n");
	else if (!fgets(line, sizeof(line), stdin) ||
		 (*line != 'y' && *line != 'Y'))
		return (0);
	return (1);
}

void main(argc, argv)
	int argc;
	char *argv[];
{
	char *buf, *p = argv[1];

#ifdef _MSX_DOS
	initenv();
#endif
	if (--argc > 0 && *p == '-') {
		if (p[1] != 'y' && p[1] != 'Y') {
			fprintf(stderr, "Illegal switch %s\n", p);
			xexit(-1);
		}
		++_yes;
		p = argv[2];
		--argc;
	}
	if ((argc != 1) || (p[1] != ':') || !isalpha(*p)) {
		fprintf(stderr,"usage: fsck [-y] d:\n");
		xexit(-1);
	}
	dev = ((*p & 223) - 65);
	if (dev >= 8) {
		fprintf(stderr,"Invalid drive %c.\n",dev+65);
		xexit(-1);
	}
#ifdef _MSX_DOS
	if (!_yes) {
		PF("Insert disk and press RETURN: "); FF;
		getchar();
	}
#endif
	bufinit();
	if (d_init() || d_open(dev)) {
		fprintf(stderr,"Can't open device number %x\n", dev);
		xexit(-1);
	}
	/* Read in the super block. */
	buf = daread(SUPERBLOCK);
	bcopy(buf, &filsys, sizeof(filesys_t));
	/* Verify the fsize and isize parameters */
	if (filsys.s_mounted != SMOUNTED) {
		PF("Device %x has invalid magic number %d. Fix? ",
		       dev, filsys.s_mounted);
		if (!yes())
			xexit(-1);
		filsys.s_mounted = SMOUNTED;
		dwrite(SUPERBLOCK, &filsys);
	}
	PF("Checking drive %c with fsize %u, isize %u, rsize %u. Confirm? ",
	       dev+65, filsys.s_fsize, filsys.s_isize,
	       filsys.s_reserv-1-SUPERBLOCK);
	if (!yes())
		xexit(-1);
	bitmap = calloc(((filsys.s_fsize / 8) + 1), sizeof(char));
	ninodes = DINODESPERBLOCK * filsys.s_isize;
	finode = filsys.s_reserv;
	linkmap = (uchar *) calloc(ninodes, sizeof(char));
	if (!bitmap) {
		p="bitmap";
		goto nomem;
	}
	if (!linkmap) {
		p="linkmap";
nomem:		fprintf(stderr,"Not enough memory for %s.\n", p);
		xexit(-1);
	}
	bfill(bitmap, 0, (filsys.s_fsize / 8) + 1);
	bfill(linkmap, 0, ninodes * sizeof(char));
	PF("\nPass 1: Checking inodes.\n");		FF; pass1();
	PF("Pass 2: Rebuilding free list.\n");		FF; pass2();
	PF("Pass 3: Checking block allocation.\n");	FF; pass3();
	PF("Pass 4: Checking directory entries.\n");	FF; pass4();
	PF("Pass 5: Checking link counts.\n");		FF; pass5();
	bufsync();
	d_close(dev);
	PF("Done.\n");
	exit(0);
}

