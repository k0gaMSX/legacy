#include "stdio.h"		/* Include file overhead info */
#define CLEAR 12		/* Clear screen for ADDS Viewpoint */

main(argc, argv)
int argc;
char *argv[];
{
	int i, c;
	FILE *fp;

	putchar(CLEAR);		/* Clear the screen */

	if (argc != 2) {
		printf("I need to know the file name.\n\n");
		printf("Use:\n\nA>READFILE FILENAME.XXX");
		exit(-1);
	}

	if ((fp = fopen(argv[1], "r")) == NULL) {
		printf("Can't open file %s", argv[1]);
		exit(-1);
	}

	while ((c = getc(fp)) != EOF)
		putchar(c);

	fclose(fp);
}

