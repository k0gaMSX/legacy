/* REVERSE.C  example program to demonstrate random access

   type REVERSE file   to type a file backwards
*/

#include <stdio.h>

extern FILE *fopen();		/* declare external function */

main(argc,argv)
int argc;
char **argv;
{
	FILE *infile;		/* input file pointer */
	int c;
	long fpos;

	if (argc != 2)
	{
		printf("\nError - missing filename");
		abort();
	}

	infile = fopen(argv[1],"a+b");		/* open file at end */
	if (infile == NULL)
	{        
		printf("\nCannot open file");
		abort();
	}

	fpos = ftell(infile);			/* number of bytes in file */
	fseek(infile,-1L,1);			/* move back to last byte */

	while(fpos--)
	{						
		c = fgetc(infile);		/* read character */
		putchar(c);			/* disp;lay it */
		fseek(infile,-2L,1);		/* back two bytes */
	}

	fclose(infile);
}
