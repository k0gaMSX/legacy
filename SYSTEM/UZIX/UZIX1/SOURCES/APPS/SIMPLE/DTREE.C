/*
 *	DTREE - Print the tree structure of a directory
 *	4/7/83 name was changed from TREE to DTREE
 *	9/7/83 mods for 4.1c and 4.2 dirctory structure added
 *
 *	Dave Borman, Digital Unix Engineering Group
 *		decvax!borman
 *	Originally written at St. Olaf College, Northfield MN.
 *	Copyright (c) 1983 by Dave Borman
 *	All rights reserved
 *	This program may not be sold, but may be distributed
 *	provided this header is included.
 *
 *	Compile: PDP V7 w/split i&d    cc -O dtree.c -i -n -o dtree
 *		 VAX 4.1bsd	       cc -O dtree.c -n -o dtree
 *		 VAX 4.2bsd	       cc -O -DNEWDIR -DLINK dtree.c -n -o dtree
 *
 *	Usage:	dtree -[adfglnpsvx] [-b filenamesize] [-c linelength] [top]
 *	Flags:	-a) include non-directory entries in listing
 *		-d) sort tree with directories at the top
 *		-f) sort tree with files at the top
 *		-g) same as l, but use group name instead of user name
 *		-l) print stats with each listing
 *		    if both g & l flags are given, both owner and
 *		    group will be printed
 *		-n) do not sort the tree
 *		-p) include files starting with a '.' (except "." & "..")
 *		-s) use shorter stats. Implies -l if -g isn't given.
 *		-v) variable length columns off
 *		-x) do not cross mounted file systems.
 *              -b length) big directory names (define the max. name length)
 *		-c length) set max column length to "length" (if col.
 *                         length > file name length, this implies -b also)
 */
	
 /*     Modified by      Ed Arnold      CSU-CS   (csu-cs!arnold)     3-5-84
  *
  *     Allows symbolic links to both directories and individual files.
  *     With a '-l' or '-al' option, links are denoted with a 'l' in front of 
  *     file or directory permissions. In all other instances both links to 
  *     directories and files are represented just as files are. Contents of
  *     linked directories are not printed due to the possibility of 
  *     recursively linked directories.
  *
  *     Big directory name option added by:
  *                      Mike Vevea      CSU-CS (csu-cs!vevea)      3-22-84
  *	Toggle sense of -v (running 4.2), and eliminate some extraneous
  *		print info	Mike Meyer Energy Analysts (mwm@ea)	4/17/84
  *	Fix the exit status to correctly indicate what happened.
  *				Mike Meyer Energy Analysts (mwm@ea)	4/23/84
  *
  *   12/07/92  	adapted for UZI280 by Stefan Nitschke
  *			- sbrk() instead of malloc()
  *   05/10/99  	adapted for UZX by Adriano Cunha
  *			- malloc() check / downsizing / readdir
  */

	
#define STATS	/* comment out to remove stats, giving more core space	*/
		/* and thus the ability to tree larger tree structures	*/
		/* on PDP 11/70s */
	
#define	NEWDIR	/* directory structure ala Berkeley 4.1c or 4.2 */
 
	
#define LINK    /* allows links to be processed in Berkeley 4.2 version 
                      NEWDIR must be defined as well as LINK */

static	char Sccsid[]="@(#)dtree.c	2.3	2/14/84";
	
#ifdef LINK
static  char Rcsid[] ="$Header: /mnt/ntape/RCS/dtree.c,v 1.2 84/04/23 10:33:41 root Exp $";
#endif LINK

#include	<stdlib.h>	
#include	<stdio.h>
#include	<types.h>
#include	<sys/stat.h>
#include	<string.h>
#include	<unistd.h>
#ifdef	STATS
# include	<pwd.h>
# include	<grp.h>
#endif	STATS
#ifdef	NEWDIR
# include	<dirent.h>
#else
# include	<dir.h>
#endif	NEWDIR

#ifdef MSX_UZIX_TARGET
#define DEFDIRSIZ	64
#else
#define	DEFDIRSIZ	255
#endif

#define DEFCOLWID       14

#ifndef MAXNAMLEN
# define MAXNAMLEN      DEFCOLWID
#endif
	/*
	 * TWIDDLE is a fudge factor.  It should be declared so that
	 * sizeof(struct Entry) is on a nice boundry.
	 */
#define	TWIDDLE	1
	
#define	addr(b,o) ((struct Entry *)((unsigned int)(b)+(o)*(sizeof(struct Entry)+Length)))
#define	SIZEOFentry	(sizeof(struct Entry)+Length)
	
#define	DEPTH	10	/* maximum depth that dtree will go */

#ifdef MSX_UZIX_TARGET
#define MAX	40
#else
#define	MAX	160	/* initial # of elements for list of files */
#endif

#define	PWD	"/bin/pwd"	/* program to get name of current dir */
#define	DATE	"/bin/date"	/* program to print current date */
	
#define	FFIRST	2	/* sort files first */
#define DFIRST	1	/* sort directories first */
#define	FAIL	-1	/* failure return status of sys calls */
#define	GREATER	1	/* return value of strcmp if arg1 > arg2 */
#define	LESSTHAN -1	/* return value of strcmp if arg1 < arg2 */
#define	SAME	0	/* return value of strcmp if arg1 == arg2 */
	
	int	Index = 0;		/* current element of list[]	*/
	int	Length = DEFDIRSIZ;	/* max length of a dir. name    */
	int     CLength = DEFDIRSIZ;    /* max length of a column       */
	int	All = 0;		/* all != 0; list non-directory entries */
	int	File_dir = 0;		/* flag for how to sort */
	int	Sort = 1;		/* flag to cause sorting of entries */
	int	Point = 1;		/* skip point files if set	*/
	int	Maxes[DEPTH];		/* array keeps track of max length in columns */
	int	Level = 0;		/* counter for how deep we are	*/
	int	Device;			/* device that we are starting tree on */
	int	Xdev = 1;		/* set to allow crossing of devices */
	int	Varspaces = 1;		/* set to allow compaction of column width */
#ifdef	STATS
	int	Gflag = 0;		/* set for group stats instead of owner */
	int	Longflg = 0;		/* set for long listing */
	int	Compact = 0;		/* set for shortened long listing */
#endif	STATS
	struct	stat Status;
#ifdef  LINK
	struct  stat Lstat;   /* stat of link, if there is one */
#endif  LINK

#ifndef _PROTOTYPE
#define _PROTOTYPE(x,y)		x y
#endif

_PROTOTYPE(int main, (int argc, char **argv));
_PROTOTYPE(int stln, (char *st));
_PROTOTYPE(void pt_tree, ());
_PROTOTYPE(int t_search, (char *dir, struct Entry *addrs));
_PROTOTYPE(int compar, (struct Entry *a, struct Entry *b));
	
struct Entry {
	int next;			/* index to next element in list */
					/* could be a ptr, but realloc() */
					/* might screw us then */
#ifdef	STATS
	off_t	e_size;			/* size in blocks */
 	short	e_mode;			/* file mode */
	short	e_uid;			/* uid of owner */
	short	e_gid;			/* gid of owner */
#endif	STATS
	short dir;			/* Entry is a directory */
	short last;			/* last Entry in the dir. */
	short dev;			/* set if same device as top */
	short end;			/* index of last subdir Entry*/
	char  e_name[TWIDDLE];		/* name from directory Entry */
					/* it will actually be larger */
} *List, *SaveList;
	
unsigned int Size;			/* how big of space we've malloced */
	
char	*Spaces;	/* used for output */
char	Buf1[BUFSIZ];	/* buffers for stdio stuff.  We don't want	*/
/*char	Buf2[BUFSIZ];	/* anyone calling malloc, because then	*/
/*char	Buf3[BUFSIZ];	/* realloc() will have to move the whole list	*/
	
int	dir = 1;		/* Entry is a directory */
int	last = 1;	/* last Entry in the dir. */
int	dev = 1;		/* set if same device as top */
int	end = 13;	/* index of last subdir Entry*/
	
	
main(argc, argv)
char	**argv;
int	argc;
{
	register int i, j = 0;
	int	flag = 0;	/* used to jump over 'c' argument */
	char	top[128];	/* array for treetop name */
	char	home[128];	/* starting dir for multiple trees */
	char	*ptr;
	

	setbuf(stdout, Buf1);
	
	for (j=1; j<argc; j++) {
		if (flag) {	/* saw a 'c' or 'b', so jump over value */
			if (flag > 1) j += flag-1;
			flag = 0;
			continue;
		}
		if (argv[j][0] == '-') {
			for (i = 1; i < strlen(argv[j]); i++) {
				switch (argv[j][i]) {
				case 'a':
					All = 1;
					break;
				case 'b':
					Length = atoi(argv[j+1+flag]);
						if (Length > MAXNAMLEN)
							Length = MAXNAMLEN;
						else if (Length < 1)
							Length = DEFCOLWID;
						flag += 1;
						break;
					case 'c':
						CLength = atoi(argv[j+1+flag]);
						if (CLength > MAXNAMLEN)
							CLength = MAXNAMLEN;
						else if (CLength < 1)
							CLength = DEFCOLWID;
						if (Length < CLength) Length = CLength;
						flag += 1;
						break;
					case 'd':
						File_dir = DFIRST;
						break;
					case 'f':
						File_dir = FFIRST;
						break;
					case 'n':
						Sort = 0;
						break;
					case 'p':
						Point = 0;
						break;
					case 'v':
						Varspaces = 0;
						break;
					case 'x':
						Xdev = 0;
						break;
#ifdef	STATS
					case 'g':
						Gflag = 1;
						break;
					case 'l':
						Longflg = 1;
						break;
					case 's':
						Compact = 1;
						break;
#endif	STATS
					default:
						fprintf(stderr,
							"Bad flag: %c\n", argv[j][i]);
						fprintf(stderr,
#ifdef	STATS
			"usage: dtree -[adfglnpsvx] [-b filenamesize] [-c linelength] [directory ... ]\n");
#else	STATS
			"usage: dtree -[adfnpvx] [-b filenamesize] [-c linelength] [directory ... ]\n");
#endif	STATS
						exit(FAIL);
					}
				}
			} else
				break;
		}
	
		/* Establish where we are (our home base...) */
		getcwd(home,128);	


		if ((Spaces = malloc(Length+2)) == NULL) {
			fprintf(stderr, "dtree: out of memory (%d bytes)\n", Length+2);
			exit(1);
		}
		for(i = 0; i < Length + 1; i++)
			Spaces[i] = ' ';
		Spaces[i] = '\0';
	
		/* Get initial Storage space */
		Size = SIZEOFentry * MAX;

		if ((SaveList = (struct Entry *)malloc(Size)) == NULL) {
			fprintf(stderr, "dtree: out of memory (%u bytes)\n", Size);
			exit(1);
		}
/*	
		SaveList = (struct Entry *)sbrk(Size);	
*/
		/* adjust for no specified directory */
		if (j == argc)
			argv[--j] = ".\0";
	
		/* walk down the rest of the args, treeing them one at at time */
		for (; j < argc; j++) {
			if (chdir(home) == -1) {
				fprintf(stderr, "Can't chdir back to %s\n", home);
				exit(1);
			}
			sprintf(top, "%s", argv[j]);
	
			if (chdir(top) == FAIL) 
			{
				fprintf(stderr, "Can't chdir to %s\n", top);
				continue;
			} 
			else 
			{
				getcwd(top,128);
				ptr = top;
/*				while (*ptr && (*ptr != '\n'))
					ptr++;
				*ptr = '\0';
				pclose(istr); 
*/
		}
	
		List = SaveList; Index = 0;
		ptr = rindex(top, '/');
	
		if (!ptr || *++ptr == '\0')
			sprintf(addr(List,Index)->e_name, "%s", top);
		else
			sprintf(addr(List,Index)->e_name, "%s",  ptr);

		if(stat(top, &Status) == FAIL) {
			fprintf(stderr, "Can't stat %s\n", top);
			continue;
		}
		Device = Status.st_dev;
		addr(List,0)->dir = 1;
		addr(List,0)->last = 1;
		addr(List,0)->next = 1;
		Index = 1;
		for (i = 1; i < DEPTH; i++)
			Maxes[i] = 0;
		Maxes[0] = stln(addr(List,0)->e_name);
		Level = 1;
	
		/* search the tree */
		addr(List,0)->end = t_search(top, addr(List,0));

		if (Index == 1)				/* empty tree */
			addr(List,0)->next = 0;
	
		if (All)
		    printf("\nDirectory structure and contents of %s\n", top);
		else
		    printf("\nDirectory structure of %s\n", top);
		if (Point)
			printf("(excluding entries that begin with '.')\n");
		pt_tree();				/* print the tree */
	}
	exit(0) ;
}
	
	
t_search(dir, addrs)
char *dir;
struct	Entry *addrs;
{
	int	bsort;			/* index to begin sort */
	int	stmp;			/* save temporary index value */
	struct Entry *sstep;		/* saved step in list */
	int	nitems;			/* # of items in this directory */
	DIR	*dirp;
	char	sub[MAXNAMLEN+1];	/* used for subdirectory names */
	int	i;
	struct  dirent direntry;
	struct  dirent *dp = &direntry;
	int	n_subs = 0;
	int	tmp = 0;
	
	dirp = opendir(".");
	if (dirp == NULL) {
		fprintf(stderr, "Cannot open %s\n", dir);
		return(0);
	}
/*	setbuf(dirp, Buf3);*/
	
	bsort = Index;
	sstep = addr(List,bsort); /* initialize sstep for for loop later on */
	nitems = Index;
	/* get the entries of the directory that we are interested in */
	while ((dp = readdir(dirp)) != NULL ) {	
		if (!dp->d_ino
		    || (strcmp(dp->d_name, ".") == SAME)
		    || (strcmp(dp->d_name, "..") == SAME)
		    || (Point && dp->d_name[0] == '.'))
				continue;
	
		sprintf(sub, "%s", dp->d_name);
		if ((tmp = stat(sub, &Status)) == FAIL) {
			fprintf(stderr, "%s:stat can't find\n", sub);
			continue;
		}
		else if ((Status.st_mode & S_IFMT) == S_IFDIR)
			addr(List,Index)->dir = 1;
		else if (All)
			addr(List,Index)->dir = 0;
		else
			continue;
		sprintf(addr(List,Index)->e_name, "%s", dp->d_name);
		addr(List,Index)->last = 0;
		addr(List,Index)->end = 0;
	        addr(List,Index)->dev = (Device == Status.st_dev);
		if (stln(addr(List,Index)->e_name) > Maxes[Level])
			Maxes[Level] = stln(addr(List,Index)->e_name);
		++Index;
		if (Index*SIZEOFentry >= Size) {
			Size += 20*SIZEOFentry;
			if (!(List =
			    (struct Entry *)realloc((char *)List, Size))) {
				fprintf(stderr, "Out of space\n");
				break;
			}
			fprintf(stderr, "Out of space\n");
			break;
		}
	}
	closedir(dirp);
	nitems = Index - nitems;	/* nitems now contains the # of */
					/* items in this dir, rather than */
					/* # total items before this dir */
	if (Sort)
		qsort(addr(List,bsort),nitems,SIZEOFentry,compar);
	addr(List,Index-1)->last = 1;	/* mark last item for this dir */
	n_subs = nitems;
	stmp = Index;
	/* now walk through, and recurse on directory entries */
	/* sstep was initialized above */
	for (i = 0; i < nitems;	sstep = addr(List,stmp - nitems+(++i))) {
		if (sstep->dir && (Xdev || sstep->dev)) {
			sstep->next = Index;
			sprintf(sub, "%s", sstep->e_name);
			tmp = n_subs;
			Level++;
			if (chdir(sub) == FAIL)
				fprintf(stderr,
					"Can't chdir to %s/%s\n", dir, sub);
			else {
				n_subs += t_search(sub, sstep);
				if (chdir("..") == FAIL) {
					fprintf(stderr,
						"No '..' in %s/%s!\n",dir, sub);
					exit(1);
				}
			}
			--Level;
			if (n_subs - tmp <= 0)
				sstep->next = 0;
			else
				--n_subs;
		}
		else
			sstep->next = 0;
	}
	addrs->end = (unsigned)n_subs;
	return(n_subs);
}
	
/*
 *	comparison routine for qsort
 */
	
int compar(a, b)
struct Entry *a, *b;
{
	if (!File_dir)		/* straight alphabetical */
		return(strncmp(a->e_name, b->e_name, Length));

	/* sort alphabetically if both dirs or both not dirs */
	
	if ((a->dir && b->dir) || (!a->dir && !b->dir))
		return(strncmp(a->e_name, b->e_name, Length));

	if (File_dir == FFIRST) {	/* sort by files first */
		if (a->dir)
			return(GREATER);
		else
			return(LESSTHAN);
	}
	
	if (a->dir)			/* sort by dir first */
		return(LESSTHAN);
	else
		return(GREATER);
}
	
	
void pt_tree()
{
	register int	i,j;
	struct Entry *l;
	struct Entry *hdr[DEPTH];
	int posit[DEPTH];		/* array of positions to print dirs */
	int con[DEPTH];			/* flags for connecting up tree */
	char	flag;			/* flag to leave blank line after dir */
	struct	Entry *stack[DEPTH];	/* save positions for changing levels */
	int	top = 0;		/* index to top of stack */
	int	count = 1;		/* count of line of output */
	int	n;
	Level = 0;			/* initialize Level */

	/* this loop appends each Entry with dashes or spaces, for */
	/* directories or files respectively */

	for (i = 0; i < Index; i++) {
		for (j = 0; j < Length; j++) {
			if (!addr(List,i)->e_name[j])
				break;
		}
		if (addr(List,i)->dir) {
				addr(List,i)->e_name[j] = '-';
		} else {
				addr(List,i)->e_name[j] = ' ';
		}
	}

	/* adjust the Maxes array according to the flags */
	
	for (i = 0; i < DEPTH; i++) {
		if (Varspaces) {
			if (Maxes[i] > CLength )
				Maxes[i] = CLength;
		} else
			Maxes[i] = CLength;
	}
	
	/* clear the connective and position flags */

	for (i = 0; i < DEPTH; i++)
		con[i] = posit[i] = 0;

	/* this is the main loop to print the tree structure. */
	l = addr(List,0);
	j = 0;
	for (;;) {
		/* directory Entry, save it for later printing */
		if (l->dir != 0 && l->next != 0) {
			hdr[Level] = l;
			posit[Level] = count + (l->end + 1)/2 - 1;
			flag = 1;
			stack[top++] = l;
			l = addr(List,l->next);
			++Level;
			continue;
		}
	
	/* print columns up to our Entry */
	for (j = 0; j < (flag ? Level-1 : Level); j++) {
		if (!flag && posit[j] && posit[j] <= count) {
		/* time to print it */
		if (hdr[j]->e_name[CLength-1] != '-')
			hdr[j]->e_name[CLength-1] = '*';
			printf("|-%s",hdr[j]->e_name);
			if (strlen(hdr[j]->e_name)<Maxes[j])
				for(n=0;n<(Maxes[j]-strlen(hdr[j]->e_name));n++)
					putchar('-');
			posit[j] = 0;
			if (hdr[j]->last != 0)
			    con[j] = 0;
			else
			    con[j] = 1;
		} 
		else
		{
			if (con[j]) putchar('|');
			else putchar(' ');
			putchar(' ');
			for (n=0;n<Maxes[j];n++)
			putchar(' ');
		}
	}
		if (flag) {	/* start of directory, so leave a blank line */
			if (con[j]) putchar('|');
			putchar('\n');
			flag = 0;
			continue;
		} else {
				/* normal file name, print it out */
			if (l->e_name[CLength-1] != '-' &&
			    l->e_name[CLength-1] != ' ')
			    l->e_name[CLength-1] = '*';
			printf("|-%s",l->e_name);
			if (l->last) {
				con[j] = 0;
			} else {
				con[j] = 1;
			}
		}
		putchar('\n');
	
		if (l->last) {  
			/* walk back up */
			while (l->last) {
				--Level;
				if (--top <= 0)
					return;
				l = stack[top];
			}
		}
		l = addr(l,1);
		++count;
	}
}
	
	
/* stln - sortof like strlen, returns length up to Length-1 */
int stln(st)
register char *st;
{
	register int t;

	for (t=0; t<Length-1; ++t)
		if (!st[t])
			return (++t);
	return (++t);
}

#ifdef NO_RINDEX
/*
 * Return a pointer into str at which the character
 * c last appears; NULL if not found.
*/
	
char *
rindex(str, c)
register char *str, c;
{
	register char *ptr;

	ptr = NULL;
	do {
		if (*str == c)
			ptr = str;
	} while (*str++);
	return(ptr);
}
#endif
