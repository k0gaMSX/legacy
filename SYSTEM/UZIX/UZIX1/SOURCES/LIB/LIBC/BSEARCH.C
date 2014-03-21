/* This file lifted in toto from 'Dlibs' on the atari ST  (RdeBath)
 *
 *    Dale Schumacher			      399 Beacon Ave.
 *    (alias: Dalnefre')		      St. Paul, MN  55104
 *    dal@syntel.UUCP			      United States of America
 */
#include <stdlib.h>

int _bsearch;	/* index of element found, or where to insert */

void *bsearch(key, base, num, size, cmp)
	void *key;	/* item to search for */
	void *base;	/* base address */
	size_t num;	/* number of elements */
	size_t size; 	/* element size in bytes */
	cmp_func_t cmp;	/* comparison function */
{
	register int a, b, c, dir;

	a = 0;
	b = num - 1;
	while (a <= b) {
		c = (a + b) >> 1;	/* == ((a + b) / 2) */
		if (0 != (dir = (*cmp) (((char *)base + (c * size)), key))) {
			if (dir > 0)
				b = c - 1;
			else	a = c + 1;	/* (dir < 0) */
		}
		else {
			_bsearch = c;
			return ((char *)base + (c * size));
		}
	}
	_bsearch = b;
	return (NULL);
}
