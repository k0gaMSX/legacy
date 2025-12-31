/*--- MF.C ------------------------------------------------------------------*/

#include <stdio.h>
#include <tree.h>
#include <mf.h>
#include <error.h>
#include <main.h>


/*------------------------------------------------------------- Variables ---*/
char	mfbuf[128], *mfbufpointer, *ii;
FILE	*MF;			/* makefile */
char	*EOMF = 0xFFFF; 	/* NULL if End Of MakeFile */
BOOL	SPILL = FALSE;		/* SPILL = TRUE if the spill character has been
				   detected at the end of the line */
BOOL	PSPILL = FALSE; 	/* Previous SPILL = TRUE if the previous line
				   has been spilled */
BOOL	MAKE = TRUE;		/* MAKE = TRUE if makespill, else slavespill */

extern VOID  NameProc();
extern VOID  MakeProc();
extern VOID  CommProc();

extern struct node  *mnode;	/* MAIN.C: NULL when no master is defined, else
				   mnode points to master node */
extern char  makefile[13];	/* MAIN.C: NULL when input from stdin */

extern BOOL  _isfn();	       /* LIB2.C: return TRUE if character is a valid
				   filename character, FAlSE if not */
/*------------------------------------------------------------- Functions ---*/
VOID GetNames();

/*
--- RdLnMf() ---------------------------------------------------------------
ù function: Read line from makefile
ù input:    stdin
ù output:   makefile-line is put in 'mfbuf'
ù return:   pointer to mfbuf, or NULL if end of file error occurs
*/

char *RdLnMf() {

   mfln++;
   mfcl = 0;
   if (*makefile)
      return (fgets(mfbufpointer = mfbuf, sizeof(mfbuf), MF));
   else
      return (gets(mfbufpointer = mfbuf, sizeof(mfbuf)));
}


/*
--- RdChMfbuf() ------------------------------------------------------------
ù function: Read character from 'mfbuf', skip multiple spaces
ù input:    none
ù output:   none
ù return:   character
*/

char RdChMfbuf() {

   static char c;

   do {
      if (c = *mfbufpointer) {
	 if (++mfcl > sizeof(mfbuf))
	    MError(4, 4);
	 mfbufpointer++;
	 if (! ((isspace(c)) && (*mfbufpointer) && (isspace(*mfbufpointer))) )
	    return (c);
      }
      else
	 return (c);
   } while (TRUE);
}


/*
--- Extension() ------------------------------------------------------------
ù function: Check if filename extension is defined
ù input:    pointer to filename string
ù output:   none
ù return:   TRUE if the filename at least contains a '.'
*/

BOOL Extension(filename)
char *filename;
{
   while (*filename)
      if (*filename++ == '.')
	 return (TRUE);
   return (FALSE);
}


/*
--- ProcMf() ---------------------------------------------------------------
ù function: Process makefile; one line at a time.
ù input:    none
ù output:   modified tree
ù return:   none
*/

VOID ProcMf() {

   char mfchar;

   if (*makefile) {
      if (! Extension(makefile))	   /* Concatenate MFEXTENSION */
	 strcat(makefile, MFEXT);
      if ((MF = fopen(makefile, "r")) == NULL) {
	 strcpy (mfname, makefile);
	 MError(5, 0);
      }
   }

   do {
	 EOMF = RdLnMf();
					      /* detect spill character */
	 PSPILL = (SPILL) ? YES : NO;
	 for (ii = mfbuf; *ii; ii++)
	    if (*ii == '\n')
	       break;
	 if (*--ii == SPILLC) {
	    *ii = '\0';
	    SPILL = TRUE;
	 }
	 else
	    SPILL = FALSE;

	 mfchar = RdChMfbuf();
	 if (PSPILL)
	    if (MAKE)
	       GetNames(mfchar);
	    else
	       MakeProc(mfbufpointer);
	 else
	    if (! (mfchar) || mfchar == COMMC || mfchar == '\n')
	       PSPILL = SPILL = MAKE = FALSE;
	    else
	       if (isspace(mfchar)) {
		  MakeProc(mfbufpointer);
		  MAKE = FALSE;
	       }
	       else {
		  if (mnode && OptXB && (OptL || OptB && mnode->Aupdate
		  || OptT && mnode->Tupdate))
		     Backup(mnode);
		  if (mnode && OptMX && mnode->Aupdate)
		     printf("attrib2 -a %s\n", mnode->name);
		  lcmc = 0;
		  GetNames(mfchar);
		  MAKE = TRUE;
	       }
   } while (EOMF);
   if (mnode && OptXB && (OptL || OptB && mnode->Aupdate
   || OptT && mnode->Tupdate))
      Backup(mnode);
   if (mnode && OptMX && mnode->Aupdate)
      printf("attrib2 -a %s\n", mnode->name);
}


/*
--- pName() ----------------------------------------------------------------
ù function: parse name string from makefile onto end of destination string
ù input:    first character, *destination, number of characters to process
ù output:   parsed name string in d
ù return:   non-filename character
*/

char pName(c, d, n)
char  c, *d;
TINY  n;
{
   while(*d)		  /* goto end of string */
      d++;
   for (; _isfn(c); c = RdChMfbuf()) {
      if (n--)
	 *d++ = toupper(c);
      else
	 MError(4, 2);
   }
   *d = '\0';             /* null-terminate string */
   return(c);
}


/*
--- GetNames() -------------------------------------------------------------
ù function: process names from mfbuf
ù input:    character being read by the makefile-processor
ù output:   modified tree, 'mfname' filled
ù return:   none
*/

char GetNames(mfchar)
char  mfchar;
{
   do {
      while (! _isfn(mfchar))		 /* skip non-filename character(s) */
	 if ((mfchar = RdChMfbuf()) == '\0')
	    return;

      mfname[0] = '\0';
      mfchar = pName(mfchar, mfname, (TINY) 8);
      if (mfchar == '.')
	 mfchar = pName(RdChMfbuf(), strcat(mfname, "."), (TINY) 3);
      switch(mfchar) {
      case ':' :
	 NameProc((BOOL) TRUE);
	 break;
      case ' ' :
      case '\t' :
      case '\0' :
      case '\n' :
	 NameProc((BOOL) FALSE);
	 break;
      default:
	 MError(4, 1);
      }
   } while (mfchar);
}

