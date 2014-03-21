/* Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * 01/99: added -e option by Archi Schekochikhin.
 */
#include <stdio.h>

typedef unsigned char BOOL;

static BOOL nonl;

static void doesc __P((char *p));

static void doesc(p)
	char *p;
{
	int i, n;
	char ch;

	while ((ch = *p++) != 0) {
		if (ch == '\\') {
			switch (*p++) {
			case 'c':	nonl = 1;	continue;
			case 'a':	ch = 7; 	break;
			case 'b':	ch = '\b';	break;
			case 'f':	ch = '\f';	break;
			case 'n':	ch = '\n';	break;
			case 'r':	ch = '\r';	break;
			case 't':	ch = '\t';	break;
			case 'v':	ch = '\v';	break;
			case '\\':	ch = '\\';	break;
			case 'x':
				n = 0;
				for (i = 2; --i >= 0; ++p) {
					ch = *p - '0';
					if (ch > 'a'-'0')
						ch = *p - 'a' + 10;
					else if (ch > 'A'-'0')
						ch = *p - 'A' + 10;
					if (ch < 0 || ch > 15)
						break;
					n <<= 4;
					n += ch;
				}
				ch = n;
				break;
			case '0': case '1': case '2': case '3':
			case '4': case '5': case '6': case '7':
				n = 0;
				for (i = 3, --p; --i >= 0; ++p) {
					ch = *p - '0';
					if (ch < 0 || ch > 7)
						break;
					n <<= 3;
					n += ch;
				}
				ch = n;
				break;
			default:	ch = *p;	break;
			}
		}
		fputc(ch, stdout);
	}
}

int main(argc, argv)
	int argc;
	char *argv[];
{
	BOOL first = 1, esc = 0;
	char *p;
	int i;

	if (argc < 2) {
		fprintf(stderr,"usage: echo [-ne] string ...\n");
		return 0;
	}
	for (i = 1; i < argc; ++i) {
		p = argv[i];
		if (p[0] == '-') {
			for (++p; *p; ++p) {
				switch (*p) {
				case 'n':	nonl = 1; break;
				case 'e':	esc = 1; break;
				default:	goto Print;
				}
			}
		}
		else	break;
	}
Print:	for (; i < argc; ++i) {
		p = argv[i];
		if (!first)
			fputc(' ', stdout);
		first = 0;
		if (esc)
			doesc(p);
		else	fputs(p, stdout);
	}
	if (!nonl)
		fputc('\n', stdout);
	return ferror(stdout);
}

