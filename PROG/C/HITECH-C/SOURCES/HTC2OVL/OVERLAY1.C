/* Test overlay function for Hi-Tech C */

#include <stdio.h>
extern char version[];

ovmain(code)
int code;
{
	printf("We're in overlay 1 now.\nGlobal version reads: %s\n",version);
	printf("The code is: %d\n",code);
	return 42;
}

         