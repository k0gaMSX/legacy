/*
 *	Editor Routines for TELED package (see TELED.C)
 */

#include <bdscio.h>
#include <hardware.h>
#include "teledit.h"

#if !EDITOR

ed(lineptr)
{
	puts("Edit function not implemented in this object version.\n");
	puts("See the \"#define EDITOR\" line in TELEDIT.H to enable it.\n");
}

#else

ed(lineptr)	/* editor */
char **lineptr;
{
	char in, *inl[ML], *p, buf[BUFSIZ];
	int i, j, k, l;
	char *getm(), *alloc();

	if(!fflg)
	{	printf("\n\7No text buffer to edit.\n");
		return;
	}

	printf("\nedit\n*");
	nl = 22;

	while (in = getchar())
	   switch (tolower(in)) {

		case 'a':
			puts("Filename to yank = ");
			if(fopen(getname(linebuf), buf) == ERROR) {
				printf ("\r  Cannot open %s.\r*", linebuf);
				continue;
			}

			for(i = 0; fgets(linebuf, buf); i++) {
				inl[i] = getm(linebuf);
				if(inl[i] == NULL) break;
			}

			inl[i] = NULL;
			iblock(lineptr, inl, linect);
			show (lineptr, linect, nl);
			continue;

		case 'b':
			linect = 0;
			show (lineptr, linect, nl);
			continue;

		case 'q':
			printf(CLEARS);
			return;

		case 'f':
			gets(linebuf);
			if((i = find(lineptr, linect)) >= 0) {
				linect = i;
				show (lineptr, linect, nl);
			}
			else if((i = find(lineptr, 0)) >= 0) {
				linect = i;
				show (lineptr, linect, nl);
			}
			else
			{
				printf(HC);
				printf("  not found\r*");
			}
			continue;

		case 'i':
			j = min(linect, 5);
			if(j == 0)
				printf(CLEARS);
			else {
				show(lineptr, (linect - j), j);
				j++;
				printf("\b ");
				for(; j; j--)
					putchar('\n');
			}
			while(1) {
				gets(linebuf);
				for(i = 0; linebuf[i]; i++)  
					if(linebuf[i] == CPMEOF)  
						break;
				if(linebuf[i] == CPMEOF) break;
				linebuf[i++] = '\n';
				linebuf[i] = NULL;
				inl[j++] = getm(linebuf);
			}
			inl[j] = NULL;
			iblock(lineptr, inl, linect);
			show (lineptr, linect, nl);
			continue;

		case 'k':
			putchar('\n');
			show1(lineptr, linect);
			kill(lineptr, linect, 1);
			continue;

		case 'l':
			gets(linebuf);
			if((i = lfind(lineptr, linect)) >= 0) {
				linect = i;
				show(lineptr, linect, nl);
			}
			else if((i = lfind(lineptr, 0)) >= 0) {
				linect = i;
				show(lineptr, linect, nl);
			}
			else {
				printf(HC);
				printf("  not found\r*");
			}
			continue;

		case 'o':
			putchar('\n');
			i = linect;
			while(gets(linebuf)) {
				for(j = 0; linebuf[j]; j++)
					if(linebuf[j] == CPMEOF) break;
				if(linebuf[j] == CPMEOF) break;
				linebuf[j++] = '\n';
				linebuf[j] = NULL;
				if(lineptr[i])
					free(lineptr[i]);
				lineptr[i++] = getm(linebuf);
				if(i > nlines) lineptr[++nlines] = NULL;
			}
			show (lineptr, linect, nl);
			continue;

		case 'p':
			linect = min((linect + nl), nlines);
			show (lineptr, linect, nl);
			continue;

		case 's':
			gets(linebuf);
			nl = max((atoi(linebuf)), 1);
			show (lineptr, linect, nl);
			continue;

		case 'z':
			linect = nlines;
			show(lineptr, linect, nl);
			continue;

		case '1': case '2': case '3': case '4': case '5':
		case '6': case '7': case '8': case '9': case '-':
			linebuf[0] = in;
			for (i = 1; (isdigit(in = getchar())); i++)
				linebuf[i] = in;
			linebuf[i] = NULL;
			i = atoi(linebuf);
			if (i < 0)
				j = max((linect + i), 0);
			else
				j = min((linect + i), nlines);
			in = tolower(in);
			if(j > linect && in == 'k')
				kill(lineptr, linect, (j - linect));
			else
				linect = j;
			if (in == 'p') linect = max((linect-nl), 0);
			show (lineptr, linect, nl);
			continue;

		case '#':
			printf (" of lines: %d\r*", nlines);
			continue;

		case '\n':
			if (lineptr[linect] != NULL) {
				show1(lineptr, linect);
				linect++;
			}
			else
				printf (HC);
			continue;

		case ' ':
			if(linect)
				linect--;
			show(lineptr, linect, nl);
			continue;

		case ('E'&037):
			send(in);
			printf("\n^E sent\n");
			return;

		default:
			printf(" ?\r*");
		}
}

find(lineptr, linect)	/*Find a line having the pattern in linebuf        */
char *lineptr[];
int linect;
{
	int i;

	for(i = linect; lineptr[i] != NULL; i++)
		if(pat(lineptr[i], linebuf) >= 0)
			return(i);
	return(-1);
}

kill(lineptr, linect, nl)	/* erase lines */
char *lineptr[];
int linect, nl;
{
	int i, j;

	for (i = linect; lineptr[i] != NULL && nl > 0; i++, nl--) {
		free(lineptr[i]);
		nlines--;
	}
	lineptr[linect] = NULL;
	if(lineptr[i] != NULL) {
		j = (nlines - linect) * 2;
		movmem(&lineptr[i], &lineptr[linect], j + 2); 
	}
}

lfind(lineptr, linect) 		/* find pattern at beginning of a line */
char *lineptr[];
int linect;
{
	int i, j;
	char line[MAXLINE];

	j = strlen(linebuf);
	for (i = linect; lineptr[i] != NULL; i++) {
		strcpy(line, lineptr[i]);
		line[j] = NULL;
		if(strcmp(line, linebuf) == 0)
			return i;
	}
	return -1;
}
	

pat(s, t)	/* pattern match..*/
char s[], t[];
{
	int i, j, k;

	for(i = 0; s[i] != '\0'; i++)
	   {
		for(j = i, k=0; t[k] != '\0' && s[j] == t[k]; j++, k++)
			;
		if(t[k] == '\0')
			return(i);
	   }
	return(-1);
}

show (lineptr, linect, nl)	/* screen current frame */
char *lineptr[];
int linect, nl;
{
	int i;

	printf (CLEARS);
	putchar('\n');

	for (i = linect; i < (linect+nl) && lineptr[i] != NULL; i++)
		printf("%s", lineptr[i]);
	printf (HC);
	return(i);
}

show1(lineptr, linect)
char **lineptr;
int linect;
{
	int i;

	for(i = 0; i < nl; i++)
		putchar('\n');

	if((linect + nl) >= nlines)
		putchar('\n');
	else
		printf("%s", lineptr[linect+nl]);

	printf(HC);

	for(i = 0; i < 78; i++)
		putchar(' ');

	printf("\r*");
}

iblock(rb, ib, cl)		/* insert block ib into rb at cl */
char *rb[], *ib[];
int cl;
{
	int i, j;

	j = 0;
	if (rb[cl]) {
		for (i = 0; ib[i]; i++)
			;
		j = (nlines - cl) * 2;
		movmem (&rb[cl], &rb[cl+i], j + 2);
	}
	for (i = 0; ib[i]; i++, cl++)
		rb[cl] = ib[i];
	if(!j) rb[cl] = NULL;
	nlines += i;
	return cl;	/* return new current line */
}

#endif
