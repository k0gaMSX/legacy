/* Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 *
 * This is a combined alloca/malloc package. It uses a classic algorithm
 * and so may be seen to be quite slow compared to more modern routines
 * with 'nasty' distributions.
 */

#include "malloc-l.h"

#ifdef L_alloca
static mem *alloca_stack = 0;

void *alloca(size)
	size_t size;
{
	auto char probe;	/* Probes stack depth: */
	register mem *hp, *np;

	/* Reclaim garbage, defined as all alloca'd storage that was allocated
	 * from deeper in the stack than currently.
	 */
	hp = alloca_stack; 
	while (hp != 0) {
		if (m_deep(hp) < &probe) {
			np = m_next(hp);
			free(hp);	/* Collect garbage */
			hp = np;	/* -> next header */
		}
		else	break;	/* Rest are not deeper */
	}
	alloca_stack = hp;	/* -> last valid storage */
	if (size == 0)
		return 0;	/* No allocation required */
	if ((hp = (mem *) (*__alloca_alloc) (sizeof(mem) * 2 + size)) == 0)
		return hp;
	m_next(hp) = alloca_stack;
	m_deep(hp) = &probe;
	alloca_stack = hp;
	/* User storage begins just after header */
	return (void *) (hp + 2);
}
#endif	/* L_alloca */

