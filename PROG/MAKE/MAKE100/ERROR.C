/*--- ERROR.C ---------------------------------------------------------------*/

#include <stdio.h>
#include <error.h>


/*------------------------------------------------------------- Variables ---*/
int	mfln = 0;	/* current line# of makefile */
char	mfcl;		/* current column# of makefile */
char	mfname[13];


/*
--- MError() ---------------------------------------------------------------
ù function: output error string to the standard output
ù input:    error-number and error-specie
ù ouput:    error string to the standard output
*/

char *ErrSw[] = {					/* 1: Switch errors */
   "invalid option",
   "option /B and /H both specified",
   "too many parameters",
   "filename expected as first parameter",
   "option /A without option /X specified",
   "option /X and /Y both specified",
   "backup drive/path not specified",
   "backup drive/path specification too long",
   "archive bit is not supported by MSX-DOS 1",
   "option /T without option /B specified",
   "option /M without option /B or /X specified"
};
char *ErrMe[] = {					/* 2: Memory errors */
   "not enough memory"
};
char *ErrTr[] = {					/* 3: Tree errors */
   "node already exists"
};
char *ErrMf[] = {					/* 4: Makefile errors */
   "spill character used in middle of line",
   "invalid filename character",
   "filename too long",
   "no master defined",
   "line too long",
   "inconsistent relation; master already used as slave"
};
char *ErrDs[] = {					/* 5: DOS file errors */
   "file not found",
   "error closing file"
};

VOID MError(species, number)
int species, number;
{
   char *ErrStr;

   switch(species) {
   case 1:	/* Switch errors */
      ErrStr = ErrSw[number];
      break;
   case 2:	/* Memory errors */
      ErrStr = ErrMe[number];
      break;
   case 3:	/* Tree errors */
      ErrStr = ErrTr[number];
      break;
   case 4:	/* Makefile errors */
      ErrStr = ErrMf[number];
      printf("line %d column %d: ", mfln, (int) mfcl);
      break;
   case 5:	/* DOS file errors */
      ErrStr = ErrDs[number];
      printf("%s: ", mfname);
      break;
   }
   fputs(ErrStr, stderr);
   fputs("\n", stderr);
   exit();
}
