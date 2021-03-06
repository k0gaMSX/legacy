#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <conio.h>
#include "make.h"
int fmake(char *);
int examine(FILENODE *, DATE);
extern int laterdt(DATE,DATE);
extern int undefmac(char *);

#define SCRIPTFILE "make$$$$.bat"       /* (default) script-listing file */
#define	INIT	"~INIT"			/* initialization macro */
#define	DEINIT	"~DEINIT"		/* de-init macro */
#define	BEFORE	"~BEFORE"		/* the per-root 'startup' method */
#define	AFTER	"~AFTER"		/* the per-root 'wrapup' method */

MACRO *mroot = NULL;		/* root of macro-list */
FILENODE *froot = NULL; 	/* root of filenode-list */
FILENODE *firstf = NULL;	/* the very first filenode */
FILE *mkfp = NULL;		/* script file */
extern int modcount;
extern int debug;
extern int obsolete;
extern int noscript;
extern int noexec;
extern char *modnames[MAXMODS]; /* module-names mentioned in commandline */
extern char *scriptf;		/* default script file */

#define endoftime ULONG_MAX	/* a date, the very last possible */


/*
 * Construct dependency tree from the makefile 'fn'.
 * Figure out what has to be recompiled, and write a script file to do that.
 */

fmake(fn)
char *fn;
{
	FILE *fp;

	if((fp = fopen(fn, "r")) == NULL) return -1;

	fparse(fp);
	determ();

	fclose(fp);
	return 0;
}


/*
 * Parse the input file, defining macros and building the dependency tree.
 */
fparse(fp)
FILE *fp;
{
	char *strp, *tok1, *tok2, *s;
	FILENODE *lastf = NULL;
	char ibuf[STRSIZ], ebuf[STRSIZ];
/*	  FILENODE *sf; */

	for(;;)
	{
		if(fgets(ibuf, STRSIZ, fp) == NULL) break;
		mexpand(ibuf, ebuf, STRSIZ, MACCHAR);
		escape(ebuf, COMCHAR);

			/* clobber last newline in string */
		s = ebuf + strlen(ebuf) - 1;
		if(s >= ebuf && *s == '\n') *s = '\0';

		if(*ebuf == '\t')
		{
			addmeth(lastf, ebuf+1);
			continue;
		}

		strp = ebuf;
		if((tok1 = token(&strp)) == NULL) continue;
		if((tok2 = token(&strp)) != NULL)
			if(!strcmp(tok2, DEFMAC))
			{
				if(*strp) defmac(tok1, strp);
				else if(undefmac(tok1) < 0)
				    fprintf(stderr,
					  "Can't undefine macro '%s'\n", tok1);
				continue;
			}
			else if(!strcmp(tok2, DEPEND))
			{
				addmeth(lastf, gmacro(AFTER));

				lastf = filenode(tok1);
				if(firstf == NULL) firstf = lastf;
				lastf->fmake = NULL;

				addmeth(lastf, gmacro(BEFORE));

				lastf->fflag |= ROOTP;
				while((tok1 = token(&strp)) != NULL)
					addfile(lastf, tok1);
				continue;
			}
			else addfile(lastf, tok2);

		do {
			addfile(lastf, tok1);
		} while((tok1 = token(&strp)) != NULL);
	}

	addmeth(lastf, gmacro(AFTER));
}


/*
 * Determine sequence of recompiles from the creation dates.
 * If there is anything to recompile, then create a script file full of commands.
 */
determ()
{
	FILENODE *f;
	int i;
	char *m;

	if(firstf == NULL)			/* empty tree */
	{
		printf("No changes\n");
		noexec=1;
		return;
	}

	if(modcount == 0) examine(firstf, endoftime);
	else for(i = 0; i < modcount; ++i)
	{
		if((f = gfile(modnames[i])) == NULL)
		{
			fprintf(stderr, "Can't find root '%s'.\n", modnames[i]);
			continue;
		}

		if((f->fflag & ROOTP)== 0)
		{
			fprintf(stderr, "'%s' is not a root!\n", f->fname);
			continue;
		}
		examine(f, endoftime);
	}

	if(mkfp != NULL)
	{
		if((m = gmacro(DEINIT)) != NULL)
		{
			fputs(m, mkfp);
			fputc('\n', mkfp);
		}
		fclose(mkfp);
	} else {
	    printf("No changes\n");
	    noexec=1;
	    }
}


/*
 * Examine filenode 'fnd' and see if it has to be recompiled.
 * 'date' is the last-touched date of the node's father
 * (or 'endoftime' if its a root file.)
 * Root files with NO dependencies are assumed not to be up to date.
 */
examine(fnd, date)
FILENODE *fnd;
DATE date;
{
	int rebuildp = 0;
	NODE *n;

	getdate(fnd);

	if(fnd->fnode == NULL && fnd->fflag & ROOTP)
		rebuildp = 1;
	else for(n = fnd->fnode; n != NULL; n = n->nnext)
		if(examine(n->nfile, fnd->fdate)) rebuildp = 1;

	if(rebuildp) recomp(fnd);
	if(obsolete || laterdt(fnd->fdate, date) >= 0)
		rebuildp = 1;
	return rebuildp;
}


/*
 * Make sure a filenode gets recompiled.
 */
recomp(f)
FILENODE *f;
{
/*	  FILENODE *sf; */
	char *m;

	if(mkfp == NULL)
	{
		if(noscript) mkfp = stdout;
		else if((mkfp = fopen(scriptf, "w")) == NULL)
			{
			  fprintf(stderr, "Cannot create: '%s'\n", scriptf);
			  noexec=1;
			}

	if((m = gmacro(INIT)) != NULL)
		{
			fputs(m, mkfp);
			fputc('\n', mkfp);
		}
	}

	if(f->fflag & REBUILT) return;
	if(f->fmake != NULL) fputs(f->fmake, mkfp);
	f->fflag |= REBUILT;
}




/*
 * Complain about being out of memory, and then die.
 */
allerr() {
	fprintf(stderr, "Can't alloc -- no space left (I give up!)\n");
	noexec=1;
	exit(1);
}


cmdrun(s)			/* Return to MSXDOS */
char *s;
{
#asm
	psect	text
	ld	l,(ix+6)
	ld	h,(ix+7)	; hl = char * s
	ld	a,(hl)
	or	a		; if NULL
	jp	z,cret		; quit it
	push	hl
	ld	ix,0156h	; bios function kilbuf
	ld	iy,(0fcc0h)
	call	001ch
	pop	hl
	ld	de,0fbf0h	; keybuf
	ld	(0f3fah),de	; getpnt
	ld	b,38
kopie:	ld	a,(hl)
	or	a
	jr	z,klaar
	cp	'.'
	jr	z,klaar
	ldi
	djnz	kopie
klaar:	ld	a,13		; end with a <CR>
	ld	(de),a
	inc	de
	ld	(0f3f8h),de	; putpnt
	ld	a,(0f313h)
	or	a
	jp	z,0		; if DOS1
	ld	bc,0062h
	call	5		; if DOS2
#endasm
}
                                                                               