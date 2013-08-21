
/*
	CTYPE.C 9/15/1983   by  Mikio Uzawa
*/


#include <bdscio.h>

#define STDERR	4

main(argc,argv)
int	argc;
char	*argv[];
{
	FILE fp;
	int   c;

	if (fopen(argv[1],fp) < 0)
		{
		fputs ("file can't open\n",STDERR);
		exit();
		}

	while ((c = getc(fp)) != CPMEOF)
		{
		printf("%c", c);
		}
	fclose(fp);
}
