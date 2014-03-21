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
 System configuration
**********************************************************/

/* Remake devio.c when this is changed */

#ifndef __EXTERN_H_IN_PROGRESS
#ifdef __DEVIO__COMPILATION

#define O	ok
#define B	nogood
#define B_ioctl	nogood_ioctl
#define M	MAXDRIV

devsw_t dev_tab[] = {	/* The device driver switch table */
	{ M, fd_init, fd_open,  fd_close,   fd_read,  fd_write,   B_ioctl },	/* 0 - /fd* */
	{ 1, O,       O,        O,          null_read,null_write, B_ioctl },	/* 1 - /null */
	{ 1, O,       lpr_open, lpr_close,  lpr_read, lpr_write,  B_ioctl },	/* 2 - /lpr */
	{ 1, O,       O,        O,          tty_read, tty_write,  tty_ioctl},	/* 3 - /tty */
#ifdef MEM_DEV
	{ 2, O,       O,        O,          mem_read, mem_write,  B_ioctl }, 	/* 4 - /mem */
#else	/* MEM_DEV */
	{ 2, O,       B,        B,          null_read,null_write, B_ioctl },	/* 4 - /mem */
#endif	/* MEM_DEV */
};
#define DEV_TAB (sizeof(dev_tab)/sizeof(dev_tab[0]))
#undef O
#undef B
#undef B_ioctl
#undef M

#endif
#else	/* __EXTERN_H_IN_PROGRESS */

#define BLK_DEVS 1	/* # of block (mountable) devices in table */
#define NFS	2	/* max # of mounted fs */
#define ROOTDEV 0x000	/* Device used by kernel as root */
#define TTYDEV	0x300	/* Device used by kernel for messages, panics */

#define VERSION "1.0"	/* UZIX version */
#define RELEASE "0"	/* UZIX release */

#endif	/* __EXTERN_H_IN_PROGRESS */
