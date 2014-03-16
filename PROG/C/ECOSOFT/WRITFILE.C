#include "stdio.h"		/* Include file overhead info */
#define CLEAR 12		/* Clear screen for ADDS Viewpoint */
#define MAX 1000		/* Maximum number of characters */

main()
{
	int i, c;
	FILE *fp;

	putchar(CLEAR);		/* Clear the screen */

	if ((fp = fopen("TEXT.TXT", "w")) == NULL) {
		puts("Can't open TEXT.TXT");
		exit(-1);	/* Signals an error */
	}

	puts("Enter line of text and press RETURN:\n");
	for (i = 0; (c = getchar()) != '\n' && i < MAX; ++i)
		putc(c, fp);

	putc(CPMEOF, fp);

	fclose(fp);
}
	