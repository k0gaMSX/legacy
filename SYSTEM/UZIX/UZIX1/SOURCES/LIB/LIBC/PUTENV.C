/************************** putenv.c ***************************/
/* Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "environ.h"

#ifdef L_putenv
#include <malloc.h>

#define ADD_NUM 4

int putenv(var)
	register char *var;
{
	static char **mall_env = 0;
	static int extras = 0;
	char **p, **d, *r, *q;
	register int len;

	if ((r = strchr(var, '=')) == 0)
		len = strlen(var);
	else	len = (int)(r - var);
	p = environ; 
	while ((q = *p) != NULL) {
		if (q[0] == var[0] &&
		    q[len] == '=' &&
		    memcmp(var, q, len) == 0) {
			while ((p[0] = p[1]) != NULL)
				p++;
			extras++;
			break;
		}
		++p;
	}
	if (r == 0)
		return 0;	/* want removing */
	if (extras <= 0) {	/* Need more space */
		if ((d = malloc((p-environ+1+ADD_NUM)*sizeof(char *))) == 0)
			return -1;
		memcpy(d, environ, (p-environ+1)*sizeof(char *));
		p = d + (p - environ);
		extras = ADD_NUM;
		if (mall_env)
			free(mall_env);
		mall_env = environ = d;
	}
	*p++ = var;
	*p = NULL;
	extras--;
	return 0;
}
#endif
