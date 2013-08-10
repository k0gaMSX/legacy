/*
	echo - echo back arguments

	10-Nov-83	fprintf -> fputs
*/


#include <stdio.h>
#pragma	nonrec


VOID	main(argc, argv)
int	argc;
char	**argv;
{
	char	*exargv[100];
	unsigned i, exargc;

	if( (exargc = expargs(argc - 1, argv + 1, 100, exargv)) == ERROR ) {
		fputs("too many arguments\r", stderr);
		exit(1);
	}
	for(i = 0; i < exargc; i++) {
		puts(exargv[i]);
		puts(" ");
	}
	puts("\n");
}
