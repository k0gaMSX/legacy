/* lsearch.c
 *    Dale Schumacher			      399 Beacon Ave.
 *    (alias: Dalnefre')		      St. Paul, MN  55104
 *    dal@syntel.UUCP			      United States of America
 */
#include <stdlib.h>
#include <memory.h>

void *lfind(key, base, num, size, cmp)
	register void *key, *base;
	size_t *num;
	register size_t size;
	register cmp_func_t cmp;
{
	register int n = *num;

	while (n--) {
		if ((*cmp) (base, key) == 0)
			return (base);
		base = (char *)base + size;
	}
	return (NULL);
}

void *lsearch(key, base, num, size, cmp)
	void *key, *base;
	register size_t *num;
	register size_t size;
	cmp_func_t cmp;
{
	register void *p;

	if ((p = lfind(key, base, num, size, cmp)) == NULL) {
		p = memcpy(((char *)base + (size * (*num))), key, size);
		++(*num);
	}
	return (p);
}

