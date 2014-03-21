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
 Filesystem related routines
**********************************************************/

#define NEED__DEVIO
#define NEED__FILESYS
#define NEED__MACHDEP
#define NEED__PROCESS
#define NEED__SCALL

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#include "errno.h"
#include "sys\stat.h"
#endif
#include "unix.h"
#include "extern.h"

LCL inoptr _namei __P((uchar *name, uchar **rest, inoptr strt, inoptr *parent));
LCL fsptr getfs __P((dev_t devno));

/* Common messages. They are here to save memory */
static char *badinomsg = "%s: bad inode number %u";
char *baddevmsg = "%s: bad dev %d";
static char *badfsmsg = "%s: fs of dev %p marked as bad";
static char *refstoinode = "%s refs to inode %p";
static char *gtinobadoft = "getinode: bad oft %u%s %u";

/* Returns true if the magic number of a superblock is ok ??? not used */
#define gooddev(dev)		((dev)->s_mounted == SMOUNTED)

#define blockinodes(blk)	((blk) << DINODESPERBLOCKLOG)
#define devinodes(dev)		blockinodes((dev)->s_isize)
#define inodeblock(dev,ino)	(((ino) >> DINODESPERBLOCKLOG) + (dev)->s_reserv)
#define inodeoffset(ino)	((ino) & DINODESPERBLOCKMASK)

/* Check the given device number, and return its address in the mount table.
 */
GBL fsptr findfs(devno)
	dev_t devno;
{
	register fsptr dev = fs_tab;

	while (dev != fs_tab + NFS) {
		if (dev->s_mounted != 0 && dev->s_dev == devno)
			return dev;
		++dev;
	}
	return NULL;
}

/* Check the given device number, and return its address in the mount table.
 * Also time-stamp the superblock of dev, and mark it modified.
 * Used when freeing and allocating blocks and inodes.
 */
LCL fsptr getfs(devno)
	register dev_t devno;
{
	fsptr dev = findfs(devno);

	if (dev == NULL)
		panic(baddevmsg, "getfs", devno);
	rdtime(&dev->s_time);	/* timestamp */
	dev->s_fmod = 1;	/* mark modified */
	return dev;
}

/* Wr_inode() writes out the given inode in the inode table out to disk,
 * and resets its dirty bit.
 * Attention! Immediate writing may be delayed by dirty_mask!
 */
GBL int wr_inode(ino)
	register inoptr ino;
{
	dinode_t *buf;

	magic(ino);
	if (ino->c_dirty && !ino->c_ro) {
		if ((buf = (dinode_t *)bread(ino->c_dev, 
			inodeblock(findfs(ino->c_dev), 
			ino->c_num), 0)) == NULL)
Err:			return -1;
		bcopy(&ino->c_node,&buf[inodeoffset(ino->c_num)], sizeof(dinode_t));
		if (bfree((bufptr)buf, 2) < 0)	/* write immediately ! */
			goto Err;
	}
	ino->c_dirty = 0;	/* unmark modif flag */
	return 0;
}

/* I_ref() increases the reference count of the given inode table entry.
 */
GBL void i_ref(ino)
	register inoptr ino;
{
	magic(ino);
	if (++ino->c_refs >= 12 * ITABSIZE) /* Arbitrary limit */
		panic(refstoinode, "too many", ino);
}

/* I_deref() decreases the reference count of an inode, and frees it
 * from the table if there are no more references to it.  If it also
 * has no links, the inode itself and its blocks (if not a device) are freed.
 */
GBL void i_deref(ino)
	register inoptr ino;
{
	magic(ino);
	if (ino->c_refs == 0)
		panic(refstoinode, "no", ino);
	if (getmode(ino) == S_IFPIPE)
		wakeup(ino);
	/* If the inode has no links and no refs,
	 * it must have its blocks freed.
	 */
	if (--ino->c_refs == 0) {
		if (ino->c_node.i_nlink == 0) {
			ino->c_node.i_size = 0;
			f_trunc(ino);
			/* and also freeing this inode */
			ino->c_node.i_mode = 0;
			i_free(ino->c_dev, ino->c_num);
		}
		/* If the inode was modified, we must write it back to disk. */
		if (ino->c_dirty)
			wr_inode(ino);
	}
}

/* I_free() is given a device and inode number, and frees the inode.
 * It is assumed that there are no references to the inode in the
 * inode table or in the filesystem.
 */
GBL void i_free(devno, ino)
	dev_t devno;
	ino_t ino;
{
	register fsptr dev = getfs(devno);

	if (ino <= ROOTINODE || ino >= devinodes(dev))
		panic(badinomsg, "i_free", ino);
	++dev->s_tinode;	/* total free inodes */
	/* account to free inodes list if it's possible */
	if (dev->s_ninode < FSFREEINODES)
		dev->s_inode[dev->s_ninode++] = ino;
}

/* _namei() is given a string containing a path name,
 * and returns an inode table pointer.
 * If it returns NULL, the file did not exist.
 * If the parent existed, 'parent' will be filled in with the
 * parents inoptr. Otherwise, 'parent' will be set to NULL.
 */
LCL inoptr _namei(name, rest, strt, parent)
	uchar *name, **rest;
	inoptr strt, *parent;
{
	inoptr temp;
	register inoptr ninode; /* next dir */
	register inoptr wd;	/* the directory we are currently searching. */

	ninode = wd = strt;
	i_ref(wd);
	i_ref(ninode);
	for (;;) {
		if (ninode != NULL) {
			magic(ninode);
			/* See if we are at a mount point */
			ninode = srch_mt(ninode);
		}
		while (*name == '/')	/* Skip (possibly repeated) slashes */
			++name;
		if (*name == 0) 	/* No more components of path? */
			break;
		if (ninode == NULL) {	/* path not found */
			UDATA(u_error) = ENOENT;
			goto Err;
		}
		if (getmode(ninode) == S_IFLNK)
			break;		/* symlinks processed separately */
		i_deref(wd);		/* drop current dir */
		wd = ninode;		/* switch to next inode */
		/* this node must be directory ... */
		if (getmode(wd) != S_IFDIR) {
			UDATA(u_error) = ENOTDIR;
			goto Err;
		}
		/* ... enabled for searching */
		if ((getperm(wd) & S_IOEXEC) == 0) {
			UDATA(u_error) = EPERM;
			goto Err;
		}
		/* See if we are going up through a mount point */
		if (wd->c_num == ROOTINODE &&
		    wd->c_dev != root_dev &&
		    name[1] == '.') {
			/* switch to other fsys */
			temp = findfs(wd->c_dev)->s_mntpt;
			i_deref(wd);
			i_ref(wd = temp);
		}
		/* search for next part of path */
		if ((ninode = srch_dir(wd, (char *)name)) == (inoptr)-1)
			goto Err;
		while (*name != 0 && *name != '/')
			++name; 	/* skip this part */
	}
	*parent = wd;			/* store ref to parent */
	*rest = name;
	return ninode;

Err:	*parent = NULL;
	i_deref(wd);
	return NULL;
}

/* namei() is given a string containing a path name,
 * and returns an inode table pointer.
 * If it returns NULL, the file did not exist.
 * If the parent existed, and 'parent' is not null, 'parent'
 * will be filled in with the parents inoptr.
 * Otherwise, 'parent' will be set to NULL.
 * If 'follow' is false then tail symlink is not opened
 */
GBL inoptr namei(name, parent, follow)
	char *name;
	inoptr *parent;
	uchar follow;
{
	register inoptr ino;
	inoptr parent1, strt;
	uchar *buf = NULL, *buf1 = NULL, *rest, *s;
	uchar cnt = 0;

	UDATA(u_error) = 0;
	if (name == NULL) {
		UDATA(u_error) = ENOENT;
		return NULL;
	}
	strt = (*name == '/') ? UDATA(u_root) : UDATA(u_cwd);
	while ((ino = _namei((uchar *)name, &rest, strt, &parent1)) != NULL) {
		if (getmode(ino) != S_IFLNK || (*rest == 0 && !follow)) {
			if (parent != NULL)
				*parent = parent1;
			else	i_deref(parent1);
			goto Ret;
		}
		/* check symlink is readable */
		if (!(getperm(ino) & S_IOREAD)) {
			UDATA(u_error) = EPERM;
Err:			i_deref(parent1);
			i_deref(ino);
			ino = NULL;
			goto Ret;
		}
		if (!buf) if ((buf = zerobuf(1)) == NULL) goto Err1;
		if (*rest) {	/* need the temporary buffer */
			if (!buf1)	buf1 = zerobuf(0);
			if (!buf1) {
Err1:				UDATA(u_error) = ENOMEM;
				goto Ret;
			}
			s = buf1;
			while ('\0' != (*s++ = *rest++))
				;
			rest = buf1;
		}
		else	rest = (uchar *)"";	/* ! It's important - really "" ! */
		/* readin symlink contents */
		UDATA(u_count) = BUFSIZE;
		UDATA(u_base) = (uchar *)buf;
		UDATA(u_offset) = 0;
		readi(ino);
		/* check for buffer size */
		s = rest;
		while (*s++ != '\0')
			;
		if (UDATA(u_count) + (s - rest) >= BUFSIZE-1) {
			UDATA(u_error) = ENOMEM;
			goto Err;
		}
		/* create substituted name */
		s = buf+UDATA(u_count);
		if (*rest)
			*s++ = '/';
		while ((*s++ = *rest++) != '\0')
			;
		name = (char *)buf;
		strt = (*name == '/') ? root_ino : parent1;
		if (++cnt == 13) {	/* recursion too deep */
			UDATA(u_error) = ELOOP;
			goto Err;
		}
		i_deref(parent1);
		i_deref(ino);
	}
	/* name not found (ino == NULL) */
	if (parent != NULL)
		*parent = parent1;	/* store ref to parent */
	else {	/* we wont existent file! */
		if (parent1)
			i_deref(parent1); /* deref node */
		if (UDATA(u_error) == 0) UDATA(u_error) = ENOENT;
	}
Ret:	if (buf) if (brelse((bufptr)buf) < 0) ino=NULL;
	if (buf1) if (brelse((bufptr)buf1) < 0) ino=NULL;
	return ino;
}

/* Srch_dir() is given a inode pointer of an open directory and a string
 * containing a filename, and searches the directory for the file.
 * If it exists, it opens it and returns the inode pointer, otherwise NULL.
 * If an error occur, Srch_dir() returns -1.
 *
 * This depends on the fact that bread will return unallocated blocks as
 * zero-filled, and a partially allocated block will be padded with zeroes.
 */
GBL inoptr srch_dir(wd, name)
	register inoptr wd;
	char *name;
{
	ino_t ino;
	blkno_t db;
	uint cb, ce, nblocks;
	register direct_t *bp, *buf;

	nblocks = (uint)(wd->c_node.i_size >> BUFSIZELOG); /* # of full blocks */
	if ((uint)wd->c_node.i_size & (BUFSIZE-1))
		++nblocks;			/* and part of last block */
	cb = 0;
	while (cb != nblocks) {
		/* map file block to fs */
		if ((db = bmap(wd, cb, 1)) == NULLBLK)
			break;
		if ((buf = bp = (direct_t *)bread(wd->c_dev, db, 0)) == NULL)
Err1:			return (inoptr)-1;
		ce = 0;
		while (ce < DIRECTPERBLOCK) {
			if (namecomp((uchar *)name, bp->d_name)) {
				/* file name found */
				ino = bp->d_ino; /* inode of file */
				if (brelse((bufptr)buf) < 0) goto Err1;
				/* open the found file */
				return i_open(wd->c_dev, ino);
			}
			++ce;
			++bp;
		}
		if (brelse((bufptr)buf) < 0)	/* need next block */
			goto Err1;
		++cb;
	}
	/* file not found in this directory */
	return NULL;
}

/* Srch_mt() sees if the given inode is a mount point.
 * If so it dereferences it, and references and returns a pointer
 * to the root of the mounted filesystem.
 */
GBL inoptr srch_mt(ino)
	inoptr ino;
{
	register fsptr dev = fs_tab;

	while (dev != fs_tab + NFS) {
		if (dev->s_mounted != 0 && dev->s_mntpt == ino) {
			i_deref(ino);
			ino = i_open(dev->s_dev, ROOTINODE);
			/* return replaced inode */
			break;
		}
		++dev;
	}
	return ino;
}

/* I_open() is given an inode number and a device number, and makes an entry
 * in the inode table for them, or increases it reference count if it is
 * already there.
 *
 * An inode == NULLINO means a newly allocated inode.
 */
GBL inoptr i_open(devno, ino)
	dev_t devno;
	register ino_t ino;
{
	fsptr dev;
	dinode_t *buf;
	inoptr ip, nindex;
	uchar i, newn, mode0;
	static inoptr nexti = i_tab;	/* rover ptr */

	if ((dev = findfs(devno)) == NULL)
		panic(baddevmsg, "i_open", devno);
	newn = 0;
	if (ino == NULLINO) {		/* Wanted a new one */
		if ((ino = i_alloc(devno)) == NULLINO)
			goto Err;	/* errno is already set by i_alloc */
		++newn;
	}
	if (ino < ROOTINODE || ino >= devinodes(dev)) {
		warning(badinomsg, "i_open", ino);
		goto Err;
	}
	/* search inode table for available entry */
	nindex = NULL;
	i = 0;
	ip = nexti;
	while (i != ITABSIZE) {
		nexti = ip;
		if (++ip >= i_tab + ITABSIZE)
			ip = i_tab;
		if (ip->c_refs == 0)
			nindex = ip;	/* candidate for discarding */
		if (ip->c_dev == devno && ip->c_num == ino) {
			nindex = ip;
			goto found;	/* really found */
		}
		++i;
	}
	/* Not already in table - take last candidate */
	if (nindex == NULL) {	/* No unrefed slots in inode table */
		UDATA(u_error) = ENFILE;
		goto Err;
	}
	/* discard oldest? inode from table and read the inode from disk */
	buf = (dinode_t *)bread(devno, inodeblock(dev, ino), 0);
	if (buf == NULL) goto Err;
	bcopy(&buf[inodeoffset(ino)], &nindex->c_node, sizeof(dinode_t));
	if (brelse((bufptr)buf) < 0) goto Err;
	/* fill-in in-core parts of inode */
	nindex->c_magic = CMAGIC;
	nindex->c_dev = devno;
	nindex->c_num = ino;
	nindex->c_ro = dev->s_ronly;
found:	mode0 = (getmode(nindex) == 0);
	if (newn) {	/* RO fs can't do i_alloc()! */
		/* newly allocated disk inode must be clean */
		if (nindex->c_node.i_nlink || !mode0)
			goto badino;
	}	/* and vice versa */
	else if (nindex->c_node.i_nlink == 0 || mode0)
		goto badino;
	i_ref(nindex);		/* yet one ref */
	return nindex;

badino: warning(badinomsg, "i_open (disk)", nindex);
Err:	return NULL;
}

/* Ch_link() modifies or makes a new entry in the directory for the name
 * and inode pointer given. The directory is searched for oldname.
 * When found, it is changed to newname, and it inode # is that of *nindex.
 *
 * An empty oldname ("") matches a unused slot.
 * A nindex NULL means an inode #0.
 *
 * A return status of 0 means there was no space left in the filesystem,
 * or a non-empty oldname was not found, or the user did not have write
 * permission.
 */
GBL int ch_link(wd, oldname, newname, nindex)
	register inoptr wd;
	char *oldname;
	char *newname;
	inoptr nindex;
{
	direct_t curentry;
	int i;

	/* Need the write permissions */
	if ((getperm(wd) & S_IOWRITE) == 0) {
		UDATA(u_error) = EPERM;
		goto Err;
	}
	/* Search the directory for the desired slot */
	UDATA(u_offset) = 0;	/* from beginning */
	for (;;) {
		UDATA(u_base) = (uchar *)&curentry;
		UDATA(u_count) = sizeof(curentry);
		readi(wd);
		/* Read until EOF or name is found */
		/* readi() advances UDATA(u_offset) */
		if (UDATA(u_count) == 0 ||
		    namecomp((uchar *)oldname, curentry.d_name))
			break;
	}
	if (UDATA(u_count) == 0 && *oldname)
		goto Err;	/* Rename and old entry not found */
	oldname = (char *)curentry.d_name;
	i = sizeof(curentry.d_name);
	while (--i >= 0) {
		if ('\0' != (*oldname++ = *newname))
			++newname;
	}
	curentry.d_ino = nindex ? nindex->c_num : 0;
	/* If an existing slot is being used,
	 * we must back up the file offset
	 */
	if (UDATA(u_count) > 0)
		UDATA(u_offset) -= UDATA(u_count);
	UDATA(u_base) = (uchar *)&curentry;
	UDATA(u_count) = sizeof(curentry);
	UDATA(u_error) = 0;
	writei(wd);	/* write back updated directory */
	if (UDATA(u_error))
Err:		return 0;
	/* Update directory length to next block - simple way to extend dir */
	if ((uint)wd->c_node.i_size & (BUFSIZE-1)) {
		wd->c_node.i_size &= ~(BUFSIZE-1);
		wd->c_node.i_size += BUFSIZE;
	}
	setftim(wd, A_TIME | M_TIME | C_TIME); /* And sets c_dirty */
	return 1;
}

/* Filename() is given a path name, and returns a pointer
 * to the final component of it.
 */
GBL char *filename(path)
	char *path;
{
	register char *ptr = path;

	while (*ptr)		/* find end of pathname */
		++ptr;
	while (*ptr != '/' && ptr >= path)
		--ptr;		/* traverse back */
	return (ptr + 1);
}

/* Namecomp() compares two strings to see if they are the same file name.
 * It stops at DIRNAMELEN chars or a null or a slash.
 * It returns 0 for difference.
 */
int namecomp(n1, n2)
	register uchar *n1;
	register uchar *n2;
{
	uchar n = DIRNAMELEN;

	while (*n1 && *n1 != '/') {
		if (*n1++ != *n2++)
			goto NotEq;
		if (--n == 0)
			return (-1);	/* first name too long - ignore this */
	}
	if (*n2 == '\0' || *n2 == '/')
		return 1;		/* names matched */
NotEq:	return 0;
}

/* Newfile() is given a pointer to a directory and a name, and
 * creates an entry in the directory for the name, dereferences
 * the parent, and returns a pointer to the new inode.
 *
 * It allocates an inode number, and creates a new entry in the inode
 * table for the new file, and initializes the inode table entry for
 * the new file.  The new file will have one reference, and 0 links to it.
 *
 * Better make sure there isn't already an entry with the same name.
 */
GBL inoptr newfile(pino, name)
	inoptr pino;
	char *name;
{
	register inoptr nindex;
	if ((getperm(pino) & S_IOWRITE) == 0) {
		UDATA(u_error) = EPERM;
		return 0;
	}
	if ((nindex = i_open(pino->c_dev, NULLINO)) == NULL)
		goto Ret;			/* can't create new inode */
	/* fill-in new inode */
	bzero(&nindex->c_node,sizeof(dinode_t));
	nindex->c_node.i_mode = S_IFREG;	/* For the time being */
	nindex->c_node.i_nlink = 1;
	nindex->c_node.i_uid = UDATA(u_euid);	/* File owner */
	nindex->c_node.i_gid = UDATA(u_egid);
	nindex->c_dirty = 1;
	wr_inode(nindex);
	if (ch_link(pino, "", filename(name), nindex) == 0) {
		i_deref(nindex);	/* can't enter new file to directory */
		nindex = NULL;
	}
Ret:	i_deref(pino);
	return nindex;
}

/* doclose() given the file descriptor and close them */
GBL int doclose(fd)
	uchar fd;
{
	register inoptr ino = getinode(fd);
	uchar oftindex;
	
	if (ino == NULL)
		return (-1);
	oftindex = UDATA(u_files)[fd];
	if (isdevice(ino)
	    && ino->c_refs == 1
	    && of_tab[oftindex].o_refs == 1)
		d_close(DEVNUM(ino));
	UDATA(u_files)[fd] = -1;
	oft_deref(oftindex);
	return 0;
}

/* I_alloc() finds an unused inode number, and returns it,
 * or NULLINO if there are no more inodes available.
 */
GBL ino_t i_alloc(devno)
	dev_t devno;
{
	ino_t ino;
	blkno_t blk;
	register uchar j, k;
	dinode_t *buf, *bp;
	fsptr dev = getfs(devno);

	if (dev->s_ronly) {
		UDATA(u_error) = EROFS;
		goto Err1;
	}
Again:	if (dev->s_ninode) {	/* there are available inodes in list */
		if (dev->s_tinode == 0)
			goto Corrupt; /* fs is not corrup, just full! shouldn't be "goto Err"? */
		/* get free inode from list */
		ino = dev->s_inode[--dev->s_ninode];
		if (ino <= ROOTINODE || ino >= devinodes(dev))
			goto Corrupt;
		--dev->s_tinode;
		return ino;
	}
	/* There are no avilable inodes in list - we must scan the
	 * disk inodes, and fill up the table
	 */
	sys_sync();	/* Make on-disk inodes consistent */
	k = 0;
	blk = 0;
	while (blk != dev->s_isize) {
		if ((bp = buf = (dinode_t *)bread(devno, blk+dev->s_reserv, 0)) == NULL)
			goto Err;
		j = 0;
		while (j != DINODESPERBLOCK) {
			if (bp->i_mode == 0 && bp->i_nlink == 0)
				dev->s_inode[k++] = blockinodes(blk) + j;
			if (k == FSFREEINODES) {
				if (brelse((bufptr)buf) < 0) goto Err;
				goto Done;
			}
			++bp;
			++j;
		}
		++blk;
		if (brelse((bufptr)buf) < 0) goto Err;
		if (k >= DINODESPERBLOCK-2)		/* ??? */
			break;
	}
Done:	if (k == 0) {	/* no free inodes on disk */
		if (dev->s_tinode)
			goto Corrupt;
		goto Err;
	}
	dev->s_ninode = k;
	goto Again;

Corrupt:warning(badfsmsg, "i_alloc", devno);
	dev->s_mounted = ~SMOUNTED;	/* mark device as bad */
Err:	UDATA(u_error) = ENOSPC;
Err1:	return NULLINO;
}

/* Blk_alloc() is given a device number, and allocates an unused block
 * from it. A returned block number of zero means no more blocks.
 */
GBL blkno_t blk_alloc(devno)
	dev_t devno;
{
	count_t nf;
	blkno_t *buf, newno;
	register fsptr dev = getfs(devno);

	if (dev->s_ronly) {
		UDATA(u_error) = EROFS;
		goto Err1;
	}
	nf = dev->s_nfree;
	if (nf <= 0 || nf > FSFREEBLOCKS) goto Corrupt;
	if (0 == (newno = dev->s_free[--dev->s_nfree])) {
		if (dev->s_tfree != 0)
			goto Corrupt;
		++dev->s_nfree;
		goto Err;
	}
	/* See if we must refill the s_free array */
	if (dev->s_nfree == 0) {
		if ((buf = (blkno_t *)bread(devno, newno, 0)) == NULL)
			goto Err;
		dev->s_nfree = buf[0];
		bcopy(buf+1,dev->s_free,sizeof(dev->s_free));
		if (brelse((bufptr)buf) < 0)
			goto Err;
	}
	validblk(devno, newno);
	if (dev->s_tfree == 0)
		goto Corrupt;
	--dev->s_tfree;
	/* Zero out the new block */
	if ((buf = (blkno_t *)bread(devno, newno, 2)) == NULL) 	/* 2 for zeroing */
		goto Err;
	if (bawrite((bufptr)buf) < 0)				/* write back */
		goto Err;
	return newno;

Corrupt:warning(badfsmsg, "blk_alloc", devno);
	dev->s_mounted = ~SMOUNTED;
Err:	UDATA(u_error) = ENOSPC;
Err1:	return 0;
}

/* Blk_free() is given a device number and a block number,
 * and frees the block.
 */
GBL void blk_free(devno, blk)
	dev_t devno;
	blkno_t blk;
{
	blkno_t *buf;
	register fsptr dev = getfs(devno);

	if (dev->s_ronly || blk == 0)
End:		return;
	validblk(devno, blk);
	/* flushing overflowed free blocks list  */
	if (dev->s_nfree == FSFREEBLOCKS) {
		buf = bread(devno, blk, 1);
		if ((buf) == NULL)
			goto End;
		buf[0] = dev->s_nfree;
		bcopy(dev->s_free, buf+1, sizeof(dev->s_free));
		if (bawrite((bufptr)buf) < 0) goto End;
		dev->s_nfree = 0;
	}
	++dev->s_tfree;
	dev->s_free[dev->s_nfree++] = blk;
}

/* Oft_alloc() allocate entries in the open file table.
 */
GBL uchar oft_alloc(VOID) {
	register ofptr op = of_tab;
	uchar j = 0;

	while (j != OFTSIZE) {
		if (op->o_refs == 0) {
			bzero(op, sizeof(oft_t)); /* zero out all fields */
			op->o_refs++;
			return j;
		}
		++op;
		++j;
	}
	UDATA(u_error) = ENFILE;
	return (-1);
}

/* Oft_deref() dereference (and possibly free attached inode)
 * entries in the open file table.
 */
GBL void oft_deref(of)
	uchar of;
{
	register ofptr op = of_tab + of;

	if (--op->o_refs == 0 && op->o_inode != NULL) {
		i_deref(op->o_inode);
		op->o_inode = NULL;
	}
}

/* Uf_alloc() finds an unused slot in the user file table.
 */
GBL uchar uf_alloc(VOID) {
	register uchar j = 0;
	register uchar *p = UDATA(u_files);

	while (j != UFTSIZE) {
		if (freefileentry(*p))
			return j;
		++p;
		++j;
	}
	UDATA(u_error) = ENFILE;
	return (-1);
}

/* isdevice() returns true if ino points to a device
 * !!! assume S_IFBLK == S_IFCHR|any
 */
GBL uchar isdevice(ino)
	inoptr ino;
{
	return (ino->c_node.i_mode & S_IFCHR) != 0;
}

/* Freeblk() - free (possible recursive for (double)inderect) block
 */
GBL void freeblk(dev, blk, level)
	dev_t dev;
	blkno_t blk;
	uchar level;
{
	if (blk != 0) {
		if (level != 0) {	/* INDERECT/DINDERECT block */
			register blkno_t *buf = (blkno_t *)bread(dev, blk, 0);
			uint j;

			--level;
			if ((buf) != NULL) {
				j = BUFSIZE/sizeof(blkno_t);
				while (j != 0)
					freeblk(dev, buf[--j], level);
				brelse((bufptr)buf);
			}
		}
		blk_free(dev, blk);
	}
}

/* F_trunc() frees all the blocks associated with the file,
 * if it is a disk file.
 * need enhancement for truncating to given size
 */
GBL void f_trunc(ino)
	register inoptr ino;
{
	dinode_t *ip = &ino->c_node;
	blkno_t *blk = ip->i_addr;
	register uchar j;

	/* First deallocate the double indirect blocks */
	freeblk(ino->c_dev, blk[TOTALREFBLOCKS-1], 2);
	/* Also deallocate the indirect blocks */
	freeblk(ino->c_dev, blk[TOTALREFBLOCKS-1-DINDIRECTBLOCKS], 1);
	/* Finally, free the direct blocks */
	j = 0;
	while (j != DIRECTBLOCKS) {
		freeblk(ino->c_dev, *blk++, 0);
		++j;
	}
	bzero(ip->i_addr, sizeof(blkno_t)*TOTALREFBLOCKS);
	ino->c_dirty = 1;
	ip->i_size = 0;
}

/* Bmap() defines the structure of file system storage by returning the
 * physical block number on a device given the inode and the logical
 * block number in a file.
 *
 * The block is zeroed if created.
 */
GBL blkno_t bmap(ip, bn, rdflg)
	inoptr ip;
	register blkno_t bn;
	uchar rdflg;
{
	dev_t dev;
	register uint i, j, sh;
	register blkno_t *bp, nb;

	if (isdevice(ip))	/* block devices */
		return bn;	/* map directly */
	dev = ip->c_dev;
	/* blocks 0..DIRECTBLOCKS-1 are direct blocks */
	if (bn < DIRECTBLOCKS) {
		bp = &ip->c_node.i_addr[bn];
		if (0 == (nb = *bp)) {
			/* block not allocated yet */
			if (rdflg || (nb = blk_alloc(dev)) == 0)
				goto Err;
			*bp = nb;
			ip->c_dirty = 1;
		}
		goto Ok;
	}
	/* addresses DIRECTBLOCKS and DIRECTBLOCKS+1 have single and double
	 * indirect blocks.
	 * The first step is to determine how many levels of indirection.
	 */
	bn -= DIRECTBLOCKS;
	sh = 0;
	j = INDIRECTBLOCKS+DINDIRECTBLOCKS;
	if (bn >= BUFSIZE/sizeof(blkno_t)) {	/* double indirect */
		sh = 8; 			/* shift by 8 */
		bn -= BUFSIZE/sizeof(blkno_t);
		j -= INDIRECTBLOCKS;
	}
	/* fetch the address from the inode.
	 * Create the first indirect block if needed.
	 */
	bp = &ip->c_node.i_addr[TOTALREFBLOCKS - j];
	if ((nb = *bp) == 0) {
		if (rdflg || 0 == (nb = blk_alloc(dev)))
			goto Err;
		*bp = nb;
		ip->c_dirty = 1;
	}
	/* fetch through the indirect blocks */
	while (j <= INDIRECTBLOCKS+DINDIRECTBLOCKS) {
		if ((bp = (blkno_t *)bread(dev, nb, 0)) == NULL)
Err:			return NULLBLK;
		i = (bn >> sh) & (BUFSIZE/sizeof(blkno_t)-1);
		if ((nb = bp[i]) != 0) {
			if (brelse((bufptr)bp) < 0) 
				goto Err;
		} else {
			if (rdflg || 0 == (nb = blk_alloc(dev))) {
				brelse((bufptr)bp);
				goto Err;
			}
			bp[i] = nb;
			if (bawrite((bufptr)bp) < 0)
				goto Err;
		}
		sh -= 8;
		++j;
	}
Ok:	return nb;
}

/* Validblk() panics if the given block number is not a valid data block
 * for the given device.
 */
GBL void validblk(devno, num)
	dev_t devno;
	blkno_t num;
{
	register fsptr dev = findfs(devno);

	if (dev == NULL)
		panic("validblk: dev %p not mounted",dev);
	if (num < dev->s_isize + dev->s_reserv || num >= dev->s_fsize)
		panic("validblk: invalid block %u", num);
}

/* Getinode() returns the inode pointer associated with a user's
 * file descriptor, checking for valid data structures
 */
GBL inoptr getinode(uindex)
	uchar uindex;
{
	register inoptr inoindex;
	uchar oftindex = UDATA(u_files)[uindex];

	if (uindex >= UFTSIZE || freefileentry(oftindex)) {
		UDATA(u_error) = EBADF;
		return (NULL);
	}
	if (oftindex >= OFTSIZE)
		panic(gtinobadoft, oftindex, " for", uindex);
	if ((inoindex = of_tab[oftindex].o_inode) < i_tab ||
	    inoindex >= i_tab + ITABSIZE)
		panic(gtinobadoft, oftindex, ", inode", inoindex);
	magic(inoindex);
	return inoindex;
}

/* Getperm() looks at the given inode and the effective user/group ids, and
 * returns the effective permissions in the low-order 3 bits.
 */
GBL int getperm(ino)
	inoptr ino;
{
	mode_t mode = ino->c_node.i_mode;

	if (super())
		mode |= S_ISDEV(mode) ? (mode >> 3) | (mode >> 6) : 07;
	else {
		if (ino->c_node.i_uid == UDATA(u_euid))	mode >>= 6; /* owner */
		else if (ino->c_node.i_gid == UDATA(u_egid)) mode >>= 3; /* group */
	}
	return (mode & 07);
}

/* Setftim() sets the times of the given inode, according to the flags
 */
GBL void setftim(ino, flag)
	register inoptr ino;
	register uchar flag;
{
	static time_t t;

	rdtime(&t);
	if (flag & A_TIME)	ino->c_node.i_atime = t;
	if (flag & M_TIME)	ino->c_node.i_mtime = t;
	if (flag & C_TIME)	ino->c_node.i_ctime = t;
	ino->c_dirty = 1;
}

/* Fmount() places the given device in the mount table with mount point ino
 */
GBL int fmount(dev, ino, roflag)
	dev_t dev;
	inoptr ino;
	bool_t roflag;
{
	char *buf;
	register fsptr fp = fs_tab;

	if (!validdev(dev,NULL)) {
		UDATA(u_error) = ENODEV;
		goto Err1;	/* ENODEV */
	}
	if (MAJOR(dev) >= BLK_DEVS)
		goto Err;
	/* Lookup free slot in mounted fs table */
	while (fp != fs_tab+NFS) {
		if (fp->s_dev == dev && fp->s_mounted != 0) {
			UDATA(u_error) = EBUSY;
			goto Err1;
		}
		++fp;
	}
	while (fp != fs_tab) {
		--fp;
		if (fp->s_mounted == 0)
			goto Ok;
	}
	UDATA(u_error) = ENOMEM;
	goto Err1;
	/* temporarly lock the slot */
Ok:	fp->s_mounted = ~SMOUNTED;
	fp->s_dev = dev;
	if (d_open(dev) != 0)
		panic("fmount: can't open fs on %p", dev);
	/* read in superblock */
	buf = bread(dev, SUPERBLOCK, 0);
	if (buf == NULL) goto Err1;
	bcopy(buf, fp, sizeof(filesys_t));
	/* fill-in in-core fields */
	fp->s_ronly = roflag;
	fp->s_dev = dev;
	fp->s_fmod = 0;
	if (brelse((bufptr)buf) < 0) goto Err1;
	/* See if there really is a filesystem on the device */
	if (fp->s_mounted != SMOUNTED || fp->s_isize >= fp->s_fsize) {
		fp->s_mounted = 0;	/* free fs table entry */
Err:		UDATA(u_error) = ENOTBLK;
Err1:		return (-1);
	}
	if ((fp->s_mntpt = ino) != NULL)
		i_ref(ino);
	return 0;
}

/* magic() check inode against corruption
 */
GBL void magic(ino)
	inoptr ino;
{
	if (ino->c_magic != CMAGIC)
		panic("corrupted inode %p",ino);
}

/* i_sync() syncing all inodes
 */
GBL void i_sync(VOID) {
	register inoptr ino = i_tab;

	/* Write out modified inodes */
	++dirty_mask;
	while (ino != i_tab + ITABSIZE) {
		if (ino->c_magic == CMAGIC &&
		    ino->c_dirty != 0 && 
		    ino->c_refs > 0)
			wr_inode(ino);
		++ino;
	}
	bufsync();
}

/* fs_sync() syncing all superblocks
 */
GBL void fs_sync(VOID) {
	register fsptr fp = fs_tab;
	register bufptr buf;
	
	/* Write out modified super blocks
	 * This fills the rest of the super block with zeros
	 */
	while (fp != fs_tab+NFS) {
		if (fp->s_mounted && fp->s_fmod) {
			if ((buf = bread(fp->s_dev, SUPERBLOCK, 2)) != NULL) {
				fp->s_fmod = 0;
				bcopy(fp, buf, sizeof(*fp));
				if (bfree(buf, 1) < 0) fp->s_fmod = 1;
			}
		}
		++fp;
	}
	bufsync();
}

