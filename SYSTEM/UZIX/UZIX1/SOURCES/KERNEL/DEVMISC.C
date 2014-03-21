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
 Miscellaneous device drivers: memory, printer, null
**********************************************************/

#define NEED__DEVMISC
#define NEED__MACHDEP
#define NEED__SCALL

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#include "sys\ioctl.h"
#endif
#include "unix.h"
#include "extern.h"

STATIC uchar lop = 0;

STATIC uchar lpout __P((uchar c));

#ifdef PC_HOSTED
#include "devmisc.mtc"
#else /* PC_HOSTED */
#ifdef MSX_HOSTED
#include "devmisc.msx"
#else /* MSX_HOSTED */
#endif /* MSX_HOSTED */
#endif /* PC_HOSTED */

#ifdef MEM_DEV
/* DEVICE DRIVER - mem, 128 blocks of main memory */

#define NUM_MEMBLK	((uint)((((uint)-1) >> BUFSIZELOG)+1))

/* read data from device */
GBL int mem_read(minor, rawflag)
	uchar minor;
	uchar rawflag;
{
	uint ublk = (uint)(UDATA(u_offset) >> BUFSIZELOG);

	NOTUSED(minor);
	NOTUSED(rawflag);
	if (ublk > NUM_MEMBLK)
		return -1;
	if (ublk == NUM_MEMBLK)
		return 0;
	bcopy((void *)(uint)UDATA(u_offset), UDATA(u_base), UDATA(u_count));
	return UDATA(u_count);
}

/* write data to device */
GBL int mem_write(minor, rawflag)
	uchar minor;
	uchar rawflag;
{
	uint ublk = (uint)(UDATA(u_offset) >> BUFSIZELOG);

	NOTUSED(minor);
	NOTUSED(rawflag);
	if (ublk >= NUM_MEMBLK)
		return -1;
	bcopy(UDATA(u_base), (void *)(uint)UDATA(u_offset), UDATA(u_count));
	return UDATA(u_count);
}

/* do ioctl on device */
GBL int mem_ioctl(minor, req, ptr)
	uchar minor;
	int req;
	void *ptr;
{
	NOTUSED(minor);
	if (req == MEM_INFO)
		return getfsys(((info_t *)ptr)->req, (info_t *)ptr);
	return -1;
}
#endif

/* DEVICE DRIVER - null */

/* write data to device - simply drop data */
GBL int null_write(minor, rawflag)
	uchar minor;
	uchar rawflag;
{
	NOTUSED(minor);
	NOTUSED(rawflag);
	return UDATA(u_count);
}

/* read data from device - always eof */
GBL int null_read(minor, rawflag)
	uchar minor;
	uchar rawflag;
{
	NOTUSED(minor);
	NOTUSED(rawflag);
	return 0;
}

/* DEVICE DRIVER - printer */

/* Open device */
GBL int lpr_open(minor)
	uchar minor;
{
	lop = minor+1;	/* mark opened state */
	return 0;
}

/* Close device */
GBL int lpr_close(minor)
	uchar minor;
{
	if ((uchar)lop == (uchar)(minor+1)) {	/* was opened */
		lpout('\f');	/* flush page */
		lop = 0;	/* mark not opened */
		return 0;
	}
	return (-1);
}

/* read data from device - always error */
GBL int lpr_read(minor, rawflag)
	uchar minor;
	uchar rawflag;
{
	NOTUSED(minor);
	NOTUSED(rawflag);
	return -1;
}

/* write data to device */
GBL int lpr_write(minor, rawflag)
	uchar minor;
	uchar rawflag;
{
	register count_t n = UDATA(u_count);

	NOTUSED(rawflag);
	if ((uchar)lop != (uchar)(minor+1))	/* device not opened */
		return (-1);
	/* write until done or printer error */
	while (n && !lpout(*(UDATA(u_base))++))
		--n;
	return UDATA(u_count-n);
}

