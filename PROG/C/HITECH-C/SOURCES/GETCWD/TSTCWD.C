/* Test char * getcwd(d) */

#include <stdio.h>
#include <sys.h>		/* defines getcwd */

main()
{
	short d;

	d = 0;
	printf("test GETCWD\n");
	if (!DOSVER)
	   printf("*** DOS2 only\n");
	else
	{
	  printf("Current directory: %s\n",getcwd(d));
	}
}

                                                                                                                  