/*  fortune  -  hand out Chinese fortune cookies	Author: Bert Reuling */

#include <types.h>
#include <sys/stat.h>
#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

#define COOKIEJAR "/usr/lib/fortune.dat"

static char *Copyright = "\0Copyright (c) 1990 Bert Reuling";
static unsigned long seed;

#ifndef _PROTOTYPE
#define _PROTOTYPE(x,y)		x y
#endif

_PROTOTYPE(int main, (int argc, char **argv));
_PROTOTYPE(unsigned long magic, (unsigned long range));

#if defined(MSX_UZIX_TARGET) || defined (PC_UZIX_TARGET)
#define LONG(x)		(long)(x.t_time+x.t_date*65536)
#else
#define LONG(x)		(long)x
#endif

int main(argc, argv)
int argc;
char *argv[];
{
  int c1, c2, c3;
  struct stat cookie_stat;
  FILE *cookie;
  time_t now;

  if ((cookie = fopen(COOKIEJAR, "r")) == NULL) {
	printf("\nSome things better stay closed.\n  - %s\n", argv[0]);
	exit (-1);
  }

  /* Create seed from : date, time, user-id and process-id. we can't get
   * the position of the moon, unfortunately.
   */
  time(&now);
  seed = LONG(now) + (long) getuid() + (long) getpid();
  
  if (stat(COOKIEJAR, &cookie_stat) != 0) {
	printf("\nIt furthers one to see the super guru (%d).\n  - %s\n", errno, argv[0]);
	exit (-1);
  }
  
  fseek(cookie, magic((unsigned long) cookie_stat.st_size), 0); /* move by magic... */

  c2 = c3 = '\0';
  while (((c1 = getc(cookie)) != EOF) && ((c1 != '%') || (c2 != '%') || (c3 != '\n'))) {
	c3 = c2;
	c2 = c1;
  }

  if (c1 == EOF) {
	printf("\nSomething unexpected has happened.\n  - %s", argv[0]);
	exit (-1);
  }

  c2 = c3 = '\0';
  c1 = getc(cookie);	/* skip \n */
  while (((c1 = getc(cookie)) != '%') || (c2 != '%') || (c3 != '\n')) {
	if (c1 == EOF) {
		rewind(cookie);
		continue;
	}
	putc(c2, stdout);
	c3 = c2;
	c2 = c1;
  }
  /* putc('\n', stdout); */
  fclose(cookie);
  return (0);
}

/*  magic  -  please study carefull: there is more than meets the eye */
unsigned long magic(range)
unsigned long range;
{

  seed = 9065531L * (seed % 9065533L) - 2 * (seed / 9065531L) + 1L;
  return (seed % range);
}
