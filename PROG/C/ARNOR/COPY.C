/* COPY.C  example program to demonstrate use of files

   type COPY file1 file2  to copy the first file to the second
*/

#include <stdio.h>

extern FILE *fopen();		/* declare external function */

main(argc,argv)
int argc;
char **argv;
{
	FILE *infile;		/* input file pointer */
	FILE *outfile;		/* output file pointer */
	int c;

	if (argc != 3)
	{
		printf("\nError - need two filenames");
		abort();
	}

	infile = fopen(argv[1],"rb");
	if (infile == NULL)
	{
		printf("\nCannot open input file");
		abort();
	}

	outfile = fopen(argv[2],"wb");
	if (outfile == NULL)
	{
		printf("\nCannot open output file");
		abort();
	}

	while(!feof(infile))
	{
		c = fgetc(infile);
		fputc(c,outfile);
	}

	fclose(infile);
	fclose(outfile);
}
