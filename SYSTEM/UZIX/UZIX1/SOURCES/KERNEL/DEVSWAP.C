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
 Memory swapper
**********************************************************/

#define NEED__DEVSWAP
#define NEED__MACHDEP

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#include "sys\ioctl.h"
#endif
#include "unix.h"
#include "extern.h"

#ifdef PC_HOSTED
#include "devswap.mtc"
#else /* PC_HOSTED */
#ifdef MSX_HOSTED
#include "devswap.msx"
#else /* MSX_HOSTED */
#endif /* MSX_HOSTED */
#endif /* PC_HOSTED */
