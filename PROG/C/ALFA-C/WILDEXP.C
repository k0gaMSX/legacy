/*
	WILDEXP.C 	v2.0	5/10/84
	Alpha-C Command-line Wild-card expansion utility.

	Written by Leor Zolman. Various sections of the code were
	added/fixed by:
		W. Earnest, Dave Hardy, Gary P. Novosielski,
		Bob Mathias and others (thanks, y'all!)

	New for v2.0:
		User area prefixes on wildcards are now permitted;
		'*' or '?' as user number searches ALL user areas (0-15).
		As usual by Alpha-C convention: if both a drive spec and a
		user area prefix are used with the same file spec, then
		the user area prefix must be first.

	General Description:

	WILDEXP lets ambiguous file names appear on the command line to C
	programs, automatically expanding the parameter list to contain
	all files that fit the afn's.

	An afn preceded by a "!" causes all names matching the given afn to
	be EXCLUDED from the resulting expansion list. Thus, to yield a
	command line containing all files except "COM" files, you'd say:

		A>progname !*.com <cr>

	(If a single "!" spec is the only parameter on the command line,
	then an implicit "*.*" is assumed to have preceded it.)

	Another example: to get all files on B: except .C files, say:

		A>prognam b:*.* !b:*.c <cr>

	When giving a "!" afn, "*" chars in the string matches to the end of
	either the filename or extension, just like CP/M, but "?" chars match
	ONE and ONLY ONE character in either the filename or extension.


	To use WILDEXP, begin your "main" function as follows:

	---------------------------------------------
	main(argc,argv)
	char **argv;
	{
		...			     /* local declarations  */
		wildexp(&argc,&argv, sys);   /* perform wildexp expansions */
		dioinit(&argc,argv);	     /* if using DIO, put this here */
 		.
		.
		.
	---------------------------------------------

	"sys" tells WILDEXP whether or not to recognize "system" (invisible)
	files during ambiguous file name expansions. If true (non-zero), then
	system files are seen, otherwise not. See the "CP.C" program for an
	example of how a command line option can be used to control this
	feature  of WILDEXP.

	Link WILDEXP.CRL in with your program by including it on the CLINK
	command line. That's all there is to it.

	Note that "wildexp" uses the "sbrk" function to obtain storage,
	so don't go playing around with memory that is outside of the
	external or stack areas unless you obtain the memory through "sbrk"
	or "alloc" calls.
*/

#include	<bdscio.h>
#define		MAXITEMS	512	/* max no. of items after expansion */
#define		SEARCH_FIRST	17	/* BDOS calls */
#define		SEARCH_NEXT	18
#define		SET_DMA		26

wildexp(oargcp, oargvp, sysflag)
int	*oargcp;		/* pointer to old argc */
char	***oargvp;		/* pointer to old argv */
int	sysflag;		/* TRUE to include system (invisible) files */
{
	int	nargc;		/* new argc */
	char	**nargv;	/* new argv */
	char	**oargv;	/* old argv */
	int	oargc;		/* old argc */
	char	fcb[36];	/* fcb used for search for first/next calls */
	char	dmapos;		/* value returned by search calls */
	char	first_time;	/* used in search routine */
	char	tmpfn[20],	/* temp filename buffer */
		*tmpfnp;
	char 	tmpfn2[25];
	char	*notfns[20];	/* list of !<afn> entries */
	int	notcount;	/* count of entries in notfns */

	char	cur_drive;	/* currently logged drive */
	char 	cur_usr;	/* currently logged user area */
	int	first_usr;	/* range of user areas in which to search */
	int	last_usr;	/* for a given wild-card filename */
	int	exp_usr;	/* explicit user area prefix given? */

	char	*str;
	int	i,j,k;

	bdos(SET_DMA, 0x80);		/* set default DMA address */

	cur_drive = bdos(25);		/* get current drive	*/
	cur_usr = bdos(32, 0xff);	/* and user area	*/

	oargv = *oargvp;
	oargc = *oargcp;
	nargc = 1;
	notcount = 0;

	if ((nargv = sbrk(MAXITEMS * 2 + 4)) == ERROR)
		return ERROR;

	for (i = 1;(nargc <= (MAXITEMS+1)) && i < oargc; i++)
	{
		first_usr = last_usr = cur_usr;
		tmpfnp = tmpfn;
		str = oargv[i];
		if (*str == '!') {
			if (i == 1) {
				oargv[oargc] = "*.*";
				oargc++;
			}				
			notfns[notcount++] = &oargv[i][1];
		}
		else if (!haswild(str))
			nargv[nargc++] = str;
		else {
		   exp_usr = hasuno(str);

		   if (exp_usr) {		/* explicit user area spec? */
			if (*str == '*' || *str == '?')
				{ first_usr = 0; last_usr = 15; }
			else
				first_usr = last_usr = atoi(str);
			while (*str++ != '/')
				;
		   }

		   setfcb(fcb,str);	/* set up fcb for searching */
		   if ((tmpfn[1] = str[1]) == ':')
		   {
			tmpfn[0] = str[0];
			tmpfnp = tmpfn + 2;
			bdos(14,tmpfn[0] - 'A');
		   }

		   for (j = first_usr; j <= last_usr; j++)
		   {
		     bdos(32, j);
		     first_time = TRUE;
		     while (nargc <= (MAXITEMS+1))  /* find matching files */
		     {
			dmapos = bdos(first_time ? SEARCH_FIRST : SEARCH_NEXT,
									fcb);
			if (dmapos == 255) break;
			first_time = FALSE;

			if (sysflag || peek((BASE + 0x8A) + dmapos * 32) < 128)
			{
			
			  hackname(tmpfnp,(BASE + 0x80 + dmapos * 32));
			  tmpfn2[0] = '\0';
			  if (exp_usr)
				sprintf(tmpfn2, "%d/", j);
			  strcat(tmpfn2,tmpfn);

			  if ((nargv[nargc] = sbrk(strlen(tmpfn2) + 1))==ERROR)
				  return ERROR;
			  strcpy(nargv[nargc++], tmpfn2);
			}
		     }
		   }
		   bdos(14,cur_drive);		/* restore to current drive */
		   bdos(32,cur_usr);		/* and use area */
		}

	}
	for (i = 0; i < notcount; i++)
		for (j = 1; j < nargc; j++)
			while (match(notfns[i],nargv[j],cur_drive))
			{
				if(j == --nargc)
					break;
				for (k = j; k < nargc; k++)
					nargv[k] = nargv[k+1];
			}
	*oargcp = nargc;
	*oargvp = nargv;
	return 0;
}

hackname(dest,source)
char *dest, *source;
{
	int i,j;

	j = 0;

/* Remove attributes first so compares will work */
	for (i = 1; i < 12; i++) source[i] &= 0x7F;

	for (i = 1; i < 9; i++)
	{
		if (source[i] == ' ') break;
		dest[j++] = source[i];
	}
	if (source[9] != ' ')
		dest[j++] = '.';

	for (i = 9; i < 12; i++)
	{
		if (source[i] == ' ') break;
		dest[j++] = source[i];
	}
	dest[j] = '\0';
	return dest;
}

int haswild(fname)
char *fname;
{
	char c;

	while (c = *fname++)
		if (c == '*' || c == '?') 
			return TRUE;
	return FALSE;
}

int match(wildnam, filnam, cur_drive)
char *wildnam, *filnam, cur_drive;
{
   char c;

   if (wildnam[1] != ':')
   {
	if (filnam[1] == ':')
		if (filnam[0] - 'A' == cur_drive)
			filnam += 2;
		else
			return FALSE;
   }
   else
   {
	if (filnam[1] != ':')
		if (wildnam[0] - 'A' == cur_drive)
			wildnam += 2;
		else
			return FALSE;
   }

   while (c = *wildnam++)
	if (c == '?')
		if ((c = *filnam++) && c != '.')
			continue;
		else
			return FALSE;
	else if (c == '*')
	{
		while (c = *wildnam)
		{ 	wildnam++;
			if (c == '.') break;
		}
		while (c = *filnam)
		{	filnam++;
			if (c == '.') break;
		}
	}
	else if (c == *filnam++)
	 	continue;
	else return FALSE;

   if (!*filnam)
	return TRUE;
   else
	return FALSE;
}


int hasuno(str)	   /* return true if filename string has user num. prefix */
char *str;
{
	if (str[1] == '/' && (*str == '*' || *str == '?'))
		return TRUE;

	if (isdigit(*str++))
		return (*str == '/' || isdigit(*str++) && *str == '/');
	else
		return FALSE;
}
