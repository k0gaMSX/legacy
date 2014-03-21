#ifndef _SYS_IOCTL_H
#define _SYS_IOCTL_H

typedef enum {
	GI_PTAB = -1,	/* processes table */
	GI_ITAB = -2,	/* inodes table */
	GI_BTAB = -3,	/* buffers table */
	GI_FTAB = -4,	/* filesystems table */
	GI_UDAT = -5,	/* process user data */
	GI_UTAB = -6,	/* current process table */
	GI_PDAT = -7,	/* process info */
	GI_KDAT = -8	/* kernel info */
} getinfo_t;

/* control of /dev/mem device */
#define MEM_INFO	0

/* control of /dev/tty device */
#define TTY_COOKED	0	/* buffered */
#define TTY_RAW 	1	/* unbuffered, wait */
#define TTY_RAW_UNBUFF	2	/* unbuffered, no wait */

struct swap_mmread {
	uchar	mm[2];
	uint	offset;
	uint	size;
	uchar	*buf;
};

typedef struct {
	getinfo_t req;
	size_t	size;
	void	*ptr;
} info_t;

#endif

