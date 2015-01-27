/*                            */
/*    MSX-C compiler sample   */
/*      program "head.c"      */

#pragma nonrec
#include <stdio.h>

#define NUL '\0'
#define TABS 8
#define TAB (char)0x09
#define space (char)0x20

#define SIZBUF (unsigned)1024 /*size of line buffer*/

/*usage*/
char USAGE[] = "Usage: head [/n] [/l] <filename>\n";

/*error messages*/
char e_mes1[] = "File not found\n";
char e_mes2[] = "Invalid character\n";
char e_mes3[] = "Missing parameter\n";
char e_mes4[] = " is not digit\n";
char e_mes5[] = "Unknown switch\n";
char e_mes6[] = "Excessive argument\n";
char e_mes7[] = "Not enough memory for buffer\n";

BOOL Nsw; /*switch flag*/

VOID puthlp()
{
/*--------------------------*/
    printf("\
HEAD\n\
============================\n\
Usage: head[/h][/l<lines>][/n] [<filename>]\n\
\n\
 /h ... help\n\
 /l ... number of lines\n\
 /n ... suppress filenames\n\
	and line numbers\n\
\n\
HEAD prints   the  first  10\n\
(or specified   number   of)\n\
lines of  a  specified file.\n\
If no  file  is   specified,\n\
standard input  is  printed.\n\
By default, file is  printed\n\
with filename    and    line\n\
numbers.\n\
\n\
");
    exit(0);
}

VOID putusage()
{
    fputs(USAGE, stderr);
}

int atoix(p)
char **p;
{
    int ans;

    for (ans = 0; ('0' <= **p) && ('9' >= **p); (*p)++)
	ans = ans *10+ (int)(**p - '0');

    return(ans);
}

int shifarg(argc, argv, num) /*shift argument table*/
int argc;
char **argv;
int num;
{

    for (argc--; num < argc; num++)
	argv[num] = argv[num+1];

    return(argc);
}

int parsesw(argc, argv, ptr)
int argc;
char **argv;
unsigned *ptr;
{/*start of parsesw()*/
    int i;
    char *cp;

    for(i = 1; i < argc; ){
	if (*argv[i] == '/') {
	    cp = argv[i] + 2;

	    switch(toupper(*(argv[i] + 1))) {

	    case 'H':
		puthlp();

	    case 'E': case 'L':
		    if (!(*cp))
			fputs(e_mes3, stderr);
		    *ptr = (unsigned)atoix(&cp);
		    if (*cp != NUL){
			fprintf(stderr, "%c%s", *cp,e_mes4);
			putusage();
			exit(1);
		    }
		    argc = shifarg(argc, argv, i);/*shift argument table*/
		    break;

		case 'N':
		    if (*cp != NUL){
			fputs(e_mes2, stderr);
			putusage();
			exit(1);
		    }
		    Nsw = TRUE;
		    argc = shifarg(argc, argv, i);
		    break;

		default:
		    fputs(e_mes6, stderr);
		    putusage();
		    exit(1);
	    }
	} else i++;
    }
    return(argc);
}/*end of parsesw()*/

VOID ts(buf)
char *buf;
{
    unsigned pos;

    for (pos = 0; *buf; pos++, buf++) {
	if (*buf == TAB) {
	    pos = TABS -pos % TABS;

	    while (pos--)
		putchar(space);

	} else
	    putchar(*buf);
    }

    return;
}

VOID typehead(fp, lines)
FILE *fp;
unsigned lines;
{/*start of typehead module*/

    char buf[SIZBUF];
    unsigned counter;

    for(counter = 1; (counter <= lines) && fgets(buf, SIZBUF-1, fp); counter++){
	if (!Nsw) {
	    printf("%5u: ", counter); /*print line number*/
	    ts(buf);                  /*expand tabs to blanks*/
	} else
	    puts(buf);
    }

}/*end of typehead module*/

main(argc, argv)
int argc;
char *argv[];
{/*start of main */

    FILE *fp;
    int i;
    unsigned lines;

    Nsw = FALSE;
    lines = 10;
    argc = parsesw(argc, argv, &lines);

    if (argc <= 1)
	typehead(stdin, lines);
    else{
	if (argc > 2) {
	    fputs(e_mes6, stderr);
	    putusage();
	    exit(1);
	}
	if ((fp = fopen(argv[1], "r")) == NULL)
	    fputs(e_mes1, stderr);               /*file not found*/
	else {
	    if (!(Nsw))
		printf("      %s:\n", argv[1]);  /*print file name*/
	    typehead(fp, lines);                 /*type out specified*/
	    fclose(fp);
	}
    }
} /* end of main */
