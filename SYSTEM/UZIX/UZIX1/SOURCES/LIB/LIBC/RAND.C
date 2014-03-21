/* rand.c
 */
#include <stdlib.h>

#ifdef ZX81_RNG
/* This is my favorite tiny RNG, If you had a ZX81 you may recognise it :-)
 *								(RdeBath)
 */

#define MAXINT (((unsigned)-1)>>1)

static unsigned sseed = 0;

int rand(void) {
	sseed = (unsigned)(((sseed + 1L) * 75L) % 65537L) - 1;
	return sseed;
}

void srand(seed)
	unsigned seed;
{
	sseed = seed;
}
#else
/* This generator is a combination of three linear congruential generators
 * with periods or 2^15-405, 2^15-1041 and 2^15-1111. It has a period that
 * is the product of these three numbers.
 */
static int seed1 = 1;
static int seed2 = 1;
static int seed3 = 1;
#define MAXINT (((unsigned)-1)>>1)

#define CRANK(a,b,c,m,s)	\
	q = s/a;		\
	s = b*(s-a*q) - c*q;	\
	if (s < 0) s += m;

int rand(void) {
	register int q;
#if 1
	q = seed1/206; 
	seed1 = 157*(seed1-206*q) - 31*q;
	if (seed1 < 0) seed1 += 32363;

	q = seed2/217;
	seed2 = 146*(seed2-217*q) - 45*q;
	if (seed2 < 0) seed2 += 31727;

	q = seed3/222;
	seed3 = 142*(seed3-222*q) - 133*q;
	if (seed3 < 0) seed3 += 31657;
#else	
	CRANK(206, 157, 31, 32363, seed1);
	CRANK(217, 146, 45, 31727, seed2);
	CRANK(222, 142, 133, 31657, seed3);
#endif
	return seed1 ^ seed2 ^ seed3;
}

void srand(seed)
	unsigned int seed;
{
	seed &= MAXINT;
	seed1 = seed % 32362 + 1;
	seed2 = seed % 31726 + 1;
	seed3 = seed % 31656 + 1;
}
#endif

