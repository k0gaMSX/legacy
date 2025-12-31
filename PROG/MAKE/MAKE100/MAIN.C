/*--- MAIN.C ------------------------------------------------------------------

   MAKE verwerkt informatie van de 'standard input' en verricht de daarin
   gespecificeerde handelingen op basis van de gespecificeerde relaties en
   condities.
   Een makefile bevat de beschrijving van de afhankelijkheden tussen files 
   en de operaties benodigd om een resultaat te bereiken. Afhankelijkheden 
   worden beschreven door een regel te beginnen met de naam van de doelú 
   file, gevolgd door ':' en de namen van de files waarvan de doelfile 
   afhankelijk is. Als het totale aantal files groter is dan de regellengte 
   kan worden doorgegaan op de volgende regel, mits de vorige is afgesloten 
   met een '\'. De instructies hoe de doelfile te realiseren, dienen direct 
   op de afhankelijkheden te volgen, beginnend met een TAB-teken. Commenú 
   taar kan overal worden toegevoegd, mits dit begint met het '#'-teken.     */


#include <stdio.h>
#include <bdosfunc.h>
#include <main.h>
#include <error.h>
#include <tree.h>
#include <mf.h>
#include <mac.h>


/*------------------------------------------------------------- Variables ---*/

								 /* Switches */
char OptX = FALSE;	/* output make commands for modified files only */
char OptY = FALSE;	/* output make commands all files */
char OptB = FALSE;	/* backup modified files only */
char OptL = FALSE;	/* backup all files */
char OptXB = FALSE;	/* TRUE if X/Y-B/H, FALSE if reverse (B/H-X/Y) */
char OptA = FALSE;	/* check archive attribute */
char OptM = FALSE;	/* temporary /m variable */
char OptMX = FALSE;	/* as /a, reset archive attribute for /X option */
char OptMB = FALSE;	/* as /a, reset archive attribute for /B option */
char OptT = FALSE;	/* check date and time */

/* By default make commands are output for modified files only, the files
   being checked on time as well as on the archive attribute		     */



char makefile[13];	/* empty if input from stdin */
char dpf[64];		/* dir/path/file specification for backup */

struct node *mnode = NULL; /* Master node, NULL if no master defined */

int    lcmc;		/* line counter for make commands */

			/*--------------- DOS 1 ---*/
FD	TFD;		/* File Descriptor */
FCB	*tFCB;		/* File Control Block */

			/*--------------- DOS 2 ---*/
char	MFileH; 	/* Makefile File Handle */
char	FIB[64];	/* File Info Block */

extern FCB  *_getfcb();
/*------------------------------------------------------------- Functions ---*/
VOID MakeInfo() {
   puts("MAKE version 1.00\nThe MSX Maniac (pd) 09-Apr-1994\n\n\
Usage: MAKE [<makefile[.MF]>] [<options>]\n\n\
Makefile syntax:\n\
\t#<comment> | <master>:{<space><slave>}[\\] | <space><operation)[\\]\n\n\
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


/*
--- GetDpf() ---------------------------------------------------------------
ù function: get drive/path/file specification for backup
ù input:    pointer to switch character of option string
ù output:   filled DPF if specification OK, else DPF will contain '\0'
ù return:   updated pointer to option string
*/

char *GetDpf(OptStr)
char *OptStr;
{
   char ci = 0;

   dpf[0] = '\0';
   OptStr++;
   while(*OptStr && *OptStr != '/') {
      dpf[ci++] = *OptStr++;
      if (ci >= sizeof(dpf))
	 MError(1, 7);
   }
   if (ci == 0)
      MError(1, 6);
   dpf[ci] = '\0';
   return(OptStr);
}


/*
--- OptCtrl() --------------------------------------------------------------
ù function: check for option validity
ù input:    pointer to option string, the first character being a '/'
ù output:   setting of external option variables
ù return:   none
*/

VOID OptCtrl(OptStr)
char *OptStr;
{
   while (*++OptStr) {
      switch(toupper(*OptStr)) {
      case 'B':
	 OptB = (OptL) ? MError(1, 1) : TRUE;
	 OptStr = GetDpf(OptStr);     /* get drive/path/file specification */
	 break;
      case 'L':
	 OptL = (OptB) ? MError(1, 1) : TRUE;
	 OptStr = GetDpf(OptStr);     /* get drive/path/file specification */
	 break;
      case 'X':
	 OptX = (OptY) ? MError(1, 5) : TRUE;
	 OptXB = (OptL || OptB) ? FALSE : TRUE;
	 break;
      case 'Y':
	 OptY = (OptX) ? MError(1, 5) : TRUE;
	 OptXB = (OptL || OptB) ? FALSE : TRUE;
	 break;
      case 'A':
	 OptA = (*(char *)0xF313) ? TRUE : MError(1, 8);
	 break;
      case 'M':
	 OptM = (*(char *)0xF313) ? TRUE : MError(1, 8);
	 break;
      case 'T':
	 OptT = TRUE;
	 break;
      default:
	 MError(1, 0);
	 break;
      }
      if (*++OptStr != '/')
	 OptStr--;
   }
   if (OptA && OptX == FALSE)
      MError(1, 4);
   if (OptT && OptB == FALSE)
      MError(1, 9);
   if (OptM && OptB == FALSE && OptX == FALSE)
      MError(1, 10);
   if (OptM)
      if (OptX && OptB) {
	 OptMB = OptXB;
	 OptMX = OptXB ^ 1;
      }
      else if (OptX)
	 OptMX = TRUE;
      else if (OptB)
	 OptMB = TRUE;
   if (! (OptB || OptL || OptX || OptY))
      OptX = TRUE;
}


VOID main(argc, argv)
int  argc;
char *argv[];
{
   switch(argc) {
   case 1:
      MakeInfo();
      break;
   case 2:
      if (*argv[1] != '/') {
	 strcpy(makefile, argv[1]);
	 OptCtrl("\\\0");
      }
      else {
	 *makefile = '\0';
	 OptCtrl(argv[1]);
      }
      InitTree("MMMMMMMM.MMM");
      ProcMf();
      break;
   case 3:
      if (*argv[1] == '/')
	 MError(1, 3);
      strcpy(makefile, argv[1]);
      if (*argv[2] != '/')
	 MError(1, 0);
      OptCtrl(argv[2]);
      InitTree("MMMMMMMM.MMM");
      ProcMf();
      break;
   default:
      MError(1, 2);
      break;
   }
}


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

