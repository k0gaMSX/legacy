/*--- MAIN.C -----------------------------------------------------------------
Main source file for MAKE.COM, The MSX Maniac, 3-Jan-1995 */

#include <stdio.h>
#include "main.h"
#include "sda.h"
#include "sdm.h"
#include "macro.h"
#include "tree.h"
#include "error.h"
#include "mac.h"


char   *_p_path();		/* Internal function (CLIBMAC.MAC) */
char   calla(); 		/* MSX-C function (BDOSFUNC.H) */
VOID   InitMain();
VOID   MakeInfo();
VOID   OSAttrib();
VOID   OSBackup();
char   *PPath();


/* #define DEBUGMAIN */


			     /* Object block variables */
static node *obvMaster = NULL;
BOOL	    obvUpdate = FALSE;	/* TRUE if update is necessary, i.e.
				   operations must be output */
BOOL	    obvBackup = FALSE;	/* TRUE if backup is necessary, i.e.
				   backup commands must be output */


/*------------------------------------------------------------ functions ---*/

VOID main(argc, argv)
int argc;
char **argv;
{
   argcPublic = argc;
   argvPublic = argv;
   if (argc == 1) {
      MakeInfo();
      exit(0);
   }
   MacInit();
   SDAmanager();
   InitMain();
   SDMmanager();
}


/*------------------------------------------------------------- Functions ---*/

/*--- Aap() ------------------------------------------------------------------
ù function: Aap
*/

VOID Aap() {
   puts("Aap(): ");
   puts(f_name);
   puts("\n");
}


/*--- GetFileInfo() ----------------------------------------------------------
ù function: Get file info (date, time, attributes)
ù input:    pointer to node structure
ù output:   filled Easy node variables
ù return:   TRUE if succesfull retrieval, FALSE if not */

VOID GetFileInfo(fnode)
node *fnode;
{
#ifdef DEBUGMAIN
   puts("GetFileInfo()\n");
#endif

   EasyNode(fnode);

#ifdef DEBUGMAIN
   printf("\tSearching file: %s\n", f_name);
#endif

   ldIX(&MFIB);
   if (calla(0x0005, 0, 0, 0x0040, f_name))	/* FileFind */
      return(FALSE);
   else {
      f_node->time = MFIB.fibtime;
      f_node->date = MFIB.fibdate;
      f_node->attr = MFIB.attr;
      f_node->Aupdate = (MFIB.attr & 0x20) ? YES : NO;
      return(TRUE);
   }
}


/*--- InitMain() -------------------------------------------------------------
ù function: Initialize main */

VOID InitMain() {
   getcwd(CurrDir, sizeof(CurrDir));	   /* Get current working directory */
   if (CurrDir[strlen(CurrDir)-1] != '\\')
      strcat(CurrDir, "\\");
}


/*--- MakeInfo() -------------------------------------------------------------
ù function: display make info */

VOID MakeInfo() {
   puts("MAKE version 2.00\nThe MSX Maniac (pd) May-1995\n\n\
Usage: MAKE [<makefile[.MF]>] [<options>] [<macro definitions>]\n\n\
Makefile syntax:\n\
\t#<comment> | <master>:{<space><slave>}[\\] | <space><operation>[\\]\n\n\
Options available:\n\
\t/x\t\toutput operations for modified files only\n\
\t/y\t\toutput operations for all files\n\
\t/b<dirspec>\toutput backup commands for modified files only\n\
\t/l<dirspec>\toutput backup commands for all files\n\
\t/a\t\tcheck on archive attribute (overrule /X time check)\n\
\t/m\t\tcheck on - and reset - archive attribute\n\
\t/t\t\tcheck on date & time (overrule /B archive check)\n\
");
}


/*--- OBAttrib() -------------------------------------------------------------
ù function: Do OS' attrib command if bit in tree structure is set
*/

VOID OBAttrib(f_node, tmpStr)
struct node  *f_node;
char	     *tmpStr;
{
   if (f_resetAttr) {

	 /* FileFind */

      ldIX(&MFIB);
      if (calla(0x0005, 0, 0, 0x0040, f_name)) {
	 ErrFile = f_name;
	 MError(5, 0);	/* Can't find file */
      }

	 /* Reset archive attribute */

      calla(0x0005, 1, (int) (MFIB.attr & 0xDF), 0x0050, &MFIB);
   }
}


/*--- OBBEnd() ---------------------------------------------------------------
ù function: End block definition
*/

VOID OBBEnd() {

      /* Reset object block variables */

   obvUpdate = FALSE;
   obvBackup = FALSE;

      /* Must OS' attrib command be output for master file? */

   if ((OptB || OptL) && OptMB) {
      OSAttrib();
   }
}


/*--- OBBStart() -------------------------------------------------------------
ù function: Start block definition
ù input:    pointer to filename
*/

VOID OBBStart(mfname)
char  *mfname;
{
   ProcFile(mfname);
   obvMaster = f_node;
}


/*--- OBDeinit() -------------------------------------------------------------
ù function: Deinitialize makefile
*/

VOID OBDeinit() {
   TreeRead(OBAttrib);
/*   TreeRead(Aap); */
}


/*--- OBInit() ---------------------------------------------------------------
ù function: Initialize makefile
*/

VOID OBInit() {
}


/*--- OBMaster() -------------------------------------------------------------
ù function: End previous block definition. Start new block definition and
	    process master filename
ù input:    pointer to filename
*/

VOID OBMaster(mfname)
char *mfname;
{
   if (obvMaster == NULL)
      OBInit();
   else
      OBBEnd();
   OBBStart(mfname);
}


/*--- OBOperation() ----------------------------------------------------------
ù function: Process operation, i.e. line to hand over to operating system
ù input:    Pointer to operation string (including '\n') */

VOID OBOperation(mfOperation)
char *mfOperation;
{

#ifdef DEBUGMAIN
   puts("OBOperation()\n");
#endif

   if ((obvUpdate) && (obvMaster != NULL)) {
      puts(mfOperation);
   }
}


/*--- OBSlave() --------------------------------------------------------------
ù function: Process slave filename. Set object variables according to
	    'Option Settings'.
ù input:    pointer to filename
*/

VOID OBSlave(mfname)
char *mfname;
{

#ifdef DEBUGMAIN
   puts("OBSlave()\n");
#endif

   ProcFile(mfname);

      /* Reset archive attribute? */

   if ((OptA && OptMX) || (!(OptT) && OptMB)) {
      /* if not done already */
      if (f_backDone == FALSE)
	 OSAttrib();
   }

      /* Output backup commands? */

   if (OptB || OptL) {

	 /* Check if backup commands must be output now (before operations)
	    or after operations */

      if (

	       /* No operations at all, so output now? */

	    ((OptX == FALSE) && (OptY == FALSE)) ||

	       /* Also operations, but first output backup, then output
		  operations? */

	    ((OptX || OptY) && OptXB == 'B')
	 ) {

	    /* Output backup commands for all files? */

	 if (OptL) {
	    OSBackup();

	       /* Reset archive attribute (afterwards)? */

	    if (OptMB)
	       f_node->resetAttr = TRUE;
	 }
	 else {

	       /* Backup check using time? */

	    if (OptT) {

		  /* If slave newer than master? */

	       if (
		     (f_node->date >= obvMaster->date) &&
		     (f_node->time > obvMaster->time)
		 )  {
		 OSBackup();
	       }
	    }
	    else {

		  /* Archive attribute set? */

	       if (f_node->attr & 0x20) {
		  OSBackup();

		     /* Reset archive attribute (afterwards)? */

		  if (OptMB)
		     f_node->resetAttr = TRUE;
	       }
	    }
	 }
      }
   }

      /* Output operations? */

   if (OptX) {

	 /* Output operations for all files? */

      if (OptY) {
	 obvUpdate = TRUE;

	    /* Reset archive attribute (afterwards)? */

	 if (OptA && OptMX) {
	    f_node->resetAttr = TRUE;
	 }
      }
      else {

	    /* 'Make' check using archive attribute? */

	 if (OptA) {

	       /* Archive attribute set? */

	    if (f_node->attr & 0x20) {
	       obvUpdate = TRUE;

		  /* Reset archive attribute (afterwards)? */

	       if (OptMX)
		  f_node->resetAttr = TRUE;
	    }
	 }
	 else {

	       /* If slave newer than master? */

	    if (
		  (f_node->date >= obvMaster->date) &&
		  (f_node->time > obvMaster->time)
	       )  {
	       obvUpdate = TRUE;
	    }
	 }
      }
   }
}


/*--- OSAttrib() -------------------------------------------------------------
ù function: Reset file archive attribute
*/

VOID OSAttrib() {

#ifdef DEBUGMAIN
   puts("OSAttrib\n");
#endif

}


/*--- OSBackup() -------------------------------------------------------------
ù function: Invoke OS' backup (copy) command
*/

VOID OSBackup() {
   puts("COPY ");
   puts(f_node->name);
   puts(" ");
   puts(dpf);
   puts("\n");
}


/*--- ProcFile() -------------------------------------------------------------
ù function: Fill file node
ù input:    pointer to filename
ù output:   filled easy variables (f_)
ù return:   none
*/

VOID ProcFile(mfname)
char *mfname;
{

   char *cpi;

   if ((cpi = PPath(mfname)) == NULL)
      MError(3, 9);			/* Invalid filename */

   f_node = TreeBuild(cpi);
   if (ALIFE) {
      if (GetFileInfo(f_node) == FALSE) {
	 ErrFile = f_name;
	 MError(5, 0);			/* File not found */
      }
   }
}


/*--- PPath() ----------------------------------------------------------------
ù function: parse partial defined drive/path/file ASCIIZ string to full
	    defined ASCIIZ string
ù input:    pointer to ASCIIZ string
ù return:   pointer to parsed string, NULL if no filename specified */

char *PPath(pstring)
char *pstring;
{
   static char PPtBuf[64+3+12];
   char *cpi;
   TINY flag;

#ifdef DEBUGMAIN
   printf("\t%s passed to PPath()\n", pstring);
#endif

   _p_path(pstring, &cpi, &flag);
   if ((flag & 0x02) && (flag & 0x04))	  /* Drive & path specified ? */
      return(pstring);
   else {
      if (flag & 0x02) {		  /* Path specified ? */
	 strncpy(PPtBuf, CurrDir, 2);  /* Get current drive */
	 PPtBuf[2] = '\0';
      }
      else
	 strcpy(PPtBuf, CurrDir);      /* Get current directory */
      strcat(PPtBuf, pstring);
   }
   if (flag & 0x08) {			 /* Filename specified ? */

#ifdef DEBUGMAIN
      printf("\tPPath returns: %s\n", PPtBuf);
#endif

      return(PPtBuf);
   }
   else {

#ifdef DEBUGMAIN
      puts("\tPPath returns NULL\n");
#endif

      return(NULL);
   }
}


/*--- ProcOperation() --------------------------------------------------------
ù function: Process operation, i.e. line to hand over to operating system
ù input:    Pointer to operation string (including '\n') */

VOID ProcOperation(mfOperation)
char *mfOperation;
{
   puts(mfOperation);
}


/*--- StrToUpper() -----------------------------------------------------------
ù function: Convert string to upper case
ù input:    Pointer to string
ù return:   Pointer to uppercased string */

char *StrToUpper(s)
char *s;
{
   char *d;

   d = s;
   while (*s) {
      *s = toupper(*s);
      s++;
   }
   return d;
}


/* NEST ALL further CODE !!!!!!!
/*
--- Backup() ---------------------------------------------------------------
ù function: output command to backup master file
ù input:    pointer to file-node
ù output:   'copy' command to standard output
ù return:   none
*/

VOID Backup(node)
struct node  *node;
{
   if (node->bdone == NO) {
      printf("copy %s %s\n", node->name, dpf);
      node->bdone = YES;
   }

}


/*
--- MakeProc() -------------------------------------------------------------
ù function: Process makestring
ù input:    pointer to makestring
ù output:   stdout
ù return:   none
*/

VOID MakeProc(makestr)
char  *makestr;
{
   if (mnode) {
      if (lcmc == 0 && (OptL || OptB && mnode->Aupdate
      || OptT && mnode->Tupdate) && OptXB == FALSE)
	 Backup(mnode);
      if (OptX && mnode->Tupdate && OptMX == FALSE || (OptA||OptMX)
      && mnode->Aupdate || OptY) {
	 while (isspace(*makestr) && *makestr)
	    makestr++;
	 puts(makestr);
	 lcmc++;
      }
   }
   else
      MError(4, 3);
}


/*
--- NameProc() -------------------------------------------------------------
ù function: Process name; fill new node with time-data and set 'update' flag
	    if slaves have been modified.
ù input:    master_flag; TRUE if master-name, FALSE if slave. Usage of external
	    variable 'mfname'.
ù output:   stdout
ù return:   none
*/

VOID NameProc(MASTER)
BOOL  MASTER;
{
   EasyNode(TreeBuild(mfname));
   if (ALIFE) {
      if (*(char *)0xF313) {	     /* DOS 2 cartridge?  yes.. use FIB */
	 ldIX(FIB);
	 if (calla(0x0005, 0, 0, 0x0040, mfname))
	    MError(5, 0);
	 _time = *(unsigned *) &FIB[15];
	 _date = *(unsigned *) &FIB[17];
					       /* check archive attribute */
	 _Aupdate = (FIB[14] & 0x20) ? YES : NO;
	 if (OptMX || OptMB)		       /* reset archive attribute */
	    calla(0x0005, 1, (int) (FIB[14] & 0xDF), 0x0050, FIB);
      }
      else {						 /* no.. use FCB */
	 if ((TFD = open(mfname, 0)) == ERROR)
	    MError(5, 0);
	 tFCB = _getfcb(TFD);
	 _date = tFCB->fcbdate;
	 _time = tFCB->fcbtime;
	 close(TFD);
      }
      _node->time = _time;
      _node->date = _date;
   }

   if (MASTER) {
      if (mnode && (OptL || OptB && mnode->Aupdate || OptT && mnode->Tupdate)
      && OptXB == FALSE)
	 Backup(mnode);
      mnode = _node;
   }
   else {
      if (mnode == NULL)
	 MError(4, 3);
      if (_Aupdate == YES)
	 mnode->Aupdate = YES;
      if (_Tupdate || _date > mnode->date || _date == mnode->date
      && _time > mnode->time)
	 _node->Tupdate = mnode->Tupdate = YES;
      if (OptL || OptB && _Aupdate || OptT && _Tupdate)
	 Backup(_node);
   }
}


/*
--- CommProc() -------------------------------------------------------------
ù function: Takes action on comments and empty lines
ù input:    none
ù output:   none
ù return:   none
*/

VOID CommProc() {
}

*/  /* END OF NESTING "ALL further CODE !!!" */

