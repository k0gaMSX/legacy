
/*
		fcopy.c
*/

#include	<bdscio.h>

main(argc,argv)
int argc;
char *argv[];
{
	char	c;
	FILE	infile, outfile;

	if (argc < 3)
		errexit ("Usage: copy oldfile newfile",NULL);
	if (strcmp (argv[1], argv[2]) == 0)
		errexit ("File names must be different", NULL);
	if (fopen (argv[1], infile) == ERROR)
		errexit ("Can't open", argv[1]);
	if (fcreat (argv[2], outfile) == ERROR)
		errexit ("Can't create", argv[2]);

	printf ("File %s ", argv[1]);

	do {
		putc (c = getc(infile), outfile);
	} while (c != CPMEOF);

	fclose (infile);
	fclose (outfile);

	printf("copied to %s.\n", argv[2]);
	exit();
}

errexit(s1, s2)
char *s1, *s2;
{
	if (s2 == NULL)
		printf("%s\n", s1);
	else
		printf("%s %s\n", s1, s2);
	exit();
}
