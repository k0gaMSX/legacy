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
 External variables and global declarations
**********************************************************/

#ifndef _EXTERN_H
#define _EXTERN_H

/* These are the global data structures */
#ifdef __MAIN__COMPILATION
#define EXT
#else
#define EXT	extern
#endif

#define GBL
#define LCL
#define STATIC

#ifdef PC_HOSTED	/* only for Turbo-C! */

void __cli__();
void __sti__();
void __int__(int);
void __emit__();

#define geninterrupt(i) __int__(i)

#undef _di
#undef _ei
#define _di()	__cli__()
#define _ei()	{ if (!inint) __sti__(); }
#define __ei()	 __sti__()

#define MAXDRIV	 2	/* maximum number of floppy drives */
			/* must be power of two */

#endif

#ifdef MSX_HOSTED

#ifdef Z80MU
#define cursor(p)
#else
#define cursor(p) ((*(uchar *)0xFCA9) = (p)) /* Turns cursor on (255) or off (0) */
#endif

#ifdef __KERNEL__
#define CALROM	 0801Ch			/* ROM call routine address */
#define BDOSADDR 0801Fh			/* real BDOS call routine address */
#define	BDOS	 _bdospatch		/* BDOS call routine address */
#define MAINDRV	 0F348h			/* diskrom slot to access */
#asm
	global	_bdospatch, _bdostr, _bdosaddr
	global	_bootdskrom
#endasm
#else
#define CALROM	 0F710h			/* ROM call routine address */
#define BDOS	 0F713h			/* BDOS call routine address */
#define MAINDRV  0F716h			/* diskrom slot to access */
#endif
#define DOSVER	(*(char *)0xf313)	/* MSX: 0=DOS1 */

/* MSX UZIX memory map:

   Notes:
   UZIX kernel can't be greater than F180h, or it will hang MSX Turbo-R.
   Beware of address F661h. It used by CHPUT of MSX BIOS.

   0000 ---------------------
     |	    system vectors
   0010 ---------------------
     |	     process data
   0100 ---------------------
     |	     user process
   8000 ---------------------
     |	kernel initialization
   801C ---------------------
     |	   ROM/BDOS caller
   809D ---------------------
     |	     kernel area
   F180 ---------------------
     |    DiskROM hook area
   F380 ---------------------
     |   MSX system var area
   F419 ---------------------
     |	   disk buffer area
   F619 ---------------------
     |	     system area
   F660 ---------------------
     |	ROM caller stack area
   F6EE ---------------------
     |	  kernel data area
   F710 ---------------------
     |	  kernel temp stack
   F7C5 ---------------------   
     |	     system area
   FDFD ---------------------   
     |	       UZIX ISR
   FF01 ---------------------
     |	     system area
   FFFF ---------------------

*/

#define BDRVADDR 63218	/* MSX boot drive (F6F2h, 1 byte) */
#define CNFGBYTE 63219	/* UZIX configuration byte */
#define TICKADDR 63220	/* MSX frequency byte indicator (F6F4h, 1 byte) */
#define RAMADDR  63221	/* MSX swap RAM size (F6F5h, 1 byte) */
#define RAMSLOT  63222	/* MSX swap RAM slot (F6F6h, 1 byte) */
#define IM2ADDR  65021	/* IM 2 interruption call address (FDFDh, 3 bytes)
			   (KILL command hook) */
#define TEMPDBUF 62489	/* temporary disk buffer (F419h, 512 bytes) */
#if DEBUG > 1
#define TSTK	_tmpstk+TMPSTK-2	/* exec() tmp stack */
#else
#define TSTK	 0f7c3h
#endif
#define MAXDRIV	 8	/* maximum number of floppy drives */
			/* must be power of two */

#endif /* MSX_HOSTED */

#define __EXTERN_H_IN_PROGRESS
#include "config.h"
#undef	__EXTERN_H_IN_PROGRESS

EXT uchar MAXTICKS;	/* Max ticks before swapping out (time slice) */
EXT uchar TICKSPERSEC;	/* Ticks per second */
EXT int TICKSPERMIN;	/* Ticks per minute */

#ifdef LOC_UDATA
#if DEBUG > 2
#ifdef __MAIN__COMPILATION
udata_t *_udata_ = ((udata_t *)0x10);
#else
EXT udata_t *_udata_;
#endif
#define	UDATA(a)	(_udata_->a)	
#define	UDATA_ADDR	(_udata_)	
#else
#define udata	(*((udata_t *)0x10))
#define	UDATA(a)	(udata.a)	
#define	UDATA_ADDR	(&udata)
#endif
#else
EXT udata_t udata;		/* MUST BE FIRST */
#define	UDATA(a)	(udata.a)	
#define	UDATA_ADDR	(&udata)	
#endif
#ifdef __KERNEL__
EXT ptab_t ptab[PTABSIZE];	/* processes descriptors */
EXT uchar ptotal;		/* total active processes */
#endif
#if DEBUG > 1
EXT uchar traceon;		/* syscall tracing on */
#endif

#ifdef UZIX_MODULE
EXT modtab_t modtab[MTABSIZE];		/* modules table */
EXT modreply_t modreply[RTABSIZE];	/* modules reply table */
#endif


#ifdef __KERNEL__
#if DEBUG > 1 || defined(PC_HOSTED)
EXT char tmpstk[TMPSTK];	/* temporary stack */
#endif
#endif

#define kputchar 	_putc

extern char *UZIX;

EXT inoptr root_ino;		/* Address of root dir in inode table */
EXT dev_t root_dev;		/* Device number of root filesystem. */

EXT cinode_t i_tab[ITABSIZE];	/* In-core inode table */
EXT oft_t of_tab[OFTSIZE];	/* Open File Table */

EXT filesys_t fs_tab[NFS];	/* Table entry for each device with a fs. */
EXT blkbuf_t bufpool[NBUFS];	/* Buffer pool */
EXT uchar dirty_mask;		/* 1 if buffer writing delayed, else 0 */

EXT ptptr initproc;	/* The process table address of the first process. */
EXT volatile uchar inint; /* flag is set whenever interrupts are being serviced */

EXT uchar sec;		/* Ticks counter for counting off one second */
EXT uchar runticks;	/* Number of ticks current process has been swapped in */

EXT time_t tod; 	/* Time of day */
EXT time_t ticks;	/* Cumulative tick counter, in minutes and ticks  */

EXT uchar total;	/* Total available memory 16k pages */

#ifdef USETEST
extern void tester __P((int where));
#endif

#ifdef NEED__DEVFLOP
/* DEVFLOP.C */

extern int fd_init __P((uchar minor));
extern int fd_open __P((uchar minor));
extern int fd_close __P((uchar minor));
extern int fd_ioctl __P((uchar minor, int, void *));
extern int fd_read __P((uchar minor, uchar rawflag));
extern int fd_write __P((uchar minor, uchar rawflag));

#endif

#ifdef NEED__DEVSWAP
/* DEVSWAP.C */

#ifdef __KERNEL__
extern int swap_init __P((void));
extern int swap_open __P((void));
extern int swap_close __P((void));
extern int swap_alloc __P((page_t *mm));
extern int swap_dealloc __P((page_t *mm));
extern int swap_read __P((page_t *mm));
extern int swap_mmread __P((struct swap_mmread *rp));
#ifdef MEMBANKING
extern int swap_dup __P((page_t *mm, page_t *mmnew));
#else
extern int swap_write __P((page_t *mm));
#endif
#endif /*__KERNEL__*/

#endif

#ifdef NEED__DEVTTY
/* DEVTTY.C */

#ifndef MSX_HOSTED
#define ERASECURSOR()
#define DISPLAYCURSOR()
#else
#define ERASECURSOR()	_erasecursor()
#define DISPLAYCURSOR()	_displaycursor()
extern void _erasecursor __P((void));
extern void _displaycursor __P((void));
#endif

extern void _putc __P((uchar c));
extern int tty_poll __P((void));

extern int tty_init __P((uchar minor));
extern int tty_read __P((uchar minor, uchar rawflag));
extern int tty_write __P((uchar minor, uchar rawflag));
extern int tty_open __P((uchar minor));
extern int tty_close __P((uchar minor));
extern int tty_ioctl __P((uchar minor, int, void *));

#endif

#ifdef NEED__DEVMISC
/* DEVMISC.C */

#ifdef MEM_DEV
extern int mem_read __P((uchar minor, uchar rawflag));
extern int mem_write __P((uchar minor, uchar rawflag));
#endif

extern int null_read __P((uchar minor, uchar rawflag));
extern int null_write __P((uchar minor, uchar rawflag));

extern int lpr_open __P((uchar minor));
extern int lpr_close __P((uchar minor));
extern int lpr_read __P((uchar minor, uchar rawflag));
extern int lpr_write __P((uchar minor, uchar rawflag));

#endif

#ifdef NEED__DEVIO
/* DEVIO.C */

/* release buffer */
#define brelse(bp)	bfree(bp, 0)

/* free buffer and mark them dirty for eventually writing */
#define bawrite(bp)	bfree(bp, 1)

/* do all buffers free without flushing */
#define	bufinit()	bzero(bufpool, NBUFS*sizeof(blkbuf_t))

/* shortcuts for block device and character device read/write and device open/close */
#define bdread(bp)	bdreadwrite(bp, 0)
#define bdwrite(bp)	bdreadwrite(bp, 1)
#define cdread(dev)	cdreadwrite(dev, 0)
#define cdwrite(dev)	cdreadwrite(dev, 1)
#define d_open(dev)	d_openclose(dev, 1)
#define d_close(dev)	d_openclose(dev, 0)

extern char *baddevmsg;

extern void *bread __P((dev_t dev, blkno_t blk, uchar rewrite));
extern int bfree __P((bufptr bp, uchar dirty));
extern void *zerobuf __P((uchar waitfor));
extern void bufsync __P((void));
#if DEBUG > 0
extern void bufdump __P((void));
#endif

extern devsw_t *validdev __P((dev_t dev, char *msg));

extern int bdreadwrite __P((bufptr bp, uchar write));
extern int cdreadwrite __P((dev_t dev, uchar write));
extern int d_openclose __P((dev_t dev, uchar open));

extern int d_init __P((void));
extern int d_ioctl __P((dev_t dev, int request, void *data));

extern int ok __P((uchar minor));
extern int nogood __P((uchar minor));
extern int nogood_ioctl __P((uchar minor, int, void *));

extern int insq __P((queue_t *q, uchar c));
extern int remq __P((queue_t *q, uchar *cp));
extern int uninsq __P((queue_t *q, uchar *cp));
extern void clrq __P((queue_t *q));
extern int fullq __P((queue_t *q));
#endif

#ifdef NEED__FILESYS
/* FILESYS.C */

extern char *baddevmsg;

#define freefileentry(e)	((e) & 0x80)

extern fsptr findfs __P((dev_t devno));
extern int wr_inode __P((inoptr ino));
extern void i_ref __P((inoptr ino));
extern void i_free __P((dev_t devno, ino_t ino));
extern void i_deref __P((inoptr ino));
extern inoptr namei __P((char *name, inoptr *parent, uchar followsym));
extern inoptr srch_dir __P((inoptr wd, char *compname));
extern inoptr srch_mt __P((inoptr ino));
extern inoptr i_open __P((dev_t devno, ino_t ino));
extern int doclose __P((uchar uindex));
extern int ch_link __P((inoptr wd, char *oldname, char *newname, inoptr nindex));
extern char *filename __P((char *path));
extern int namecomp __P((uchar *n1, uchar *n2));
extern inoptr newfile __P((inoptr pino, char *name));
extern ino_t i_alloc __P((dev_t devno));
extern blkno_t blk_alloc __P((dev_t devno));
extern void blk_free __P((dev_t devno, blkno_t blk));
extern uchar oft_alloc __P((void));
extern void oft_deref __P((uchar of));
extern uchar uf_alloc __P((void));
extern bool_t isdevice __P((inoptr ino));
extern void f_trunc __P((inoptr ino));
extern void freeblk __P((dev_t dev, blkno_t blk, uchar level));
extern blkno_t bmap __P((inoptr ip, blkno_t bn, bool_t rwflg));
extern void validblk __P((dev_t dev, blkno_t num));
extern inoptr getinode __P((uchar uindex));
extern int getperm __P((inoptr ino));
extern void setftim __P((inoptr ino, uchar which));
extern int fmount __P((dev_t dev, inoptr ino, bool_t roflag));
extern void magic __P((inoptr ino));
extern void i_sync __P((void));
extern void fs_sync __P((void));
#endif

#ifdef NEED__MACHDEP
/* MACHDEP.C */

/* tempstack() MUST be inline in any case! */
#ifdef __TURBOC__
#define tempstack()	(_AX = (uint)tmpstk+sizeof(tmpstk)-2, _SP = _AX)
#else	/* z80 */
#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)
#if DEBUG > 1
#define tempstack()	asm("	global _tmpstk"); asm(" ld sp," __str1(TSTK))
#else
#define tempstack()	asm(" ld sp," __str1(TSTK))
#endif
#endif /* __TURBOC__ */

extern int Min __P((int a, int b));
extern void bcopy __P((void *src, void *dst, uint count));
extern void bzero __P((void *ptr, uint count));
extern void bfill __P((void *ptr, uchar val, uint count));

#ifndef di
#ifdef HTC
#define _di()	asm("	di")
#define _ei()	{ if (!inint) asm("	ei"); }
#define __ei()	 asm("	   ei")
#else
extern void _di __P((void));
extern void _ei __P((void));
#endif
#endif

#ifndef sttime
#define sttime(x)	wrtod(x)
#endif

#ifndef __KERNEL__
#define	kprintf		printf
#define kputchar(x)	printf("%c", x)
#endif

extern void arch_init __P((void));
extern void _abort __P((int status));
extern void initsys __P((void));
extern void setvectors __P((void));
extern void doexec __P((uint sp));
extern int valadr __P((void *base, uint size));
extern void addtick __P((time_t *t1, time_t *t2));
extern void incrtick __P((time_t *t));
extern void rdtime __P((time_t *tloc));
extern void rdtod __P((void));
#ifdef NO_RTC
extern void updttod __P((void));
#endif
extern void wrtod __P((time_t *tloc));
#ifdef __KERNEL__
extern char *itoa __P((int, char *s, int));
extern void kputs __P((char *s));
#endif
#ifdef __TURBOC__
#ifdef __KERNEL__
extern void kprintf __P((char *fmt, ...));
#endif
extern void panic __P((char *s, ...));
extern void warning __P((char *s, ...));
#else
#ifdef __KERNEL__
extern void kprintf () /*__P((char *fmt, ...))*/ ;
#endif
extern void panic () /*__P((char *s, ...))*/ ;
extern void warning () /*__P((char *s, ...))*/ ;
#endif
#if DEBUG > 0
extern void idump __P((void));
#endif

#endif

#ifdef NEED__PROCESS
/* PROCESS.C */

extern void init __P((void));
#ifdef __KERNEL__
extern void psleep __P((void *event));
extern void wakeup __P((void *event));
extern void swapout __P((void));	/* used in MACHDEP.unix() */
extern int dowait __P((void));
extern int dofork __P((void));
extern void doexit __P((uchar val, uchar val2));
extern int clk_int __P((void));
extern void calltrap __P((void));
extern void chksigs __P((void));
extern void sendsig __P((ptptr proc, signal_t sig));
extern void ssig __P((ptptr proc, signal_t sig));
#else /* __KERNEL__ */
#define psleep(p)
#define wakeup(p)
#endif /* __KERNEL__ */

#endif

#ifdef NEED__DISPATCH
/* dispatch.c */

extern int (*disp_tab[]) __P((void));
extern uchar dtsize;

#endif

extern void readwritei __P((char write, inoptr ino));
#define readi(x) 	readwritei(0, x)
#define writei(x)	readwritei(1, x)

#ifdef NEED__SCALL
/* SCALL.C */

extern void exit0 __P((void));
extern int getfsys __P((dev_t devno, void *buf));

extern int sys_NONE __P((void));
extern int sys_open __P((void));
extern int sys_close __P((void));
extern int sys_pipe __P((void));
extern int sys_link __P((void));
extern int sys_symlink __P((void));
extern int sys_unlink __P((void));
extern int sys_readwrite __P((void));
extern int sys_lseek __P((void));
extern int sys_chdir __P((void));
extern int sys_chroot __P((void));
extern int sys_mknod __P((void));
extern int sys_sync __P((void));
extern int sys_access __P((void));
extern int sys_chmod __P((void));
extern int sys_chown __P((void));
extern int sys_statfstat __P((void));
extern int sys_dup __P((void));
extern int sys_dup2 __P((void));
extern int sys_getset __P((void));
extern int sys_getfsys __P((void));
extern int sys_ioctl __P((void));
extern int sys_mountumount __P((void));
extern int sys_time __P((void));
extern int sys_stime __P((void));
extern int sys_times __P((void));
extern int sys_execve __P((void));
extern int sys_brk __P((void));
extern int sys_sbrk __P((void));
extern int sys_waitpid __P((void));
extern int sys_exit __P((void));
extern int sys_fork __P((void));
extern int sys_pause __P((void));
extern int sys_signal __P((void));
extern int sys_kill __P((void));
extern int sys_alarm __P((void));
extern int sys_utime __P((void));
extern int sys_reboot __P((void));
#ifdef UZIX_MODULE
extern void clear_module_reqs __P((int pid));
extern int sys_reg __P((void));
extern int sys_dereg __P((void));
extern int sys_callmodu __P((void));
extern int sys_repfmodu __P((void));
extern int sys_modreply __P((void));
#endif

#endif

#endif
