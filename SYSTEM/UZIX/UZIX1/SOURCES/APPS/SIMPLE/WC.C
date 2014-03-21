/* wc  Count Words, Lines, and Bytes in Files	24.11.87 by BAS
 *
 * wc [-bwp] [file ...]
 *
 *	Count the number of bytes, words, and lines in one or more files.
 *	wc accepts wild-card file name arguments.
 *
 *	-b - open files as binary stream
 *	-w - find max line width
 *	-p - count pages (FF-s)
 *
 * This program is licensed under GNU GPL license.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

long	twords, tlines, tbytes;
int	twidest, tpages;
int	bflag, wflag, pflag;

void error(char *s1,char *s2) {
	fprintf(stderr, "wc: %s %s\n", s1, s2 ? s2 : "");
	exit(1);
}

void help(void) {
	fprintf(stderr, "usage: wc [-bwph] [files]\n");
	exit(0);
}

void plural(long value, char *what) {
	printf("%8ld %s%c", value, what, (value == 1) ? ' ' : 's');
}

void output(long lines, long words, long bytes,
	    int widest, int pages, char *filename) {
	if (bflag) {
		plural(bytes, "byte");
		plural((bytes+511)>>9,"block");
		printf("%6ldK",(bytes+1024)>>10);
	}
	else if (pflag) {
		plural(lines, "line");
		printf("%5d wide",widest);
		printf("%4d page%c", pages, (pages == 1) ? ' ' : 's');
	}
	else {
		plural(lines, "line");
		plural(words, "word");
		plural(bytes, "byte");
		if (wflag)
			printf("%5d wide",widest);
	}
	if (filename)
		printf("\t%s", filename);
	printf("\n");
}

void count(FILE *fp, char *filename) {
	register int c, inword = 0, pos, widest, pages;
	long lines = 0;
	long words = 0;
	long bytes = 0;

	widest = pos = 0;
	pages = 1;
	while((c = getc(fp)) != EOF) {
		++bytes;
		if (bflag)
			continue;
		if (isspace(c)) {
			inword = 0;
			if (c == '\n') {
				if (pos > widest)
					widest = pos;
				++lines;
				pos = 0;
			}
			else if (pflag && c == '\f') {
				++pages;
				pos = 0;
			}
			else if (pflag && c == '\t') {
				int i = 8 - ((pos + 8) & 7);
				pos += i;
				bytes += i-1;
			}
			else	++pos;
		}
		else if (!inword) {
			++inword;
			++words;
			++pos;
		}
		else	++pos;
	}
	if (lines == 0) {
		lines = 1;
		widest = (int)bytes;
	}
	twords += words;
	tlines += lines;
	tbytes += bytes;
	tpages += pages;
	if (twidest < widest)
		twidest = widest;
	output(lines, words, bytes, widest, pages, filename);
}

void main(int argc, char *argv[]) {
	FILE	*fp;
	char	c, *p;
	int	i, nfiles;

	bflag = wflag = pflag = 0;
	for (nfiles = 0, i = 1; i < argc; ++i) {
		p = argv[i];
		if (*p == '-') {
			argv[i] = NULL;
			while ((c = *(++p)) != 0) {
				switch(c) {
				case '?':
				case 'h':
					help();
				case 'b':	++bflag;	break;
				case 'w':	++wflag;	break;
				case 'p':	++pflag;	break;
				default:
					error("Bad switch",p-1);
				}
			}
		}
		else	++nfiles;
	}

	twords = tlines = tbytes = 0;
	tpages = 0;
	if (nfiles == 0)
		count(stdin, NULL);
	else {
		for (nfiles = 0, i = 1; i < argc; ++i) {
			if ((p = argv[i]) == NULL)
				continue;
			if ((fp = fopen(p, bflag ? "rb" : "r")) == NULL)
				perror(p);
			else {
				++nfiles;
				setvbuf(fp,NULL,_IOFBF,BUFSIZE*10);
				count(fp, p);
				fclose(fp);
			}
		}
	}
	if (nfiles > 1)
		output(tlines, twords, tbytes, twidest, tpages, "=total=");
}
