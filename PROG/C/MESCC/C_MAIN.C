/*	c_main.c

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	Main module.

	Copyright (c) 1999-2007 Miguel I. Garcia Lopez

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation; either version 2, or (at your option) any
	later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

	Revisions:

	16 Jan 2001 : Minor changes.
	20 Dec 2003 : Minor changes.
	20 Apr 2004 : Last revision.
	16 Apr 2007 : GPL'd.
*/

#ifndef C_MAIN_H
#include "c_main.h"
#endif

#ifndef C_CPP_H
#include "c_cpp.h"
#endif

extern int cppmacx;

#define HLP1	"Usage: cc name[.typ] [options]\n"
#define HLP2	"-PRG          Out normal file ---- Type=ZSM"
#define HLP3	"-LIB          Out library file --- Type=LIB"
#define HLP4	"-ASM          Out assembler file - Type=ZSM"
#define HLP5	"-O:name[.typ] File name for output"
#define HLP6	"-Cflag        C source as comments?"
#define HLP7	"-Eflag        Pause on errors?"
#define HLP8	"-Aflag        Define code for argc & argv[]?"
#define HLP9	"-E:number     Max. number of errors to abort"
#define HLP10	"-L:letnum     Letter and start number for labels"
#define HLP11	"-S:size       Mininum stack size\n"
#define HLP12	"Default options are: (flag is + for YES, - for NO)\n"
#define HLP13   "\t-PRG -C- -A+ -E+ -E:50 -L:A0 -S:512"
#define HLP14   "\tInput file type is .c"
#define HLP15	"\tOutput file name is the same as input"

/*	ERRORS IN COMMAND LINE
*/

#define ERCMDLN	"Illegal option"
#define ERCMDER	"Illegal max. errors number"
#define ERCMDLB	"Illegal label"
#define ERCMDST	"Illegal stack size"

/*	MESSAGES
*/

#define SMRYLAB	"Next label: "
#define SMRYERR	"Errors:     "

#define SMLIN1	"Table    Used  Free"
#define SMLIN2	"-------- ----- -----"
#define SMLITS	"Strings  "
#define SMGLBS	"Globals  "
#define SMMACS	"Macros   "
	
#define DUMPLIT	"Writing strings..."
#define DUMPGLO	"Writing globals..."
#define COMPFUN	"Function: "

/*	SYMBOL TABLE
*/

#define GLB_NUM		450
#define GLB_TABSIZ	7650		/* GLB_NUM * SYMSIZE */
#define GLB_START	glbsymtab
#define GLB_END		GLB_START+GLB_TABSIZ

#define LOC_NUM		40
#define LOC_TABSIZ	680		/* LOC_NUM * SYMSIZE */
#define LOC_START	locsymtab
#define LOC_END		LOC_START+LOC_TABSIZ

/*	STATEMENT TYPES
*/

#define S_IF		1
#define S_WHILE		2
#define S_FOR		3
#define S_SWITCH	4
#define S_RETURN	5
#define S_BREAK		6
#define S_CONT		7
#define S_EXP		8

/*	SWITCH
*/

#define SWITCH_MAX 254

/*	WHILE QUEUE PARAMETERS
*/

#define WQ_TABSIZ	120
#define WQ_SIZ		7
#define WQ_MAX		wq+WQ_TABSIZ-WQ_SIZ
#define WQ_SYM		0
#define WQ_SP		1
#define WQ_LOOP		2
#define WQ_LAB		3
#define WQ_LAB2		4
#define WQ_END		5
#define WQ_BODY		6

/*	GLOBAL VARIABLES
*/

char	glbsymtab[GLB_TABSIZ],	/* Symbol tables */
	locsymtab[LOC_TABSIZ],
	*glbptr,		/* Pointers to next entry */
	*locptr;

int	wq[WQ_TABSIZ],		/* While queue and pointer */
	*wqptr;

char	litq[STRBUF_SIZ];	/* String pool and pointer */
int	litptr;

char	line[LN_SIZ];		/* Parsing buffer and pointer */
int	lptr;

int	letlab,		/* Label letter */
	errstop,	/* Pause on error ? */
	eof,		/* Non zero after final input */
	ctext,		/* Non-zero if C source to be included as comment */
	typout,		/* Output type: 0=program, 1=library, 2=assembler */
	lastst,		/* Type of last executed statement */
	argflag,	/* Define argc & argv[] ? */
	nxtlab,		/* Next label num. */
	litlab,		/* String pool label */
	sptr,		/* Relative SP */
	argstk,		/* Function arg. SP */
	argtop,		/* Function arg. top SP */
	errcnt,		/* Error count */
	errmax,		/* Max. num. of errors */
	stksize;	/* Stack size for program */

char	ipfname[15],	/* Input file name */
	opfname[15];	/* Output file name */

/*	MAIN FUNCTION
*/

main(argc,argv)
int argc,argv[];
{
	/* Init. vars. */

	glbptr=GLB_START;
	locptr=LOC_START;
	wqptr=wq;

	litptr=sptr=errcnt=eof=lastst=0;

	/* Show title */

	title();

	/* No parameters ? */

	if(argc==1)
	{
		help();
		return;
	}

	/* Get options from command line */

	getargs(argc-1,&argv[1]);
			
	/* Init. more vars. */

	litlab=getlabl();

	/* Init. file and preprocessor system */

	init_files();
	cpp_start();

	/* Open files */

	fi_open(ipfname);
	fo_open(opfname);

	/* Header for output file */

	a_start();

	/* Process all input */

	parse();

	/* Write strings and global variables */

	co_nl();

	dmplits();

	dmpglbs();

	/* Summary on screen */

	co_nl();
	co_line(SMLIN1);
	co_line(SMLIN2);
	co_str(SMLITS);co_dec05(litptr);co_ch(' ');co_dec05(STRBUF_SIZ-litptr);co_nl();
	co_str(SMGLBS);co_dec05(glbptr-GLB_START);co_ch(' ');co_dec05(GLB_END-glbptr);co_nl();
	co_str(SMMACS);co_dec05(cppmacx);co_ch(' ');co_dec05(CPPMACSIZ-cppmacx);co_nl();
	co_nl();
	co_str(SMRYERR);co_dec(errcnt);co_nl();
	co_str(SMRYLAB);co_ch(letlab);co_dec(nxtlab);co_nl();

	/* Summary on file */

	fo_nl();
	comment();fo_str(SMRYERR);fo_dec(errcnt);fo_nl();
	comment();fo_str(SMRYLAB);fo_ch(letlab);fo_dec(nxtlab);fo_nl();

	/* Footer for output file */

	a_end();

	/* Close files and bye, bye! */

	fo_close();
	fi_close();

	cpp_end();
}

/*	SET OPTIONS FROM COMMAND LINE / DEFAULT
*/

getargs(argcnt,argstr)
int argcnt,argstr[];
{
	int i;
	char *ptr;

	/* Default options */

	ctext=0;	
	errstop=argflag=1;
	errmax=50;
	letlab='a';
	nxtlab=0;
	typout=OUT_PRG;
	*opfname=0;
	stksize=512;

	/* Input file name */

	strcpy(ipfname,argstr[0]);	

	/* Get options from command line */

	for(i=1;i < argcnt;++i)
	{
		ptr=strupr(argstr[i]);
	
		if(*ptr++!='-')
			errcmdl(ERCMDLN);

		/* Output file name */

		if((!memcmp("O:",ptr,2)) && *(ptr+2))
			strcpy(opfname,ptr+2);

		/* Output file type */

		else if(!strcmp("PRG",ptr))
			typout=OUT_PRG;
		else if(!strcmp("LIB",ptr))
			typout=OUT_LIB;
		else if(!strcmp("ASM",ptr))
			typout=OUT_ASM;

		/* Write C source as comment ? */

		else if(!strcmp("C+",ptr))
			ctext=1;
		else if(!strcmp("C-",ptr))
			ctext=0;

		/* Define code for argc & argv[] ? */

		else if(!strcmp("A+",ptr))
			argflag=1;
		else if(!strcmp("A-",ptr))
			argflag=0;

		/* Pause on errors ? */

		else if(!strcmp("E+",ptr))
			errstop=1;
		else if(!strcmp("E-",ptr))
			errstop=0;

		/* Max. num. of errors to abort */

		else if((!memcmp("E:",ptr,2)) && *(ptr+2))
		{
			if((errmax=atoi(ptr+2))<0)
				errcmdl(ERCMDER);
		}
		
		/* Letter and start number for labels */

		else if((!memcmp("L:",ptr,2)) && *(ptr+2) && *(ptr+3))
		{
			if(!isalpha((letlab=*ptr+2)) || (nxtlab=atoi(*ptr+3))<0)
				errcmdl(ERCMDLB);
		}

		/* Stack size */

		else if((!memcmp("S:",ptr,2)) && *(ptr+2))
		{
			if((stksize=atoi(ptr+2))<512)			
				errcmdl(ERCMDST);
		}

		/* Unknown option */

		else
			errcmdl(ERCMDLN);
	}

	/* Put type to input file name if need */

	if(!strchr(ipfname,'.'))
		strcat(ipfname,".c");

	/* Put name without type if not exist */

	if(!(*opfname))
	{
		strcpy(opfname,ipfname);
		ptr=strchr(opfname,'.');
		*ptr=0;
	}

	/* Put type to output file name if need */

	if(!strchr(opfname,'.'))
		strcat(opfname, typout==OUT_LIB ? ".lib" : ".zsm");
}

/*	TITLE
*/

title()
{
	co_line(VERSION);
	co_nl();
}

/*	HELP
*/

help()
{
	co_line(HLP1);
	co_line(HLP2);
	co_line(HLP3);
	co_line(HLP4);
	co_line(HLP5);
	co_line(HLP6);
	co_line(HLP7);
	co_line(HLP8);
	co_line(HLP9);
	co_line(HLP10);
	co_line(HLP11);
	co_line(HLP12);
	co_line(HLP13);
	co_line(HLP14);
	co_line(HLP15);
}

/*	PROCESS ALL INPUT
*/

#define VAR_GLB 0
#define VAR_LOC 1
#define VAR_ARG 2

parse()
{
	while(!eof)
	{
		/***
		while(declvar(VAR_GLB));
		newfunc();
		InBlanks();
		***/

		if(!declvar(VAR_GLB) && !eof)
			newfunc(NULL, TY_INT);
	}
}

/*	DUMP STRINGS
*/

dmplits()
{
	int j,k;

	if(!litptr)
		return;

	co_line(DUMPLIT);

	a_lnlabel(litlab);

	k=0;

	while (k<litptr)
	{
		defbyte();

		j=10;		/* number of bytes/line */

		while(j--)
		{
			fo_dec(litq[k++]);

			if(j==0 || k>=litptr)
			{
				fo_nl();
				break;
			}

			fo_ch(',');
		}
	}
}

/*	DUMP GLOBAL VARIABLES
*/

dmpglbs()
{
	char *ptr;
	int size;

	co_line(DUMPGLO);

	for(ptr=GLB_START; ptr!=glbptr; ptr+=SYMSIZE)
	{
		if(ptr[SY_IDENT]!=ID_FUN && ptr[SY_STORAGE]!=ST_EXTERN)
		{
			fo_str(ptr); fo_colon(); defstrg();
			size=((ptr[SY_OFFSET] & 255) + (ptr[SY_OFFSET+1] << 8));
			if((ptr[SY_TYPE] & TY_INT) || ptr[SY_IDENT]==ID_PTR)
				size+=size;
			fo_dec(size);
			fo_nl();
		}
	}
}

/* todo: extern func(){...} ---> OK!? */


declvar(level)
int level;
{
	int stor, sign, type;
	int id, dim;
	char s[NAME_SIZ];

	stor=sign=type=0;

	if(level==VAR_GLB)
	{
		if(InSymEq("extern"))
			stor=ST_EXTERN;
	}

	if(InSymEq("unsigned"))
		sign=1;
	else if(InSymEq("signed"))
		sign=2;

	if(InSymEq("char"))
		type=TY_CHAR;
	else if(InSymEq("int"))
		type=TY_INT;

	if(!(stor+sign+type))
		return 0;

	if(!type)
		type=TY_INT;

	if(!stor)
		stor=(level==VAR_GLB) ? ST_STATIK : ST_STKLOC;

	if(sign==1)
		type=(type==TY_CHAR) ? TY_UCHAR : TY_UINT;

	while(1)
	{
		id=InChEq('*') ? ID_PTR : ID_VAR;

		if(!symname(s))
			illname();

		dim=0;

		if(InChEq('['))
		{
			if(number(&dim))
			{
				if(dim<0)
				{
					errcont(ERARRSZ);
					dim=-dim;
				}
			}

			ndch(']');

			if(id==ID_PTR)
				errcont(ERARRPT);

			if(level!=VAR_ARG)
			{
				if(dim || stor==ST_EXTERN)
					id=ID_ARR;
				else
					errcont(ERARRSZ);
			}
			else	/* VAR_ARG */
				id=ID_PTR;
		}
		else if(level==VAR_GLB)
		{
			if(InChEq('('))
			{
				newfunc(s, type);
				return 1;
			}
		}

		if(!dim)
			dim=1;

		if(level==VAR_GLB)
			declvglb(s, id, type, stor, dim);
		else if(level==VAR_LOC)
			declvloc(s, id, type, stor, dim);
		else
			declvarg(s, id, type, stor, dim);

		if(!InChEq(','))
			break;
	}

	ndch(';');

	return 1;
}

declvglb(sym, id, typ, sto, dim)
char *sym;
int id, typ, sto, dim;
{
	char *ptr;

	if(ptr=findglb(sym))
	{
		if(id!=ptr[SY_IDENT] || typ!=ptr[SY_TYPE] || (sto!=ST_EXTERN && ptr[SY_STORAGE]!=ST_EXTERN))
			mltidef();

		if(sto!=ST_EXTERN)
			ptr[SY_STORAGE]=sto;
	}
	else
		addglb(sym,id,typ,sto,dim);
}

int locsiz;

declvloc(sym, id, typ, sto, dim)
char *sym;
int id, typ, sto, dim;
{
	if(findloc(sym))
		mltidef();
	else
	{
		if(id==ID_PTR || (typ & TY_INT))
			dim+=dim;

		locsiz+=dim;

		addloc(sym,id,typ,sptr-locsiz);
	}
}

declvarg(sym, id, typ, sto, dim)
char *sym;
int id, typ, sto, dim;
{
	char *ptr;
	int locadr;

	if(argstk)
	{
		if(ptr=findloc(sym))
		{
			if(ptr[SY_IDENT])
				mltidef();
			else
			{
				ptr[SY_IDENT]=id;
				ptr[SY_TYPE]=typ;
			      	locadr=argtop-(ptr[SY_OFFSET+1]<<8)-ptr[SY_OFFSET];
				ptr[SY_OFFSET]=locadr;
				ptr[SY_OFFSET+1]=locadr>>8;

				argstk-=2;
			}
		}
		else
			errcont(ERARGNM);
	}
	else
		errcont(ERARGNB);
}

/*	NEW FUNCTION

	name==NULL -----> fun(){...}
	name!=NULL -----> ){...}

	typ is currently ignored, funcion is alwais TY_INT
*/

newfunc(name, typ)
char *name;
int typ;
{
	char n[NAME_SIZ],*ptr, argtyp;

	if(name)
	{
		strcpy(n, name);
	}
	else if(!symname(n))
	{
		errcont(ERFUNDE);
		BfKill();
		return;
	}
	else
		ndch('('); 

	msgindent();co_str(COMPFUN);co_line(n);

	if(ptr=findglb(n))
	{
		if(ptr[SY_IDENT]!=ID_FUN || ptr[SY_OFFSET]==ID_FUN)
			mltidef();
		else
			ptr[SY_OFFSET]=ID_FUN;

/************
		if(ptr[SY_IDENT]!=ID_FUN)
		{
			mltidef();
		}
		else
		{
			if(ptr[SY_OFFSET]==ID_FUN)
				mltidef();
			else
				ptr[SY_OFFSET]=ID_FUN;
		}
***************/

	}
	else
		addglb(n,ID_FUN,TY_INT,ST_STATIK,ID_FUN);

	/*** ndch('('); ******/

	fo_str(n);fo_colon();fo_nl();

	locptr=LOC_START;
	argstk=0;

	while(!InChEq(')'))
	{
		if(symname(n))
		{
			if(findloc(n))
				mltidef();
			else
			{
				addloc(n,0,0,argstk);
				argstk+=2;
			}
		}
		else
		{
			errcont(ERARGNM);
			junk();
		}

		InBlanks();

		if(BfNeq(')'))
			ndch(',');

		if(endst())
			break;
	}

	if(argstk)
	{
		argtop=argstk;

		while(declvar(VAR_ARG));

		if(argstk)
			errcont(ERARGNB);
	}

	sptr=0;

	if(stment()!=S_RETURN)
	{
		modstk(0,0);
		retfn();
	}

	sptr=0;
	locptr=LOC_START;
}

/*	STATEMENT
*/

stment()
{
	if(eof)
		return -1;

	if(InSymEq("if"))
	{
		doif(); lastst=S_IF;
	}
	else if(InSymEq("for"))
	{
		dofor(); lastst=S_FOR;
	}
	else if(InSymEq("while"))
	{
		dowhile(); lastst=S_WHILE;
	}
	else if(InSymEq("break"))
	{
		dobreak(); ns(); lastst=S_BREAK;
	}
	else if(InSymEq("do"))
	{
		dodo(); lastst=S_WHILE;
	}
	else if(InSymEq("return"))
	{
		doretrn(); ns(); lastst=S_RETURN;
	}
	else if(InSymEq("continue"))
	{
		docont(); ns(); lastst=S_CONT;
	}
	else if(InSymEq("switch"))
	{
		doswtch(); lastst=S_SWITCH;
	}
	else if(InChEq('{'))
	{
		while(!InChEq('}'))
		{
			if(stment()==-1)
			{
				errndch('}');
				break;
			}
		}
	}
	else if(InChEq(';'));
	else
	{
		locsiz=0;

		while(declvar(VAR_LOC));

		if(locsiz)
			sptr=modstk(sptr-locsiz,0);
		else
		{
			expresn(); ns(); lastst=S_EXP;
		}
	}

	return lastst;
}

/*	END OF STATEMENT
*/

ns()
{
	ndch(';');
}

/*	IF
*/

doif()
{
	int flev,fsp,flab1,flab2;

	flev=locptr;
	fsp=sptr;
	flab1=getlabl();
	test(flab1);
	stment();
	sptr=modstk(fsp,0);
	locptr=flev;

	if(!InSymEq("else"))
	{
		a_lnlabel(flab1);
		return;
	}

	if(lastst!=S_RETURN && lastst!=S_BREAK && lastst!=S_CONT)
		jump(flab2=getlabl());
	else
		flab2=0;

	a_lnlabel(flab1);

	stment();

	sptr=modstk(fsp,0);
	locptr=flev;

	if(flab2)
		a_lnlabel(flab2);
}

/*	DO
*/

dodo()
{
	int wq[WQ_SIZ];

	wq[WQ_SYM]=locptr;
	wq[WQ_SP]=sptr;
	wq[WQ_LOOP]=getlabl();
	wq[WQ_LAB]=getlabl();
	wq[WQ_LAB2]=getlabl();

	addwhle(wq);

	a_lnlabel(wq[WQ_LAB2]);

	stment();

	if(!InSymEq("while"))
		errcont(EREXWHI);

	a_lnlabel(wq[WQ_LOOP]);

	test(wq[WQ_LAB]);
	jump(wq[WQ_LAB2]);

	a_lnlabel(wq[WQ_LAB]);
	ns();
	locptr=wq[WQ_SYM];
	sptr=modstk(wq[WQ_SP],0);

	delwhle();
}

/*	WHILE
*/

dowhile()
{
	int wq[4];

	wq[WQ_SYM]=locptr;
	wq[WQ_SP]=sptr;
	wq[WQ_LOOP]=getlabl();
	wq[WQ_LAB]=getlabl();

	addwhle(wq);

	a_lnlabel(wq[WQ_LOOP]);

	test(wq[WQ_LAB]);
	stment();
	jump(wq[WQ_LOOP]);

	a_lnlabel(wq[WQ_LAB]);

	locptr=wq[WQ_SYM];
	sptr=modstk(wq[WQ_SP],0);

	delwhle();
}

/*	RETURN
*/

doretrn()
{
	if(endst())
		modstk(0,0);
	else
	{
		expresn();
		modstk(0,1);
	}

	retfn();
}

/*	BREAK
*/

dobreak()
{
	int *ptr;

	if((ptr=rdwhile()))
	{
		modstk(ptr[WQ_SP],0);
		jump(ptr[WQ_LAB]);
	}
}

/*	CONTINUE
*/

docont()
{
	int *ptr;

	if((ptr=rdwhile()))
	{
		modstk(ptr[WQ_SP],0);
		jump(ptr[WQ_LOOP]);
	}
}

/*	CALL FUNCTION
*/

callfnc(ptr)
char *ptr;
{
	int nargs;

	nargs=0;

	InBlanks();

	if(!ptr)
		fpush();

	while(BfNeq(')'))
	{
		if(endst())
			break;
		expresn();
		if(!ptr)
			swapstk();
		fpush();
		nargs=nargs+2;
		if(!InChEq(','))
			break;
	}

	ndch(')');

 	/* GIVE SPECIAL TREATMENT TO PRINTF, SCANF, ... */

	if(ptr)
	{
		if(special(ptr))
		{
		 	immed_dec(nargs/2);
		 	nargs+=2;
			fpush();
		}

		callfn(ptr);
	}
	else
		callstk();

	sptr=modstk(sptr+nargs,1);
}

/*	CHECK FOR SPECIAL FUNCTION NAMES WICH ARE TO BE GIVEN A
	FINAL EXTRA ARGUMENT EQUAL TO THE NUMBER OF ARGS.
*/

special(ptr)
char *ptr;
{
	if(!strcmp(ptr,"printf"))
		return 1;
	if(!strcmp(ptr,"scanf"))
		return 1;
	if(!strcmp(ptr,"sprintf"))
		return 1;
	if(!strcmp(ptr,"sscanf"))
		return 1;
	if(!strcmp(ptr,"fprintf"))
		return 1;
	if(!strcmp(ptr,"fscanf"))
		return 1;

	return 0;
}

/*	JUNK
*/

junk()
{
	if(issym(inbyte()))
	{
		while(issym(Bf()))
			BfGet();
	}
	else
	{
		while((!issym(Bf())) && Bf())
			BfGet();
	}
	InBlanks();
}

/*	ENDST
*/

endst()
{
	InBlanks();
	return(BfEq(';') || BfEq(0));
}

/*	ILLEGAL SYMBOL NAME
*/

illname()
{
	errcont(ERSYMNM);
	junk();
}

/*	SYMBOL ALREADY DEFINED
*/

mltidef()
{
	errcont(ERALDEF);
}

/*	FIND GLOBAL SYMBOL
*/

findglb(s)
char *s;
{
	char *ptr;

	for(ptr=GLB_START; ptr!=glbptr; ptr+=SYMSIZE)
	{
		if(!strcmp(s, ptr))
			return ptr;
	}

	return 0;
}

/*	FIND LOCAL SYMBOL
*/

findloc(s)
char *s;
{
	char *ptr;

	for(ptr=LOC_START; ptr!=locptr; ptr+=SYMSIZE)
	{
		if(!strcmp(s, ptr))
			return ptr;
	}

	return 0;
}

/*	ADD GLOBAL SYMBOL
*/

addglb(s,id,typ,sto,val)
char *s,id,typ,sto;
int val;
{
	char *ptr;

	if(ptr=findglb(s))
		return ptr;

	if(glbptr==GLB_END)
		errexit(EROFGLB);

	ptr=glbptr;
	strcpy(ptr,s);
	ptr[SY_IDENT]=id;
	ptr[SY_TYPE]=typ;
	ptr[SY_STORAGE]=sto;
	ptr[SY_OFFSET]=val;
	ptr[SY_OFFSET+1]=val>>8;
	glbptr+=SYMSIZE;

	return ptr;
}

/*	ADD LOCAL SYMBOL
*/

addloc(s,id,typ,val)
char *s,id,typ;
int val;
{
	char *ptr;

	if(ptr=findloc(s))
		return ptr;

	if(locptr==LOC_END)
		errexit(EROFLOC);

	ptr=locptr;
	strcpy(ptr,s);
	ptr[SY_IDENT]=id;
	ptr[SY_TYPE]=typ;
	ptr[SY_STORAGE]=ST_STKLOC;
	ptr[SY_OFFSET]=val;
	ptr[SY_OFFSET+1]=val>>8;
	locptr+=SYMSIZE;

	return ptr;
}

/*	CHECK VALID SYMBOL NAME
*/

symname(s)
char *s;
{
	int i;

	InBlanks();

	if(issym1st(Bf()))
	{
		i=0;
		do
		{
			if(i!=NAME_MAX)
			{
				*s++=BfGet();
				++i;
			}
			else
				BfGet();
		}
		while(issym(Bf()));

		*s=0;

		return 1;
	}

	return 0;
}

/*	GET NEXT LABEL NUMBER
*/

getlabl()
{
	return nxtlab++;
}

/*	ADDWHLE
*/

addwhle(ptr)
int ptr[];
{
	int k;

	if(wqptr!=WQ_MAX)
	{
		k=0;
		while(k!=WQ_SIZ)
			*wqptr++ = ptr[k++];
	}
	else
		errcont(ERTMWHI); 
}

/*	DELWHLE
*/

delwhle()
{
	if(rdwhile())
		wqptr-=WQ_SIZ;
}

/*	RDWHILE
*/

rdwhile()
{
	if(wqptr!=wq)
		return wqptr-WQ_SIZ;

	errcont(ERNOWHI);

	return 0;
}

/*	NDCH
*/

ndch(c)
char *c;
{
	if(InChEq(c))
		return 0;

	errndch(c);
/* junk(); */
	return 1;
}

/*	FOR
*/

dofor()
{
	int queue[WQ_SIZ];		/* local queue area */

	queue[WQ_SYM]=locptr;		/* save local level */
	queue[WQ_SP]=sptr;		/* and stack ptr */
	queue[WQ_LOOP]=getlabl();	/* looping label */
	queue[WQ_LAB]=getlabl();	/* loop exit varble */
	queue[WQ_END]=getlabl();	/* loop end label */
	queue[WQ_BODY]=getlabl();	
	addwhle(queue);			/* add while to loop queue */
	ndch('(');			/* check for open parn */
	expresn();			/* init express */
	ndch(';');			/* check for semcol */
	a_lnlabel(queue[WQ_LOOP]);	/* control loop label */
	expresn();			/* loop control express */
	testjmp(queue[WQ_LAB]);		/* see if exit time */
	jump(queue[WQ_BODY]);		/* not time to exit do body */
	ndch(';');			/* check for semcol */
	a_lnlabel(queue[WQ_END]);		/* print end of loop */
	expresn();			/* end loop expression */
	jump(queue[WQ_LOOP]);		/* do loop control expression */
	ndch(')');

	a_lnlabel(queue[WQ_BODY]);
	stment();
	jump(queue[WQ_END]);
	a_lnlabel(queue[WQ_LAB]);
	locptr=queue[WQ_SYM];
	sptr=modstk(queue[WQ_SP],0);
	delwhle();
}

/*	SWITCH
*/

doswtch()
{
	int value[SWITCH_MAX];	/* value for case statement */
	int label[SWITCH_MAX];	/* value for each label */
	int count, temp;	/* number of switches */
	int endlab;		/* label for default */
	int labsw;		/* used for switch label */
	int val;
	int queue[WQ_SIZ];	/* local queue area */
	count=0;		/* number of case statements */
	queue[WQ_SYM]=locptr;	/* local variable pointer */
	queue[WQ_SP]=sptr;	/* save current stack ptr */
	endlab=			/* default exit label */
	queue[WQ_LOOP]=		/* looping label */
	queue[WQ_LAB]=		/* loop exit variable */
	queue[WQ_END]=getlabl();	/* continue label */
	addwhle(queue);		/* add to while stack */


	ndch('(');		/* check to see if"(" exits */
	expresn();		/* expression for switch */
	fpush();
	ndch(')');		/* check for ")" */
	ndch('{');
	jump(labsw=getlabl());
	sptr+=2;

	while(1)
	{
 		if(InSymEq("case"))
		{
			if(!constex(&val))
				errcont(ERCONST);
			if(count<SWITCH_MAX-2)
			{
				value[count]=val;
				a_lnlabel(label[count++]=getlabl());
			}
			else
				errcont(ERTMCAS);
			ndch(':');
		}
		else if(InSymEq("default"))
		{
			endlab=getlabl();
			a_lnlabel(endlab);
			ndch(':');
		}
		else if(InChEq('}'))
		{
			jump(queue[WQ_LAB]);	/* jump past switch data */
			a_lnlabel(labsw);
			execsw(count,labsw=getlabl(),endlab);
			a_lnlabel(labsw);
			for(temp=0;temp<count;++temp)
			{
				defword();
				fo_dec(value[temp]);
				fo_ch(',');
				a_lnlabel(label[temp]);
			}
			delwhle();
			a_lnlabel(queue[WQ_LAB]);
			locptr=queue[WQ_SYM];
			sptr=modstk(queue[WQ_SP],0);
			break;
		}
		else
			stment();
	}
}


/*	CONSTEX
*/

constex(val)
int *val;
{
	InBlanks();

	if(number(val))
		return 1;

	if(pstr(val))
		return 1;

	return 0;
}
