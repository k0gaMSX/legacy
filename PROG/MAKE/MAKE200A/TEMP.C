#include <stdio.h>

char TempBuf[70];
char dpf[70];
char *_p_path();	       /* Internal function (CLIBMAC.MAC) */



/*--- PPath() ----------------------------------------------------------------
ù function: parse partial defined drive/path/file ASCIIZ string to full
	    defined ASCIIZ string
ù input:    pointer to ASCIIZ string
ù return:   pointer to parsed string */

char *PPath(pstring)
char *pstring;
{
   static char CurrDir[64+3];
   char *cpi;
   TINY flag;

   getcwd(CurrDir, sizeof(CurrDir));	   /* Get current working directory */
   if (CurrDir[strlen(CurrDir)-1] != '\\')
      strcat(CurrDir, "\\");

   _p_path(pstring, &cpi, &flag);
   if ((flag & 0x02) && (flag & 0x04))	   /* Drive & path specified ? */
      strcpy(TempBuf, pstring);
   else {
      if (flag & 0x02) {		  /* Path specified ? */
	 strncpy(TempBuf, CurrDir, 2);	/* Get current drive */
	 TempBuf[2] = '\0';
      }
      else
	 strcpy(TempBuf, CurrDir);	/* Get current directory */
      strcat(TempBuf, pstring);
   }
   if (flag & 0x08)			/* Filename specified ? */
      return(TempBuf);
   else {
      fputs("No filename specified\n", stderr);
      exit(1);
   }
}


VOID main() {
   puts("Enter a drive/path/file string:");
   scanf("%s", dpf);
   printf("Parsing \"%s\" results in: %s\n", dpf, PPath(dpf));
}
