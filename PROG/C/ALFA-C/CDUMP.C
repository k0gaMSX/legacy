/*
	CDUMP.C  10/29/1983 By Mikio Uzawa
*/



#include	<bdscio.h>

#define STDERR 4
#define LOW	0x21
#define HIGH	0x7F
#define SPACE	0x2E


main(argc,argv)
	int	argc;
	char	*argv[];
{
	FILE fp;
	int i,c;
	char  cb[16];
	unsigned addr;

	addr = 0x0100;

	if (fopen(argv[1],fp) < 0)
		{
		fputs("file can't open\n",STDERR);
		exit();
		}

	while (TRUE)
		{
		printf("%4x: ", addr);
		for (i = 0; i < 16; i++)
			{
			if ((c = getc(fp)) == EOF)
				exit();
			cb[i] = c;
			printf("%02x ", cb[i]);
			}
		printf("  ");
		for (i = 0; i < 16; i++)
			{
			if (cb[i] < LOW || cb[i] > HIGH)
				cb[i] = SPACE;
			printf("%c", cb[i]);
			}
		addr += i;
		printf("\n");
		}
	fclose(fp);
}
