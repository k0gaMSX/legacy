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
 UZIX structure and main definitions
**********************************************************/

#ifndef __UNIX_H
#define __UNIX_H

#ifndef SEPH
#include "types.h"
#include "signal.h"
#include "errno.h"
#include "fcntl.h"
#include "stat.h"
#include "ioctl.h"
#endif

#ifndef DEBUG
#define DEBUG 0
#endif

#define UZIXBASE	(unsigned)0x8000	/* start of UZIX code */
#define _UZIXBASE	8000h	/* start of UZIX code for ASM */
#define PROGBASE	0x100	/* Executable's load base */
#define SYSCADDR	8	/* System call routine */
				/* Changed to 0008h to allow BDOSEMU */
#define EXITADDR	0	/* System exit routine */

#define MAXSWAP 	1024	/* maximal memory to use for swap */
#ifdef MSX_HOSTED
#define MEMBANKING		/* MSX has memory banking hardware */
#else
#undef	MEMBANKING		/* i86 has no memory banking hardware */
#endif

#define MEM_DEV

/* ITABSIZE should be at least 7 to allow piping. A lower value causes
   piping to block. */

#if DEBUG > 1
#define UFTSIZE 	5	/* Number of per user files */
#define OFTSIZE 	10	/* Open file table size */
#define ITABSIZE	8	/* Inode table size */
#define PTABSIZE	5	/* Process table size */
#define NBUFS		(4-1)	/* Number of block buffers */
#else	/* DEBUG > 1 */
#ifdef MSX_HOSTED
#ifdef UZIX_MODULE
#define UFTSIZE 	9	/* Number of per user files */
#define OFTSIZE 	(14-4)	/* Open file table size */
#define ITABSIZE	7	/* Inode table size */
#define PTABSIZE	7	/* Process table size */
#define MTABSIZE	2	/* Module table size */
#define RTABSIZE	3	/* Module reply table size */
#define NBUFS		2	/* Number of block buffers */
#else	/* UZIX_MODULE */
#define UFTSIZE 	10	/* Number of per user files */
#define OFTSIZE 	15	/* Open file table size */
#define ITABSIZE	8	/* Inode table size */
#define PTABSIZE	6	/* Process table size */
#define NBUFS		2	/* Number of block buffers */
#endif	/* UZIX_MODULE */
#undef	MEM_DEV
#else	/* MSX_HOSTED */
#ifdef NEED__SCALL
#define UFTSIZE 	20	/* Number of per user files */
#define OFTSIZE 	40	/* Open file table size */
#define ITABSIZE	20	/* Inode table size */
#define PTABSIZE	0	/* Process table size */
#define NBUFS		10	/* Number of block buffers */
#else	/* NEED__SCALL */
#define UFTSIZE 	0	/* Number of per user files */
#define OFTSIZE 	0	/* Open file table size */
#define ITABSIZE	20	/* Inode table size */
#define PTABSIZE	0	/* Process table size */
#define NBUFS		10	/* Number of block buffers */
#endif	/* NEED_SCALL */
#endif	/* MSX_HOSTED */
#endif	/* DEBUG > 1 */

#define NSIGS		16	/* Number of signals <= 16 */

#ifdef PC_HOSTED
#define TMPSTK		400	/* size of tmp stack. the bigger, the better. */
#else
#if DEBUG > 1
#define TMPSTK		300-50	/* for MSX */
#endif
#endif

#define SUPERBLOCK	1	/* disk block of filesystem superblock */
#define ROOTINODE	1	/* Inode # of / for all mounted filesystems */

#ifdef PC_HOSTED
#define EMAGIC		0xE9	/* Header of executable - jmp near ptr ... */
#else
#define EMAGIC		0xC3	/* Header of Z80-executable: jp ...  */
#endif
#define CMAGIC		31415	/* Random number for cinode c_magic */
#define SMOUNTED	19638	/* Magic number to specify mounted filesystem */

typedef uchar page_t;	/* swap page definition */

/* file-system related data types */
typedef uint ino_t;	/* Can have 65536 inodes in fs */
typedef uint blkno_t;	/* Can have 65536 BUFSIZE-byte blocks in fs */
typedef uint dev_t;	/* Device number */

#define MINOR(dev)		((uchar)(dev))
#define MAJOR(dev)		((uchar)((dev) >> 8))
#define MKDEV(major, minor)	(((uint)(uchar)(major) << 8) | (uchar)(minor))

#define NULLINO ((ino_t)0)
#define NULLBLK ((blkno_t)-1)
#define NULLDEV ((dev_t)-1)

/* executable file header */
typedef struct s_exec {
	uchar	e_magic;	/* magic value (jmp near ptr ) */
	int	e_jump; 		/* */
	uchar	e_flags;	/* executable flags */
				/* bit 7: 1-not refresh system vectors on swapin() */
				/* bit 6: 1-process is a module */
	uint	e_text; 	/* end of text */
	uint	e_data; 	/* end of data */
	uint	e_bss;		/* end of bss */
	uint	e_heap; 	/* needed heap len */
	uint	e_stack;	/* needed stack len */
	uint	e_dummy;	/* undefined now */
} exec_t, *exeptr;

/* input/output queue for character devices */
typedef struct s_queue {
	uchar	*q_base;	/* Pointer to data buffer */
	uchar	*q_head;	/* Pointer to addr of next char to read. */
	uchar	*q_tail;	/* Pointer to where next char to insert goes. */
	uint	q_size; 	/* Max size of queue */
	uint	q_count;	/* How many characters presently in queue */
	uint	q_wakeup;	/* Threshold for waking up procs waiting on queue */
} queue_t;

/* Flags for setftime() */
#define A_TIME	1		/* set access time */
#define M_TIME	2		/* set modify time */
#define C_TIME	4		/* set creation time */

typedef struct s_blkbuf {
	uchar	bf_data[BUFSIZE]; /* This MUST BE first ! */
	dev_t	bf_dev; 	/* device of this block */
	blkno_t bf_blk; 	/* and block number on device */
	uchar	bf_dirty;	/* buffer changed flag */
	uchar	bf_busy;	/* buffer processing in progress */
	uchar	bf_prio;	/* buffer must be in memory (for wargs) */
	uint	bf_time;	/* LRU time stamp */
/*	struct s_blkbuf *bf_next;  /* LRU free list pointer */
} blkbuf_t, *bufptr;

#define DIRECTBLOCKS	18
#define INDIRECTBLOCKS	1	/* MUST BE 1! */
#define DINDIRECTBLOCKS 1	/* MUST BE 1! */
#define TOTALREFBLOCKS	(DIRECTBLOCKS+2)

/* Device-resident inode structure */
typedef struct s_dinode {
	mode_t	i_mode; 	/* file mode */
	uint	i_nlink;	/* number of links to file */
	uchar	i_uid, i_gid;	/* file owner */
	off_t	i_size; 	/* file size */
	time_t	i_atime;	/* last access time */
	time_t	i_mtime;	/* last modification time */
	time_t	i_ctime;	/* file creation time */
	blkno_t i_addr[DIRECTBLOCKS+INDIRECTBLOCKS+DINDIRECTBLOCKS];
#if TOTALREFBLOCKS < 21
	blkno_t i_dummy[21-TOTALREFBLOCKS];
#endif
} dinode_t;	/* Exactly 64 bytes long! See DINODESPERBLOCK below */

#define DINODESPERBLOCK 	8	/* # of dinode_t per logical block */
#define DINODESPERBLOCKLOG	3	/* log2(DINODESPERBLOCK) */
#define DINODESPERBLOCKMASK	((1<<DINODESPERBLOCKLOG)-1)

#define DEVNUM(ino)	((dev_t)((ino)->c_node.i_addr[0]))

/* Getmode() returns the inode kind */
#define _getmode(mode)	((mode) & S_IFMT)
#define getmode(ino)	(_getmode((ino)->c_node.i_mode))
/* Super() returns true if we are the superuser */
#define super() 	(UDATA(u_euid) == 0)

/* in-core inode structure */
typedef struct s_cinode {
	uint	c_magic;	/* Used to check for corruption */
	uchar	c_dirty;	/* Modified flag */
	dev_t	c_dev;		/* Inode's device */
	ino_t	c_num;		/* Inode's number */
	uint	c_refs; 	/* In-core reference count */
	bool_t	c_ro;		/* Read-only filesystem flag */
	dinode_t c_node;	/* disk inode copy */
} cinode_t, *inoptr;

#define DIRECTPERBLOCK	(BUFSIZE/sizeof(direct_t))

#define FSFREEBLOCKS	50
#define FSFREEINODES	50

/* device-resident super-block */
typedef struct s_filesys {
	uint	s_mounted;	/* signature */
	uint	s_reserv;	/* # of first block of inodes */
	uint	s_isize;	/* # of inode's blocks */
	uint	s_fsize;	/* # of data's blocks */

	blkno_t s_tfree;	/* total free blocks */
	uint	s_nfree;	/* # of free blocks in s_free */
	blkno_t s_free[FSFREEBLOCKS];	/* #s of free block's */

	ino_t	s_tinode;	/* total free inodes */
	uint	s_ninode;	/* # of free inodes in s_inode */
	ino_t	s_inode[FSFREEINODES];	/* #s of free inodes */

	time_t	s_time; 	/* last modification timestamp */

/* Core-resident part */
	bool_t	s_fmod; 	/* filesystem modified */
	bool_t	s_ronly;	/* readonly filesystem */
	inoptr	s_mntpt;	/* Mount point inode */
	dev_t	s_dev;		/* Fs device */
} filesys_t, *fsptr;

/* open file descriptor */
typedef struct oft {
	off_t	o_ptr;		/* File position pointer */
	inoptr	o_inode;	/* Pointer into in-core inode table */
	uchar	o_access;	/* O_RDONLY, O_WRONLY, or O_RDWR */
	uchar	o_refs; 	/* Ref count: depends on # of active children */
} oft_t, *ofptr;

#ifndef _PSTATE_T
#define _PSTATE_T
/* Process table p_status values */
typedef enum {
	P_EMPTY = 0,	/* Unused slot */
	P_ZOMBIE,	/* 1. Exited. */
	P_FORKING,	/* 2. In process of forking; do not mess with */
	P_RUNNING,	/* 3. Currently running process */
	P_READY,	/* 4. Runnable process */
	P_SLEEP,	/* 5. Sleeping; can be awakened by signal */
	P_XSLEEP,	/* 6. Sleeping, don't wake up for signal */
	P_PAUSE,	/* 7. Sleeping for pause(); can wakeup for signal */
	P_WAIT,		/* 8. Executed a wait() */
	P_STOPED	/* 9. Process is stoped */
} pstate_t;
#endif

#define PRIO_MAX	19
#define PRIO_MIN	-20

#define WNOHANG		1
#define WUNTRACED	2

/* Process table entry */
typedef struct s_ptab {
	pstate_t p_status;	/* Process status */
	int	p_pid;		/* Process ID */
	uchar	p_uid;		/* User ID */
	uchar	p_cprio;	/* Process current priority */
/*	uchar	p_prio; 	/* Process base priority - NOT IMPLEMENTED */
	char p_nice;		/* Process nice value (-20 to 19) */
/*	uchar	p_mapped;	/* Process not in UZIX kernel - NOT USED */
/*	page_t	p_map[3];	/* Process memory map - NOT USED */
	page_t	p_swap[2];	/* Swapping parameters */
	struct s_ptab *p_pptr;	/* Process's parent table entry */
	int	p_exitval;	/* Exit value */
	/* Everything below here is overlaid by time info at exit */
	void	*p_break;	/* process break level */
	void	*p_sp;		/* saved stack pointer when swapped out */
	void	*p_udata;	/* back pointer to saved udata */
	uint	p_alarm;	/* Seconds until alarm goes off */
	void	*p_wait;	/* Address of thing waited for */
	sigset_t p_pending;	/* Pending signals */
	sigset_t p_ignored;	/* Ignored signals */
	uchar	p_intr; 	/* !0 if awakened by signal */
} ptab_t, *ptptr;

#define FORALLPROCS(p)	for ((p) = ptab; (p) < ptab + PTABSIZE; ++(p))

/* Per-process data (Swapped with process) */
typedef struct s_udata {
	ptab_t	*u_ptab;	/* Process table pointer */
	uchar	u_name[DIRNAMELEN];	/* Name invoked with */

	/* syscall's interface */
	uchar	u_insys;	/* True if in kernel now */
	uchar	u_callno;	/* syscall being executed */
	uchar	u_error;	/* Last error number */
	uchar	u_traceme;	/* Process tracing flag */
	int	u_argn1;	/* First arg */
	int	u_argn2;	/* Second arg */
	int	u_argn3;	/* Third arg */
	int	u_argn4;	/* Fourth arg (only for lseek) */
	int	u_retval;	/* Return value from syscall */
	int	u_retval1;	/*   for long return value */

	/* I/O interface */
	uchar	*u_base;	/* Source or dest for I/O */
	count_t u_count;	/* Amount for I/O */
	off_t	u_offset;	/* Place in file for I/O */
	bufptr	u_buf;

	/* filesystem info */
	uchar	u_gid;		/* process group id */
	uchar	u_euid; 	/* effective user id */
	uchar	u_egid; 	/* effective group id */
	mode_t	u_mask; 	/* umask: file creation mode mask */
	time_t	u_time; 	/* Start time */
	uchar	u_files[UFTSIZE]; /* Proc file table: cont indexes into oft */
	inoptr	u_root; 	/* Pointer into inode table for root */
	inoptr	u_cwd;		/* Pointer into inode table for cwd */

	/* processes flow info */
	void	*u_break;	/* Top of data space */
	inoptr	u_ino;		/* Used during execve() */
	uchar	u_inint;	/* Inint value right before swapping */

	void	(*u_sigvec[NSIGS]) __P((signal_t)); /* Array of signal vectors */
	signal_t u_cursig;	/* Signal currently being caught (1..NSIGS) */
	time_t	u_utime;	/* Elapsed ticks in user mode */
	time_t	u_stime;	/* Ticks in system mode */
	time_t	u_cutime;	/* Total children's ticks */
	time_t	u_cstime;	/* Total system children's ticks */
} udata_t;

/* Info about a specific process, returned by sys_getfsys */
typedef struct s_pdata {
	int	u_pid;		/* Process PID */
	ptab_t	*u_ptab;	/* Process table pointer */
	uchar	u_name[DIRNAMELEN];	/* Name invoked with */

	/* syscall's interface */
	uchar	u_insys;	/* True if in kernel now */
	uchar	u_callno;	/* syscall being executed */
	uchar	u_traceme;	/* Process tracing flag */

	/* filesystem/user info */
	uchar	u_uid; 		/* user id */
	uchar	u_gid; 		/* group id */
	uchar	u_euid; 	/* effective user id */
	uchar	u_egid; 	/* group user id */
	time_t	u_time; 	/* Start time */

	/* process flow info */
	signal_t u_cursig;	/* Signal currently being caught */

	/* time info */
	time_t	u_utime;	/* Elapsed ticks in user mode */
	time_t	u_stime;	/* Ticks in system mode */
};

/* Info about kernel, returned by sys_getfsys */
typedef struct s_kdata {
	uchar	k_name[14];	/* OS name */
	uchar	k_version[8];	/* OS version */
	uchar	k_release[8];	/* OS release */
	uchar	k_machine[8];	/* Host machine */
	int	k_tmem; 	/* System memory, in kbytes */
	int	k_kmem; 	/* Kernel memory, in kbytes */
};

#define REFRESH_VECTORS()	(!(((exeptr)PROGBASE)->e_flags & 0x80))

#ifdef UZIX_MODULE

#define RESET_MODULE()		(((exeptr)PROGBASE)->e_flags &= ~0x40)
#define SET_MODULE()		(((exeptr)PROGBASE)->e_flags |= 0x40)
#define IS_MODULE()		((((exeptr)PROGBASE)->e_flags & 0x40) != 0)

typedef int (*fcnhnd_t) ();	/* Function call handler typedef */

/* Module table */
typedef struct s_mtable {
	int		sig;	/* Module signature */
	fcnhnd_t	fcn_hnd;/* Module function call handler */
	page_t		page[2];/* Module process pages */
} modtab_t, *modtabptr;

/* Module reply table */
typedef struct s_mreply {
	int	sig;		/* Module signature */
	int	fcn;		/* Function called */
	int	pid;		/* Requester PID */
	char	*replyaddr;	/* Reply data address */
	int	replysize;	/* Reply data size */
} modreply_t, *modreplyptr;
		
#endif
	
/* sys_getset() commands */
#define	GET_PID		0	/* get process id */
#define	GET_PPID	1	/* get parent process id */
#define	GET_UID		2	/* get user id */
#define	SET_UID		3	/* set user id */
#define	GET_EUID	4	/* get effective user id */
#define	GET_GID		5	/* get group id */
#define	SET_GID		6	/* set group id */
#define	GET_EGID	7	/* get effective group id */
#define	GET_PRIO	8	/* get process priority */
#define	SET_PRIO	9	/* set process priority */
#define	SET_UMASK	10	/* get/set umask */
#define	SET_TRACE	11	/* set trace flag */

#endif

