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
 Buffer pool management and generic device I/O routines
**********************************************************/

#define __DEVIO__COMPILATION
#define NEED__DEVIO
#define NEED__MACHDEP
#define NEED__PROCESS

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#include "errno.h"
#include "sys\ioctl.h"
#endif
#include "unix.h"
#include "extern.h"
#include "config.h"

extern char *baddevmsg;

/* Buffer pool management and generic device I/O */

/* The high-level interface is through bread() and bfree().
 *
 * Bread() is given a device and block number, and a rewrite flag.
 * If rewrite is 0, the block is actually read if it is not already
 * in the buffer pool. If rewrite is set, it is assumed that the caller
 * plans to rewrite the entire contents of the block, and it will
 * not be read in, but only have a buffer named after it. Also if
 * rewrite great then 1 bread() zeroes allocated buffer.
 *
 * Bfree() is given a buffer pointer and a dirty flag.
 * The dirty flag ored with buffer bf_dirty and if result is 0, the buffer
 * is made available for further use, else the buffer is marked "dirty", and
 * it will eventually be written out to disk.  If the flag is 2, the buffer
 * will be immediately written out to disk.
 *
 * Zerobuf() returns a buffer of zeroes not belonging to any device.
 * It must be bfree'd after use, and must not be dirty.
 * It is used when a read() wants to read an unallocated block of a file.
 *
 * Bufsync() write outs all dirty blocks (exclude ones with bf_prio set!)
 *
 * Note that a pointer to a buffer structure is the same as a
 * pointer to the data.  This is very important.
 */

STATIC bufptr freebuf __P((uchar waitfor));

STATIC uint bufclock = 0;	/* Time-stamp counter for LRU */

#if DEBUG > 0
GBL uint buf_hits;	/* buffer pool hits */
GBL uint buf_miss;	/* buffer pool misses */
GBL uint buf_flsh;	/* buffer pool flushes */
#endif

/* read block blk from device dev, return buffer with this block */
GBL void *bread(dev, blk, rewrite)
	dev_t dev;
	blkno_t blk;
	uchar rewrite;
{
	register bufptr bp = bufpool;

	/* find this block in buffer pool */
	while (bp < bufpool+NBUFS) {
		if (bp->bf_dev == dev && bp->bf_blk == blk) {
			if (bp->bf_busy)	/* ??? */
				panic("want busy block %d at dev %d",blk,dev);
#if DEBUG > 0
			++buf_hits;
#endif
			goto Done;
		}
		++bp;
	}
#if DEBUG > 0
	++buf_miss;
#endif
	/* block not found in pool - allocate free buffer for them */
	if ((bp = freebuf(1)) == NULL) goto Err;
	bp->bf_dev = dev;
	bp->bf_blk = blk;
	/* If rewrite is set, we are about to write over the entire block,
	 * so we don't need the previous contents
	 */
	if (rewrite == 0) {		/* we must read block data */
		if (bdread(bp) < 0) { /* device can define the error */
			if (UDATA(u_error) == 0) UDATA(u_error) = EIO;
Err:			return NULL;
		}
	}
Done:	if (rewrite > 1)		/* we need really zeroed block */
		bzero(bp->bf_data, BUFSIZE);
	bp->bf_busy++;			/* was always zero */
	bp->bf_time = ++bufclock;	/* Time stamp it */
	return (bp->bf_data);
}

/* free not needed now buffer */
GBL int bfree(bp, dirty)
	register bufptr bp;
	uchar dirty;
{
	bp->bf_dirty |= dirty;
	bp->bf_busy = 0;
	if (bp->bf_dirty && bp->bf_dev == NULLDEV)
		panic("attempt to write-back zerobuf");
	if (bp->bf_dirty >= 2 && !dirty_mask) { /* Extra dirty */
		if (bdwrite(bp) < 0) {
			UDATA(u_error) = EIO;
			return (-1);
		}
		bp->bf_prio = bp->bf_dirty = 0;
	}
	if (!bp->bf_prio)
		wakeup(bufpool);
	return 0;
}

/* Returns a free zeroed buffer with no associated device.
 * It is essentially a malloc for the kernel. Free it with brelse().
 * This procedure able to return NULL only if waitfor==0
 */
GBL void *zerobuf(waitfor)
	uchar waitfor;
{
	static int blk = 0;
	register bufptr bp = freebuf(waitfor);

	if (bp) {
		bp->bf_dev = NULLDEV;
		bp->bf_blk = ++blk;
		bp->bf_busy = 1;
		bp->bf_time = ++bufclock;
		bzero(bp->bf_data, BUFSIZE);
		return bp->bf_data;
	}
	return NULL;
}

/* flush all dirty buffers (except ones with bf_prio set) */
GBL void bufsync(VOID) {
	register bufptr bp = bufpool;

	dirty_mask = 0;
	while (bp < bufpool+NBUFS) {
		if (bp->bf_dev != NULLDEV &&
		    bp->bf_dirty &&
		    !bp->bf_prio) {
			if (!bdwrite(bp))
				bp->bf_dirty = 0;
		}
		++bp;
	}
}

/* find free buffer in pool or freeing oldest
 * This procedure able to return NULL only if waifor==0
 */
STATIC bufptr freebuf(waitfor)
	uchar waitfor;
{
	uchar i;
	uint diff;
	register bufptr bp;
	register bufptr oldest = NULL;
	register uint oldtime = 0;

	/* Try to find a non-busy buffer and
	 * write out the data if it is dirty
	 */
	for (;;) {
		i = 1;
		while (oldest == NULL) {
			/* pass 1 - try to find non dirty buffer */
			/* pass 0 - try to find any buffer */
			bp = bufpool;
			while (bp < bufpool+NBUFS) {
				if (!bp->bf_busy && !bp->bf_prio &&
				    !(bp->bf_dirty & i)) {
					diff = bufclock - bp->bf_time;
					if (diff >= oldtime) {
						oldest = bp;
						oldtime = diff;
					}
				}
				++bp;
			}
			i ^= 1;
		}
		if (oldest)	/* buffer found */
			break;
		if (!waitfor)
			goto Err;
		psleep(bufpool); /* wait for buffer */
	}
	if (oldest->bf_dirty) {
#if DEBUG > 0
		++buf_flsh;
#endif
		if (bdwrite(oldest) < 0) {
			UDATA(u_error) = EIO;
Err:			return NULL;
		}
		oldest->bf_dirty = 0;
	}
	return oldest;
}

#if DEBUG > 0
/* dump buffers info for debug */
GBL void bufdump(VOID) {
	register bufptr bp = bufpool;

	kprintf("Buf hits/miss/flsh: %u/%u/%u\nBuffs:\tdev\tblock\tDBP\ttime\t(clock=%d)\n",
		buf_hits, buf_miss, buf_flsh, bufclock);
	while (bp < bufpool+NBUFS) {
		kprintf("\t%p\t%u\t%c%c%c\t%u\n",
			bp->bf_dev, bp->bf_blk,
			bp->bf_dirty ? 'd' : '-',
			bp->bf_busy ? 'b' : '-',
			bp->bf_prio ? 'p' : '-',
			bp->bf_time);
		++bp;
	}
	buf_miss = buf_hits = buf_flsh = 0;
}
#endif

/* validate device number */
GBL devsw_t *validdev(dev, msg)
	dev_t dev;
	char *msg;
{
	register devsw_t *t = &dev_tab[MAJOR(dev)];

	if (MAJOR(dev) < DEV_TAB && MINOR(dev) < t->minors)
		return t;
	if (msg != NULL)
		panic(baddevmsg, msg, MAJOR(dev));
	UDATA(u_error) = ENODEV;
	return NULL;
}

/* Bdread() and bdwrite() are the block device interface routines.
 * They are given a buffer pointer, which contains the device,
 * block number, and data location.
 * They basically validate the device and vector the call.
 *
 * Cdread() and cdwrite() are the same for character (or "raw") devices,
 * and are handed a device number.
 *
 * Udata.u_base, count, and offset have the rest of the data.
 *
 * The device driver read and write routines now have only two arguments,
 * minor and rawflag. If rawflag is zero, a single block is desired, and
 * the necessary data can be found in UDATA(u_buf).
 * Otherwise, a "raw" or character read is desired, and UDATA(u_offset),
 * UDATA(u_count), and UDATA(u_base) should be consulted instead.
 *
 * Any device other than a disk will have only raw access.
 */

/* block device read/write */
GBL int bdreadwrite(bp, write)
	register bufptr bp;
	uchar write;
{
	register dev_t dev = bp->bf_dev;
	register devsw_t *dt = validdev(dev, !write ? "bdread" : "bdwrite");

	UDATA(u_buf) = bp;
	if (write) return (dt->dev_write)(MINOR(dev), 0);
	return (dt->dev_read)(MINOR(dev), 0);
}

/* character device read */
GBL int cdreadwrite(dev, write)
	register dev_t dev;
	uchar write;
{
	register devsw_t *dt = validdev(dev, !write ? "cdread" : "cdwrite");

	if (write) return (dt->dev_write)(MINOR(dev), 1);
	return (dt->dev_read)(MINOR(dev), 1);
}

GBL int d_openclose(dev, open)
	register dev_t dev;
	uchar open;
{
	register devsw_t *dt = validdev(dev, open ? NULL : "d_close");

	if (dt == NULL)
		return (-1);
	if (open) return (dt->dev_open)(MINOR(dev));
	return (dt->dev_close)(MINOR(dev));
}

/* generic device ioctl */
GBL int d_ioctl(dev, request, data)
	register dev_t dev;
	int request;
	void *data;
{
	register devsw_t *dt = validdev(dev, NULL);

	if (dt == NULL) {
		UDATA(u_error) = ENXIO;
		goto Err;
	}
	if ((dt->dev_ioctl)(MINOR(dev), request, data)) {
		UDATA(u_error) = EINVAL;
Err:		return (-1);
	}
	return 0;
}

/* all devices initialization */
GBL int d_init(VOID) {
	register devsw_t *dt = dev_tab;
	uchar minor;

	while (dt < dev_tab+DEV_TAB) {
		minor = 0;
		while (minor < dt->minors) {
			if ((dt->dev_init)(minor) != 0)
				return -1;
			++minor;
		}
		++dt;
	}
	return 0;
}

/* special filler for driver functions, which do nothing */
int ok(uchar minor) {
	NOTUSED(minor);
	return 0;
}

/* special filler for driver functions, which return error */
int nogood(uchar minor) {
	NOTUSED(minor);
	return (-1);
}

/* special filler for driver ioctl functions, which return error */
int nogood_ioctl(minor, req, data)
	uchar minor;
	int req;
	void *data;
{
	NOTUSED(minor);
	NOTUSED(req);
	NOTUSED(data);
	return (-1);
}

#ifdef __KERNEL__
/*
 * Character queue management routines
 */

/* add something to the queue tail */
GBL int insq(q, c)
	register queue_t *q;
	uchar c;
{
	uchar retval = 0;

	_di();
	if (q->q_count != q->q_size) {	/* queue not full */
		*(q->q_tail) = c;	/* save char */
		++q->q_count;		/* count them */
		if (++q->q_tail >= q->q_base + q->q_size)
			q->q_tail = q->q_base;	/* process pointer rollover */
		++retval;
	}
	_ei();
	return retval;
}

/* Remove something from the queue head */
GBL int remq(q, cp)
	register queue_t *q;
	uchar *cp;
{
	uchar retval = 0;

	_di();
	if (q->q_count != 0) {
		*cp = *(q->q_head);	/* get char from queue */
		--q->q_count;		/* count them */
		if (++q->q_head >= q->q_base + q->q_size)
			q->q_head = q->q_base;	/* process pointer rollover */
		++retval;
	}
	_ei();
	return retval;
}

/* Remove something from the tail; the most recently added char. */
GBL int uninsq(q, cp)
	register queue_t *q;
	uchar *cp;
{
	uchar retval = 0;

	_di();
	if (q->q_count != 0) {
		--q->q_count;		/* count removed char */
		if (--q->q_tail < q->q_base)
			q->q_tail = q->q_base + q->q_size - 1;
		*cp = *(q->q_tail);	/* save removed char */
		++retval;
	}
	_ei();
	return retval;
}

/* Clear queue. */
GBL void clrq(q)
	register queue_t *q;
{
	_di();
	q->q_count = 0;
	q->q_tail = q->q_base;
	q->q_head = q->q_base;
	_ei();
}

#if 0
/* Returns true if the queue has more characters than its wakeup number */
/* not used now */
GBL int fullq(q)
	queue_t *q;
{
	uchar s;

	_di();
	s = q->q_count > q->q_wakeup;
	_ei();
	return s;
}
#endif
#endif	/* __KERNEL__ */