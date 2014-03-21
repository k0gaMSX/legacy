/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strcspn ************************************/
#ifdef L_strcspn
/*
 *	Return the length of the sub-string of <string> that consists
 *	entirely of characters not found in <set>.  The terminating '\0'
 *	in <set> is not considered part of the match set.  If the first
 *	character in <string> is in <set>, 0 is returned.
 */
/* This uses strchr, strchr should be in assembler */
size_t strcspn(string, set)
	register char *string;
	char *set;
{
	char *start = string;
	
	while (*string && strchr(set, *string++) == 0)
		;
	return (size_t)(string - start);
}
#endif
