/*
	wc      -       count lines, words, characters in file

	23-Nov-83
	25-Nov-83       use expargs
*/

#include <stdio.h>

typedef unsigned nat;

typedef nat     LONG[2];

#define YES     1
#define NO      0
#define MAXFILE 100

#pragma nonrec



char    helpmsg[] =
"wc ver 1.0\n\
usage:\twc [-fh] [inputfiles]\r";


LONG    nl, nw, nc, tnl, tnw, tnc;




VOID    zerolong(n)
LONG    n;
{
	n[0] = n[1] = 0;
}


VOID    inclong(n)
LONG    n;
{
	if(++n[0] >= 10000) {
		n[0] = 0;
		++n[1];
	}
}



VOID    putlong(n)
LONG    n;
{
	if(n[1] != 0) {
		printf("%5u", n[1]);
		printf("%04u", n[0]);
	} else
		printf("%9u", n[0]);
}



VOID    count(fp)
FILE    *fp;
{
	int     c;
	BOOL    inword;

	inword = NO;
	zerolong(nc);   zerolong(nw);   zerolong(nl);
	while((c = getc(fp)) != EOF) {
		inclong(nc);
		inclong(tnc);
		if(c == '\n') {
			sensebrk();
			inclong(nl);
			inclong(tnl);
		}
		if(c == ' ' || c == '\n' || c == '\t')
			inword = NO;
		else if(inword == NO) {
			inword = YES;
			inclong(nw);
			inclong(tnw);
		}
	}
}




VOID    main(argc, argv)
nat     argc;
char    *argv[];
{
	static  char    *xargv[MAXFILE];
	FILE    *fp;
	char    *p;
	nat     i, xargc;
	BOOL    prteach;

	prteach = YES;
	while(argv++, argc--, argc != 0 && argv[0][0] == '-')
		for(p = &argv[0][1];  *p;  p++)
			switch(*p) {
			case 'F':
				prteach = NO;
				break;
			case 'H':
				fprintf(stderr, helpmsg);
				exit(1);
			default:
				fprintf(stderr, "bad option: -%c\r", *p);
				exit(1);
			}

	zerolong(tnc);  zerolong(tnw);  zerolong(tnl);
	if(argc == 0)
		count(stdin);
	else {
		if( (xargc = expargs(argc, argv, MAXFILE, xargv)) == ERROR ) {
			fprintf(stderr, "too many files\r");
			exit(1);
		}
		if(xargc < 2)
			prteach = NO;
		for(i = 0;  i < xargc;  i++) {
			if( (fp = fopen(xargv[i], "r")) == NULL ) {
				fprintf(stderr, "can't open: %s\r", xargv[i]);
				exit(1);
			}
			count(fp);
			if(prteach) {
				putlong(nl);
				putlong(nw);
				putlong(nc);
				printf("\t%s\n", xargv[i]);
			}
			fclose(fp);
		}
	}
	putlong(tnl);
	putlong(tnw);
	putlong(tnc);
	puts("\n");
}
