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
 Implementation of system calls
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
#include "fcntl.h"
#include "sys\stat.h"
#include "sys\ioctl.h"
#endif
#include "unix.h"
#include "extern.h"

#define ISIZE(ino)	((ino)->c_node.i_size)

/* definitions for 'UDATA' access */
#define UOFFS		(UDATA(u_offset))
#define UBAS		(UDATA(u_base))
#define UCNT		(UDATA(u_count))
#define UERR		(UDATA(u_error))

LCL inoptr rwsetup __P((uchar fd, void *base, uint cnt, uchar rwflag));
#define psize(x)	(uint)ISIZE(x)
#define addoff(x,y)	*(x)+=(y)
#define updoff(x)	of_tab[UDATA(u_files)[x]].o_ptr = UOFFS
LCL void stcpy __P((inoptr ino, struct stat *buf));
LCL inoptr n_creat __P((char *name, bool_t new, mode_t mode));

#ifdef __KERNEL__
/*********************************************
 SYSCALL NONE();
**********************************************/
GBL int sys_NONE(VOID) {
	UERR = ENOSYS;
	return -1;
}
#endif	/* __KERNEL__ */

/****************************************
 SYSCALL sync(void);
***************************************/
GBL int sys_sync(VOID) {
	i_sync();	/* flushing inodes */
	fs_sync();	/* flushing superblocks */
			/* flushing buffers is already done by i_sync/fs_sync */
	return 0;
}

#ifdef NEED__SCALL

/********************************
 SYSCALL utime(char *path, struct utimbuf *buf);
********************************/
#define path (char *)UDATA(u_argn1)
#define buf ((struct utimbuf *)UDATA(u_argn2))
GBL int sys_utime(VOID) {
	struct utimbuf lcl, *bufp = buf;
	register inoptr ino;

	if (path == NULL) {
		UERR = EFAULT;
Err:		return -1;
	}
	if (bufp == NULL) {
		bufp = &lcl;
		rdtime(&bufp->actime);
		bcopy(&bufp->actime, &bufp->modtime, sizeof(time_t));
	}
	if ((ino = namei(path, NULL, 1)) == NULL)
		goto Err;
	if (ino->c_node.i_uid != UDATA(u_euid) && !super()) {
		UERR = EPERM;
		goto Err1;
	}
	if (ino->c_ro) {
		UERR = EROFS;
Err1:		i_deref(ino);
		goto Err;
	}
	bcopy(&bufp->actime, &ino->c_node.i_atime, sizeof(time_t));
	bcopy(&bufp->modtime, &ino->c_node.i_mtime, sizeof(time_t));
	ino->c_dirty=1;
	i_deref(ino);
	return 0;
}
#undef path
#undef buf

/*********************************************
 SYSCALL close(int uindex);
**********************************************/
#define uindex (uint)UDATA(u_argn1)
GBL int sys_close(VOID) {
	return doclose(uindex);
}
#undef uindex

/* truncate the file, if a regular one, to zero length */
LCL void truncateto0(ino)
	inoptr ino;
{
	oft_t *op;

	if (getmode(ino) == S_IFREG) {	/* regular file */
		/* Truncate the regular file to zero length */
		ISIZE(ino) = 0; /* for future use */
		f_trunc(ino);
		/* Reset any oft pointers */
		op = of_tab;
		while (op < of_tab+OFTSIZE) {
			if (op->o_inode == ino)
				op->o_ptr = 0;
			++op;
		}
	}
}

/*******************************************
 SYSCALL open(char *name, int flag, mode_t mode);
********************************************/
#define name (char *)UDATA(u_argn1)
#define flag (int)UDATA(u_argn2)
#define mode UDATA(u_argn3)
GBL int sys_open(VOID) {
	ofptr of;
	off_t *op;
	register inoptr ino;
	register int spf = flag;
	uchar perm, oftindex, uindex;

	if ((flag &= 0xFF) > O_RDWR) {	/* special flags in high byte */
		UERR = EINVAL;
		goto Err1;
	}
	if (spf & O_SYMLINK)
		spf = O_SYMLINK;
	if ((uindex = uf_alloc()) == (uchar)-1 ||	/* user file descriptor */
	    (oftindex = oft_alloc()) == (uchar)-1)	/* system file descriptor */
		goto Err1;
	if ((spf & O_NEW) ||
	    (ino = namei(name, NULL, !(spf & O_SYMLINK))) == NULL) { /* open inode for name */
		if (!(spf & O_CREAT))
			goto Err;
		mode = (S_IFREG | (mode & S_UMASK & ~UDATA(u_mask)));
		UDATA(u_error) = 0;
		if ((ino = n_creat(name, (spf & O_NEW) != 0, mode)) == NULL)
			goto Err;
	}
	of = &of_tab[oftindex];
	of->o_inode = ino;			/* save inode ref */
	perm = getperm(ino);			/* check for permissions */
	if (((((uchar)flag == O_RDONLY) || (uchar)flag == O_RDWR) &&
			!((uchar)perm & S_IOREAD)) ||
	    (((uchar)flag == O_WRONLY || (uchar)flag == O_RDWR) &&
			!((uchar)perm & S_IOWRITE))) {
		UERR = EPERM;
		goto Err;
	}
	if (((uchar)flag == O_WRONLY || (uchar)flag == O_RDWR) &&
			(ino->c_ro)) {
		UERR = EROFS;
		goto Err;
	}
	if ((spf & O_SYMLINK) && getmode(ino) != S_IFLNK) {
		UERR = ESRCH;
		goto Err;
	}
	if (getmode(ino) == S_IFDIR &&		/* directories only for read */
	    flag != O_RDONLY) {
		UERR = EISDIR;
		goto Err;
	}
	if (isdevice(ino) && d_open(DEVNUM(ino)) != 0) {
		UERR = ENXIO;			/* can't access to device */
		goto Err;
	}
	UDATA(u_files)[uindex] = oftindex;	/* user fd */
	op = &(of->o_ptr);
	if (spf & O_APPEND)			/* posit to end of file */
		*op = ino->c_node.i_size;
	else	*op = 0;		/* posit to start of file */
	/* creat must truncate file to 0 if it exists! */
	if ((spf & (O_CREAT|O_TRUNC)) == (O_CREAT|O_TRUNC)) truncateto0(ino);
	of->o_access = flag;
	if (getmode(ino) == S_IFPIPE && of->o_refs == 1)
		psleep(ino);	/* sleep process if no writer of reader */
	return uindex;

Err:	oft_deref(oftindex);	/* This will call i_deref() */
Err1:	return (-1);
}
#undef name
#undef flag
#undef mode

/********************************************
 SYSCALL link(char *oldname, char *newname);
*********************************************/
#define oldname (char *)UDATA(u_argn1)
#define newname (char *)UDATA(u_argn2)
GBL int sys_link(VOID) {
	register inoptr ino, ino2;
	inoptr parent2 = NULL;
	int ret = -1;

	if ((ino = namei(oldname, NULL, 1)) == 0)
		goto Err1;
	if (!(getperm(ino) & S_IOWRITE)) {
		UERR = EPERM;
		goto Err;
	}
	/* Make sure newname doesn't exist, and get its parent */
	if ((ino2 = namei(newname, &parent2, 1)) != NULL) {
		i_deref(ino2);
		UERR = EEXIST;
		goto Err;
	}
	if (parent2 == NULL)	/* even no path */
		goto Err;
	if (ino->c_dev != parent2->c_dev) {
		UERR = EXDEV;	/* inter-device link not allowed */
		goto Err;
	}
	if (ch_link(parent2, "", filename(newname), ino) == 0)
		goto Err;
	/* Update the link count */
	++ino->c_node.i_nlink;
	if (wr_inode(ino) < 0) goto Err;
	setftim(ino, C_TIME);
	ret = 0;
Err:	if (parent2 != NULL)
		i_deref(parent2);
	i_deref(ino);
Err1:	return ret;
}
#undef oldname
#undef newname

/********************************************
 SYSCALL symlink(char *oldname, char *newname);
*********************************************/
#define oldname (char *)UDATA(u_argn1)
#define newname (char *)UDATA(u_argn2)
GBL int sys_symlink(VOID) {
	register inoptr ino = NULL;
	int ret = -1;
	mode_t mode = S_IFREG | (0666 & ~UDATA(u_mask));

	/* Create newname as new IFREG node */
	if ((ino = n_creat(newname, 1, mode)) == NULL)
		goto Ret;
	/* fill in new file */
	UOFFS = 0;	/* don't use a = b = c = 0 ! HTC doesn't like this */
	UCNT = 0;
	UBAS = (uchar *)oldname; /* buf */
	while (*oldname++ != 0)
		UCNT = UCNT+1;	/* nbytes */
	writei(ino);		/* write it */
	/* change mode to LNK */
	ino->c_node.i_mode = (mode & S_UMASK) | S_IFLNK;
	if (wr_inode(ino) < 0) goto Ret;
	ret = 0;
Ret:	if (ino != NULL)	i_deref(ino);
	return ret;
}
#undef oldname
#undef newname

/*******************************************
 SYSCALL unlink(char *path);
********************************************/
#define path (char *)UDATA(u_argn1)
GBL int sys_unlink(VOID) {
	auto inoptr pino;
	register inoptr ino = namei(path, &pino, 0);
	int ret = -1;

	if (pino == NULL || ino == NULL) {
		UERR = ENOENT;
		goto Ret;
	}
	if (!(getperm(ino) & S_IOWRITE)) {
		UERR = EPERM;
		goto Ret;
	}
	/* Remove the directory entry */
	if (ch_link(pino, filename(path), "", NULL) == 0)
		goto Ret;
	/* Decrease the link count of the inode */
	if (ino->c_node.i_nlink-- == 0)
		warning("_unlink: bad nlink %d",ino->c_node.i_nlink += 2);
	setftim(ino, C_TIME);
	ret = 0;
Ret:	if (pino)	i_deref(pino);
	if (ino)	i_deref(ino);
	return ret;
}
#undef path

/**********************************************
 SYSCALL read(int d, char *buf, uint nbytes);
 SYSCALL write(int d, char *buf, uint nbytes);
**********************************************/
#define d (uint)UDATA(u_argn1)
#define buf (void *)UDATA(u_argn2)
#define nbytes (uint)UDATA(u_argn3)
#define isread (UDATA(u_callno) == 23)
GBL int sys_readwrite(VOID) {
	register inoptr ino;

	/* Set up u_base, u_offset, ino; check permissions, file num. */
	if ((ino = rwsetup(d, buf, nbytes, isread)) == NULL)
		return (-1);	/* bomb out if error */
	if (nbytes)
		if (isread) readi(ino); else writei(ino);
	updoff(d);
	return UCNT;
}
#undef d
#undef buf
#undef nbytes

/************************************************
 SYSCALL lseek(int file, long offset, int whence);
************************************************/
#define file (uchar)UDATA(u_argn1)
#define offset *((long *)&UDATA(u_argn2))
#define flag (int)UDATA(u_argn4)
GBL int sys_lseek(VOID) {
	register off_t* offp;
	register inoptr ino;

	if ((ino = getinode(file)) == NULL) {
Err1:		UDATA(u_retval1) = (-1);
		return (-1);
	}
	if (getmode(ino) == S_IFPIPE) {
		UERR = ESPIPE;
		goto Err1;
	}
	offp = &of_tab[UDATA(u_files)[file]].o_ptr;
	switch (flag) {
	case SEEK_SET:	*offp = offset; 		break;
	case SEEK_CUR:	*offp += offset;		break;
	case SEEK_END:	*offp = ISIZE(ino) + offset;	break;
	default:
		UERR = EINVAL;
		goto Err1;
	}
	UDATA(u_retval1) = ((uint *)offp)[1];
	return *(uint *)offp;
}
#undef file
#undef offset
#undef flag

/************************************
 SYSCALL chdir(char *dir);
************************************/
#define dir (char *)UDATA(u_argn1)
GBL int sys_chdir(VOID) {
	register inoptr newcwd;

	if ((newcwd = namei(dir, NULL, 1)) == 0)
Err1:		return (-1);
	if (getmode(newcwd) != S_IFDIR) {
		i_deref(newcwd);
		UERR = ENOTDIR;
		goto Err1;
	}
	if (!(getperm(newcwd) & S_IOEXEC)) {
		UERR = EPERM;
		goto Err1;
	}
	i_deref(UDATA(u_cwd));
	UDATA(u_cwd) = newcwd;
	return 0;
}
#undef dir

/************************************
 SYSCALL chroot(char *dir);
************************************/
#define dir (char *)UDATA(u_argn1)
GBL int sys_chroot(VOID) {
	if (sys_chdir() == 0) {
		i_deref(UDATA(u_root));
		UDATA(u_root) = UDATA(u_cwd);
		i_ref(UDATA(u_root));
		return 0;
	}
	return -1;
}
#undef dir

/*********************************************
 SYSCALL mknod(char *name, mode_t mode, int dev);
*********************************************/
#define name (char *)UDATA(u_argn1)
#define mode (int)UDATA(u_argn2)
#define dev (dev_t)UDATA(u_argn3)
GBL int sys_mknod(VOID) {
	register inoptr ino;

	mode &= ((~UDATA(u_mask) & S_UMASK) | S_IFMT);
	if (S_ISDEV(mode) && !super()) { /* only super able to create devs */
		UERR = EPERM;
Err1:		return -1;
	}
	if ((ino = n_creat(name, 1, mode)) == NULL)
		goto Err1;
	/* Initialize device node */
	if (isdevice(ino)) {
		DEVNUM(ino) = dev;
		ino->c_dirty = 1;
	}
	if (wr_inode(ino) < 0) {
		i_deref(ino);
		goto Err1;
	}
	i_deref(ino);
	return 0;
}
#undef name
#undef mode
#undef dev

/****************************************
 SYSCALL access(char *path, int mode);
****************************************/
#define path (char *)UDATA(u_argn1)
#define mode (int)UDATA(u_argn2)
GBL int sys_access(VOID) {
	register inoptr ino;
	register int retval = -1;
	uchar euid, egid;

	if ((mode &= 07) != 0 && *path == 0) {
		UERR = ENOENT;
		goto Err1;
	}
	/* Temporarily make eff. id real id. */
	euid = UDATA(u_euid);
	egid = UDATA(u_egid);
	UDATA(u_euid) = UDATA(u_ptab)->p_uid;
	UDATA(u_egid) = UDATA(u_gid);

	if ((ino = namei(path, NULL, 1)) == NULL)
		goto Err;
	retval = 0;
	if ((~getperm(ino) & mode) != 0) {
		UERR = EPERM;
		retval = -1;
	}
	i_deref(ino);
Err:	UDATA(u_euid) = euid;
	UDATA(u_egid) = egid;
Err1:	return retval;
}
#undef path
#undef mode

STATIC int chany(char *path, int val1, int val2, bool_t mode) {
	register inoptr ino;

	if ((ino = namei(path, NULL, 1)) == NULL)
		goto Err1;
	if (ino->c_node.i_uid != UDATA(u_euid) && !super()) {
		i_deref(ino);
		UERR = EPERM;
Err1:		return (-1);
	}
	if (mode) {
		/* file class can't be changed */
		ino->c_node.i_mode &= S_IFMT;
		ino->c_node.i_mode = (ino->c_node.i_mode | ((mode_t)val1 & S_UMASK));
	}
	else {
		ino->c_node.i_uid = val1;
		ino->c_node.i_gid = val2;
	}
	setftim(ino, C_TIME);
	i_deref(ino);
	return 0;
}

/*******************************************
 SYSCALL chmod(char *path, mode_t mode);
*******************************************/
#define path (char *)UDATA(u_argn1)
#define mode (mode_t)UDATA(u_argn2)
GBL int sys_chmod(VOID) {
	return chany(path, (int)mode, 0, 1);
}
#undef path
#undef mode

/*************************************************
 SYSCALL chown(char *path, int owner, int group);
*************************************************/
#define path (char *)UDATA(u_argn1)
#define owner (uchar)UDATA(u_argn2)
#define group (uchar)UDATA(u_argn3)
GBL int sys_chown(VOID) {
	return chany(path, owner, group, 0);
}
#undef path
#undef owner
#undef group

/* stcpy() Utility for stat and fstat
 */
LCL void stcpy(ino, buf)
	register inoptr ino;
	register struct stat *buf;
{
	buf->st_dev = ino->c_dev;
	buf->st_ino = ino->c_num;
	buf->st_mode = ino->c_node.i_mode;
	buf->st_nlink = ino->c_node.i_nlink;
	buf->st_uid = ino->c_node.i_uid;
	buf->st_gid = ino->c_node.i_gid;
	buf->st_rdev = DEVNUM(ino);
	bcopy(&ino->c_node.i_size, &buf->st_size, sizeof(off_t));
	bcopy(&ino->c_node.i_atime, &buf->st_atime, 3*sizeof(time_t));
}

/**************************************
 SYSCALL stat(char *path, char *buf);
 SYSCALL fstat(int fd, char *buf);
 **************************************/
#define path (char *)UDATA(u_argn1)
#define fd (uchar)UDATA(u_argn1)
#define buf (char *)UDATA(u_argn2)
#define isstat (UDATA(u_callno) == 27)
GBL int sys_statfstat(VOID) {
	register inoptr ino;

	if (!valadr(buf, sizeof(struct stat))) goto Err;
	if ((ino = isstat ? namei(path, NULL, 1) : getinode(fd)) == 0) {
Err:		return -1;
	}
	stcpy(ino, (struct stat *)buf);
	if (isstat) i_deref(ino);
	return (0);
}
#undef path
#undef buf

/************************************
 SYSCALL dup(int oldd);
************************************/
#define oldd (uchar)UDATA(u_argn1)
GBL int sys_dup(VOID) {
	register uchar newd, oftindex;

	if (getinode(oldd) == NULL ||
	    (newd = uf_alloc()) == (uchar)-1)
		return (-1);
	oftindex = UDATA(u_files)[oldd];
	UDATA(u_files)[newd] = oftindex;
	++of_tab[oftindex].o_refs;
	return newd;
}
#undef oldd

/****************************************
 SYSCALL dup2(int oldd, int newd);
****************************************/
#define oldd (uchar)UDATA(u_argn1)
#define newd (uchar)UDATA(u_argn2)
GBL int sys_dup2(VOID) {
	if (getinode(oldd) == NULL)
		goto Err1;
	if (newd >= UFTSIZE) {
		UERR = EBADF;
Err1:		return (-1);
	}
	if (!freefileentry(UDATA(u_files)[newd]))
		doclose(newd);
	UDATA(u_files)[newd] = UDATA(u_files)[oldd];
	++of_tab[UDATA(u_files)[oldd]].o_refs;
	return 0;
}
#undef oldd
#undef newd

/* Special system call returns pointers to UZIX
 * structures for system dependent utils like df, ps...
 */
/***********************************************
 SYSCALL getfsys(dev_t devno, info_t *buf);
***********************************************/
#define devno ((dev_t)UDATA(u_argn1))
#define buf ((info_t *)UDATA(u_argn2))
GBL int sys_getfsys(VOID) {
	return getfsys(devno, buf);
}
#undef devno
#undef buf

/**********************************************
 SYSCALL ioctl(int fd,int request, void *data);
**********************************************/
#define fd (uchar)UDATA(u_argn1)
#define request (int)UDATA(u_argn2)
#define data (void *)UDATA(u_argn3)
GBL int sys_ioctl(VOID) {
	register inoptr ino;

	if ((ino = getinode(fd)) == NULL)
		UERR = EBADF;
	else if (!isdevice(ino))
		UERR = ENODEV;
	else if ((getperm(ino) & S_IOWRITE) == 0)
		UERR = EPERM;
	else if (!d_ioctl(DEVNUM(ino), request, data))
		return 0;
	return -1;
}
#undef fd
#undef request
#undef data

/**************************************************
 SYSCALL mount(char *spec, char *dir, int rwflag);
 SYSCALL umount(char *spec);
**************************************************/
#define spec (char *)UDATA(u_argn1)
#define dir (char *)UDATA(u_argn2)
#define rwflag (int)UDATA(u_argn3)
#define ismount (UDATA(u_callno) == 19)
GBL int sys_mountumount(VOID) {
	register inoptr sino, dino;
	register dev_t dev;
	int sts = -1;
	fsptr fp;

	if (!super()) {
		UERR = EPERM;
		goto Err1;
	}
	if ((sino = namei(spec, NULL, 1)) == NULL)
		goto Err1;
	if (ismount) if ((dino = namei(dir, NULL, 1)) == 0) {
		i_deref(sino);
		goto Err1;
	}
	if (getmode(sino) != S_IFBLK) {
		UERR = ENOTBLK;
		goto Err;
	}
	if (!ismount) {
		if (!validdev(dev = DEVNUM(sino),NULL)) goto ErrIO;
	} else {
		if (getmode(dino) != S_IFDIR) {
			UERR = ENOTDIR;
			goto Err;
		}
		if (d_open(dev = DEVNUM(sino))) {
ErrIO:			UERR = ENXIO;
			goto Err;
		}
		d_close(dev);	/* fmount will open the device */
	}
	fp = findfs(dev);
	if (!ismount) {
		if (!fp || !fp->s_mounted) {
			UERR = EINVAL;
			goto Err;
		}
		dino = i_tab;
		while (dino < i_tab + ITABSIZE) {
			if (dino->c_refs > 0 && dino->c_dev == dev) {
				goto ErrBusy;
			}
			++dino;
		}
	} else {
		if (fp || dino->c_refs != 1 || dino->c_num == ROOTINODE) {
ErrBusy:		UERR = EBUSY;
			goto Err;
		}
	}
	sys_sync();
	if (!ismount) {
		fp->s_mounted = 0;
		i_deref(fp->s_mntpt);
		sts = 0;
	} else {
		if (!fmount(dev, dino, rwflag))
			sts = 0;
		else	goto ErrBusy;
	}
Err:	if (ismount) i_deref(dino);
	i_deref(sino);
Err1:	return sts;
}
#undef spec
#undef dir
#undef rwflag

/***********************************
 SYSCALL time(time_t *tvec);
***********************************/
#define tvec (time_t *)UDATA(u_argn1)
GBL int sys_time(VOID) {
	rdtime(tvec);
	return 0;
}
#undef tvec

/*======================================================================*/

#ifdef __KERNEL__
/* exit0() - do exit through vector 0 (erroneous jmp to address 0)
 */
GBL void exit0(VOID) {
	doexit(-1, -1);
}
#endif	/* __KERNEL__ */

/* create any kind of node */
LCL inoptr n_creat(name, new, mode)
	char *name;
	bool_t new;
	mode_t mode;
{
	register inoptr ino;
	auto inoptr parent = NULL;

	if ((ino = namei(name, &parent, 1)) != NULL) {
		/* The file already exists */
		if (new) {
			UERR = EEXIST;		/* need new file! */
			goto Err1;
		}
		i_deref(parent);	/* parent not needed */
		if (getmode(ino) == S_IFDIR) {	/* can't rewrite directory */
			UERR = EISDIR;
			goto Err;
		}
		/* must have the write access */
		if ((getperm(ino) & S_IOWRITE) == 0) {
			UERR = EACCES;
			goto Err;
		}
		truncateto0(ino);
	}
	else {	/* must create the new file */
		if (parent == NULL)	/* missing path to file */
			goto Err;
		if ((ino = newfile(parent, name)) == NULL)
		/* Parent was derefed in newfile! */
			goto Err;	/* Doesn't exist and can't make it */
		ino->c_node.i_mode = mode;
		setftim(ino, A_TIME | M_TIME | C_TIME);
		/* The rest of the inode is initialized in newfile() */
		if (_getmode(mode) == S_IFDIR) {
			if (ch_link(ino, "", ".", ino) == 0 ||
			    ch_link(ino, "", "..", parent) == 0)
				goto Err1;
			ino->c_node.i_size = 2*sizeof(direct_t);
			ino->c_node.i_nlink++;
			parent->c_node.i_nlink++;
			parent->c_dirty = 1;
		}
	}
	if (wr_inode(ino) < 0) goto Err;
	return ino;

Err1:	i_deref(parent);
Err:	if (ino)
		i_deref(ino);
	return NULL;
}

/* readwritei() implements reading/writing from/to any kind of inode
 * udata prepared with parameters
 */

GBL void readwritei(write, ino)
	char write;
	register inoptr ino;
{
	register uint amount, todo, ublk, uoff, tdo = 0;
	register char *bp;
	register blkno_t pblk;
	dev_t dev = ino->c_dev;
	bool_t ispipe = 0;

	if (write && ino->c_ro) {
		UERR = EROFS;
		return;
	}
	switch (getmode(ino)) {
	case S_IFCHR:	/* character device */
		UCNT = write ? cdwrite(DEVNUM(ino)) : cdread(DEVNUM(ino));
		if ((int)UCNT != -1)
			addoff(&UOFFS, UCNT);
		return;
	case S_IFLNK:	/* sym link */
		if (write) goto error;
	case S_IFDIR:	/* directory */
	case S_IFREG:	/* regular file */
		todo = UCNT;
		if (!write) {
			/* See if offset is beyond end of file */
			if ((unsigned long)UOFFS >= (unsigned long)ISIZE(ino)) {
				UCNT = 0;
				return;
			}
			/* See if end of file will limit read */
			if (UOFFS + todo > ISIZE(ino))
				todo = (uint)(ISIZE(ino) - UOFFS);
			UCNT = todo;
		}		
		goto loop;
#ifdef __KERNEL__
	case S_IFPIPE:	/* interprocess pipe */
		++ispipe;
		if (write) {	/* write side */
			while ((todo = UCNT) >
			       (DIRECTBLOCKS * BUFSIZE) - psize(ino)) {
				if (ino->c_refs == 1) { /* No readers - broken pipe */
					UCNT = -1;
					UERR = EPIPE;
					ssig(UDATA(u_ptab), SIGPIPE);
					return;
				}
				/* Sleep if full pipe */
				psleep(ino);	/* P_SLEEP */
			}
			goto loop;
		} else {	/* read side */
			while (psize(ino) == 0) {
				if (ino->c_refs == 1)	/* No writers */
					break;
				/* Sleep if empty pipe */
				psleep(ino);		/* P_SLEEP */
			}
			todo = Min(UCNT, psize(ino));
			UCNT = todo;
			goto loop;
		}
#endif	/* __KERNEL__ */
	case S_IFBLK:	/* block device */
		dev = DEVNUM(ino);
		todo = UCNT;
		/* blockdev/directory/regular/pipe */
loop:		while (todo) {
			ublk = (uint)(UOFFS >> BUFSIZELOG);
			uoff = (uint)UOFFS & (BUFSIZE - 1);
			pblk = bmap(ino, ublk, write ? 0 : 1);
			if (!write) {
				bp = (pblk == NULLBLK) ? zerobuf(1): bread(dev, pblk, 0);
				if (bp == NULL) {
					/* EFAULT: for FD, means, out of disk bounds!
					 * it's not really an error. it just means EOF... */
					if (UERR == EFAULT) UERR = 0;
					return;
				}
			}				
			amount = Min(todo, BUFSIZE - uoff);
			if (write) {
				if (pblk == NULLBLK)
					return;	/* No space to make more blocks */
				/* If we are writing an entire block, we don't care
				 * about its previous contents
				 */
				bp = bread(dev, pblk, (amount == BUFSIZE));
				if (bp == NULL) return;
				bcopy(UBAS, bp + uoff, amount); 
				if (bfree((bufptr)bp, 2) < 0) return;
			} else {
				bcopy(bp+uoff, UBAS, amount);
				if (brelse((bufptr)bp) < 0) return;
			}
			UBAS = UBAS + amount;	/* HTC stuff */
			tdo = tdo + amount;
			addoff(&UOFFS, amount);
			todo = todo - amount;
#ifdef __KERNEL__
			if (ispipe) {
				if (ublk >= DIRECTBLOCKS)
					UOFFS &= (BUFSIZE - 1);
				addoff(&(ino->c_node.i_size), write ? amount : -amount);
				/* Wake up any readers/writers */
				wakeup(ino);
			}
#endif	/* __KERNEL__ */
		}
		UCNT = tdo;
		/* Update size if file grew */
		if (write && !ispipe) {
			if (UOFFS > ISIZE(ino)) {
				ISIZE(ino) = UOFFS;
				ino->c_dirty = 1;
			}
		}
		return;
	default:
error:		UERR = ENODEV;
		if (!write) UCNT = -1;
		return;
	}
}

/* rwsetup() prepare udata for read/write file */
LCL inoptr rwsetup(fd, base, cnt, rdflag)
	uchar fd;
	void *base;
	uint cnt;
	uchar rdflag;
{
	register inoptr ino;
	register ofptr oftp;

	if ((ino = getinode(fd)) == NULL)	/* check fd */
Err1:		return NULL;
	oftp = of_tab + UDATA(u_files)[fd];
	if (oftp->o_access == (rdflag ? O_WRONLY : O_RDONLY)) {
		UERR = EACCES;
		goto Err1;
	}
	setftim(ino, rdflag ? A_TIME : (A_TIME | M_TIME));
	/* Initialize u_offset from file pointer */
	UOFFS = oftp->o_ptr;
	UBAS = (uchar *)base;	/* buf */
	UCNT = cnt;		/* nbytes */
	return ino;
}

#ifdef __KERNEL__
#define tmpbuf ((udata_t *)TEMPDBUF)
int pdat(struct s_pdata *ubuf) {
	struct swap_mmread pp;
	register ptptr p = ptab;
#ifdef	PC_HOSTED
	udata_t TEMPDBUF[1];
#endif

	while (p < ptab+PTABSIZE) {
		if (p->p_pid == ubuf->u_pid && p->p_status != P_ZOMBIE) {
			if (p->p_status == P_RUNNING)
				bcopy(UDATA_ADDR, tmpbuf, sizeof(udata_t));
			else {
				pp.mm[0] = p->p_swap[0];
				pp.mm[1] = p->p_swap[1];
				pp.buf = (void *)tmpbuf;
				pp.size = sizeof(udata_t);
				pp.offset = (uint)p->p_udata;
				if (swap_mmread(&pp) < 0) {
					UERR = EIO;
					goto Err;
				}
			}
			ubuf->u_ptab = tmpbuf->u_ptab;
			bcopy(tmpbuf->u_name, ubuf->u_name, DIRNAMELEN);
			ubuf->u_insys = tmpbuf->u_insys;
			ubuf->u_callno = tmpbuf->u_callno;
#if DEBUG > 1
			ubuf->u_traceme = tmpbuf->u_traceme;
#else
			ubuf->u_traceme = 0;
#endif
			ubuf->u_cursig = tmpbuf->u_cursig;
			ubuf->u_euid = tmpbuf->u_euid;
			ubuf->u_egid = tmpbuf->u_egid;
			ubuf->u_gid = tmpbuf->u_gid;
			ubuf->u_uid = p->p_uid;
			ubuf->u_time = tmpbuf->u_time;
			ubuf->u_utime = tmpbuf->u_utime;
			ubuf->u_stime = tmpbuf->u_stime;
			return 0;
		}
		++p;
	}
	UERR = ESRCH;
Err:	return -1;
}
#endif	/* __KERNEL__ */

/* This function is support for getfsys syscall and /dev/kmem */
#define ubuf ((struct s_pdata *)buf)
#define kbuf ((struct s_kdata *)buf)
GBL int getfsys(devno, buf)
	dev_t devno;
	void *buf;
{
	fsptr dev = findfs(devno);
	register void *ptr = dev;
	uchar cnt = 1;

	if (dev == NULL) {
		switch (devno) {
		case GI_FTAB:	cnt = NFS;	ptr = fs_tab;	break;
		case GI_ITAB:	cnt = ITABSIZE; ptr = i_tab;	break;
		case GI_BTAB:	cnt = NBUFS;	ptr = bufpool;	break;
#ifdef __KERNEL__
		case GI_PTAB:	cnt = PTABSIZE; ptr = ptab;	break;
		case GI_UDAT:			ptr = UDATA_ADDR; break;
		case GI_UTAB:		ptr = UDATA(u_ptab);	break;
		case GI_PDAT:	return pdat(ubuf);
		
		case GI_KDAT:	bcopy(UZIX, kbuf->k_name, 14);
				bcopy(VERSION, kbuf->k_version, 8);
				bcopy(RELEASE, kbuf->k_release, 8);
				bcopy(HOST_MACHINE, kbuf->k_machine, 8);
				kbuf->k_tmem = total * 16;
				kbuf->k_kmem = 32;	/* 32k kernel */
				goto Ok;
#endif /* __KERNEL__ */
		default:
			UERR = ENXIO;
			return (-1);
		}
	}
	((info_t *)buf)->size = cnt;
	((info_t *)buf)->ptr = ptr;
Ok:	return 0;
}
#undef tmpbuf
#undef kbuf
#undef ubuf

#endif	/* NEED__SCALL */

