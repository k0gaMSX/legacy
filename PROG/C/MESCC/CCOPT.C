/*	ccopt.c

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	Optimizer.

	Copyright (c) 2000-2007 Miguel I. Garcia Lopez

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

	Compiled with MESCC: cc ccopt.c -s:2048

	Revisions:

	10 Nov 2000 : v0.10
	17 Jan 2001 : General revision.
	17 Mar 2001 : Minor changes.
	19 Mar 2001 : v0.20
	16 Apr 2007 : GPL'd.

	NOTES:

	Need a revision for last changes in compiler output
	and del_file, ren_file and getdisk functions.
*/

#include <mescc.h>
#include <conio.h>
#include <string.h>
#include <ctype.h>
#include <mem.h>
#include <alloc.h>
#include <printf.h>
#include <sprintf.h>
#include <fileio.h>

/*	GLOBALS
*/

char	ifname[15],	/* Input file name */
	ofname[15];	/* Output file name */

FILE	*ifp,		/* Input channel */
	*ofp;		/* Output channel */

int	ieof;		/* TRUE if eof in input */

int	iline,		/* Current line number for input */
	oline;		/* Current line number for output */

#define ILIN_NUM 20	/* Max. lines in buffer */
#define ILIN_MIN 10	/* Min. lines in buffer */
#define ILIN_SIZ 100	/* Size in bytes for each line */
#define ILIN_MAX 99	/* Max. lenght in bytes for data in each line */

int bf[ILIN_NUM];	/* Pointer to lines */

/*	PROGRAM
*/

main(argc, argv)
int argc, argv[];
{
	int i;
	char *ptr;

	printf("Mike's Enhanced Small C Compiler Optimizer v1.00 - 16 Apr 2007\n\n");

	if(argc==1)
		error("ccopt fname.typ [-td]");

	*ifname=*ofname=0;

	for(i=2; i<argc; ++i)
	{
		ptr=argv[i];

		if(*ptr++!='-')
			error("Bad option");

		if(*ptr=='t')
			*ofname=toupper(*(++ptr));
		else
			error("Bad option (2)");
	}

	ptr=argv[1];

	if(*(ptr+2)!=':')
	{
		ifname[0]=getdisk()+'A';
		ifname[1]=':';
		ifname[2]=0;		
	}

	strcat(ifname, argv[1]);

	if(*ofname==0)
		ofname[0]=getdisk()+'A';

	strcpy(ofname+1, ":scopt.tmp");

	optimize();
}

int saved[10];
char zfname[15];

char *ibuf;

optimize()
{
	int i, pass, flag, tsaved, psaved, lsaved;
	char *tmp;

	if((ibuf=tmp=malloc(ILIN_NUM * ILIN_SIZ))==NULL)
		error("No memory for input buffer");

	for(i=0; i<ILIN_NUM; ++i)
	{
		bf[i]=tmp;
		*tmp=0;
		tmp+=ILIN_SIZ;
	}

	flag=0;
	tsaved=0;

	for(pass=0; pass<4; ++pass)
	{
		printf("Pass %d.",pass);

		if(pass==3)
		{
			free(ibuf);
			if((ibuf=malloc(ILIN_SIZ))==NULL)
				error("No memory for input buffer (pass 3)");
		}

		for(i=0; i<10; ++i)
			saved[i]=0;

		psaved=0;

		while(1)
		{
			iopen();
			oopen();

			if(pass==0)
				pass0();
			else if(pass==1)
				pass1();
			else if(pass==2)
				pass2();
			else
				pass3();

			iclose();
			oclose();

			strcpy(zfname, ifname);
			strcpy(ifname, ofname);
			strcpy(ofname, zfname);

			flag=1-flag;

			lsaved=0;

			for(i=0; i<10; ++i)
				lsaved+=saved[i];

			if(pass)
			{
				putchar('\n');

				if(pass==1)
					smry1();
				else if(pass==2)
					smry2();
				else
					smry3();

				psaved=lsaved;

				break;
			}

			if(psaved==lsaved)
			{
				putchar('\n');

				smry0();

				break;
			}

			psaved=lsaved;
		}

		tsaved+=psaved;
	}

	free(ibuf);

	if(flag)
	{
		if(*ifname==*ofname)
		{
			if(del_file(ofname))
				errorf("Can't delete",ofname);
			ren_file(ifname, ofname);
		}
		else
		{
			iopen();
			oopen();

			while((i=fgetc(ifp))!=EOF)
			{
				if(fputc(i, ofp)==EOF)
					errorf("Can't write",ofname);
			}

			iclose();
			oclose();

			if(del_file(ifname))
				errorf("Can't delete",ifname);
		}
	}
	else
	{
		if(del_file(ofname))
			errorf("Can't delete",ofname);
	}

	putchar('\n');
	putsmry("Total bytes saved",tsaved);
}

smry0()
{
	putsmry("Constant expressions",saved[0]);
	putsmry("Constant unary expressions",saved[1]);
	putsmry("Constant array subscript",saved[2]);
	putsmry("Offset + or - offset or const.",saved[3]);
}

smry1()
{
	putsmry("?, push HL, ld HL n, pop DE, +",saved[0]);
	putsmry("?, push HL, ld HL, pop DE, ar.op.",saved[1]);
	putsmry("ld HL, push HL, ld HL, pop DE",saved[2]);
}

smry2()
{
	putsmry("push HL, ld HL, pop DE",saved[0]);
	putsmry("Local variables access",saved[1]);
	putsmry("ld HL, add HL,SP, ld DE, add HL,DE",saved[2]);
	putsmry("Expand CALL ccne (always 0)",saved[3]);
	putsmry("CALL ?, RET",saved[4]);
	putsmry("JP ?, JP ?",saved[5]);
	putsmry("ld HL ofs, CALL ccgw",saved[6]);
	putsmry("JP Z,a, JP b, a:",saved[7]);
}

smry3()
{
	putsmry("JP [Z],? to JR [Z],?", saved[0]);
}

int inasm;

testasm(buf)
char *buf;
{
	if(inasm)
	{
		if(!strcmp(";@+o",buf))
			inasm=0;
		owrite(buf);
		return 1;
	}

	if(!strcmp(";@-o",buf))
	{
		inasm=1;
		owrite(buf);
		return 1;
	}

	return 0;
}

testasmbf()
{
	if(testasm(bf[0]))
	{
		lindel();
		return 1;
	}

	return 0;
}



int lastlin;

pass0()
{
	int i;

	lastlin=inasm=0;

	while(1)
	{
		for(i=lastlin; i<ILIN_MIN; ++i)
		{
			if(!iread(bf[i], ILIN_MAX))
				++lastlin;
		}

		if(lastlin<=0)
			break;

		if(testasmbf())
			continue;

		if(pass0_0())
			continue;
		if(pass0_1())
			continue;
		if(pass0_2())
			continue;
		if(pass0_3())
			continue;

		owrite(bf[0]);
		lindel();
	}
}


pass1()
{
	int i;

	lastlin=inasm=0;

	while(1)
	{
		for(i=lastlin; i<ILIN_MIN; ++i)
		{
			if(!iread(bf[i], ILIN_MAX))
				++lastlin;
		}

		if(lastlin<=0)
			break;

		if(testasmbf())
			continue;

		if(pass1_0())
			continue;
		if(pass1_1())
			continue;
		if(pass1_2())
			continue;

		owrite(bf[0]);
		lindel();
	}
}

#define LAB_MAX 1000

int labels, *labnum, *lablin;


pass2()
{
	int i, *plabnum, *plablin;
	char *ptr;

	lastlin=inasm=labels=0;

	if((labnum=plabnum=malloc(LAB_MAX + LAB_MAX))==NULL)
		error("No memory for labels (number)");
	if((lablin=plablin=malloc(LAB_MAX + LAB_MAX))==NULL)
		error("No memory for labels (lines)");


	while(1)
	{
		for(i=lastlin; i<ILIN_MIN; ++i)
		{
			if(!iread(bf[i], ILIN_MAX))
				++lastlin;
		}

		if(lastlin<=0)
			break;

		if(testasmbf())
			continue;

		/* */

		ptr=bf[0];

		if(isalpha(*ptr++))
		{
			i=0;

			while(isdigit(*ptr))
				i=i*10+(*ptr++)-'0';

			if(!(*ptr))
			{
				if(++labels==LAB_MAX)
					error("Too many labels");

				*plabnum++=i;
				*plablin++=oline;

				owrite(bf[0]);
				lindel();

				continue;
			}
		}

		/* */

		if(pass2_0())
			continue;
		if(pass2_1())
			continue;
		if(pass2_2())
			continue;
		if(pass2_3())
			continue;
		if(pass2_4())
			continue;
		if(pass2_5())
			continue;
		if(pass2_6())
			continue;
		if(pass2_7())
			continue;

		owrite(bf[0]);
		lindel();
	}
}

pass3()
{
	char *ptr;
	int i, flag, num, *plabnum, *plablin;

	inasm=0;

	while(1)
	{
		if(iread(ibuf, ILIN_MAX))
			break;

		if(testasm(ibuf))
			continue;

		while(1)
		{

			if(matchs("\tJP Z,",ibuf))
				flag=2;
			else if(matchs("\tJP ",ibuf))
				flag=0;
			else
				break;
			
			ptr=ibuf+4+flag;

			if(!isalpha(*ptr++))
				break;

			num=0;

			while(isdigit(*ptr))
				num=num*10+(*ptr++)-'0';

			if(*ptr)
				break;

			plabnum=labnum;
			plablin=lablin;

			for(i=0; i<labels; ++i)
			{
				if(*plabnum==num)
				{
					num=*plablin-iline;
					if(num<0)
						num=-num;
					if(num<36)
					{
						*(ibuf+2)='R';
						++saved[0];
					}

					break;
				}

				++plabnum;
				++plablin;
			}

			break;
		}

		owrite(ibuf);
	}

	free(labnum);
	free(lablin);
}

lindel()
{
	int i;
	char *ptr;

	ptr=bf[0];

	for(i=0; i<(ILIN_NUM-1); ++i)
		bf[i]=bf[i+1];

	bf[ILIN_NUM-1]=ptr;

	*ptr=0;

	--lastlin;
}

linins()
{
	int i;
	char *ptr;

	if(lastlin==ILIN_NUM)
		error("Too many lines in buffer");

	ptr=bf[ILIN_NUM-1];

	for(i=(ILIN_NUM-1); i; --i)
		bf[i]=bf[i-1];

	bf[0]=ptr;

	*ptr=0;	

	++lastlin;
}

/*
	LD HL,<num1>		LD HL,<result num>
	PUSH HL
	LD HL,<num2>
	POP DE
	<arithmetic operation>
*/

pass0_0()
{
	int num1, num2;
	char *ptr;

	if(!matchs("\tLD HL," ,bf[0]) || !rint(bf[0]+7, &num1))
		return 0;
	if(!match("\tPUSH HL" ,bf[1]))
		return 0;
	if(!matchs("\tLD HL," ,bf[2]) || !rint(bf[2]+7, &num2))
		return 0;
	if(!match("\tPOP DE",bf[3]))
		return 0;
	if(match("\tADD HL,DE",bf[4]))
	{
		num1+=num2;
		saved[0]+=6;
	}
	else if(matchs("\tCALL cc",bf[4]))
	{
		ptr=bf[4]+8;

		if(match("sub",ptr))
			num1-=num2;
		else if(match("mul",ptr))
			num1=num1*num2;
		else if(match("umul",ptr))
			num1=num1*num2;
		else if(match("div",ptr))
			num1=num1/num2;
		else if(match("mod",ptr))
			num1=num1%num2;
		else if(match("or",ptr))
			num1=num1 | num2;
		else if(match("and",ptr))
			num1=num1 & num2;
		else if(match("xor",ptr))
			num1=num1 ^ num2;
		else if(match("eq",ptr))
			num1=num1 == num2;
		else if(match("ne",ptr))
			num1=num1 != num2;
		else if(match("gt",ptr))
			num1=num1 > num2;
		else if(match("lt",ptr))
			num1=num1 < num2;
		else if(match("ge",ptr))
			num1=num1 >= num2;
		else if(match("le",ptr))
			num1=num1 <= num2;
		else if(match("lgor",ptr))
			num1=num1 || num2;
		else if(match("lgand",ptr))
			num1=num1 && num2;
		else if(match("asr",ptr))
			num1=num1 >> num2;
		else if(match("asl",ptr))
			num1=num1 << num2;
		else
			return 0;

		saved[0]+=8;
	}
	else
		return 0;

	sprintf(bf[4],"\tLD HL,%d",num1);

	lindel();lindel();lindel();lindel();

	return 1;
}

/*
	LD HL,<number>		LD HL,<result number+number>
	ADD HL,HL

	eg: !5

	LD HL,<number>		LD HL,<result !number>
	CALL cclgnot

	eg: -2

	LD HL,<number>		LD HL,<result -number>
	CALL ccneg

	eg: ~1

	LD HL,<number>		LD HL,<result ~number>
	CALL cccom
*/

pass0_1()
{
	int num;

	if(!matchs("\tLD HL," ,bf[0]) || !rint(bf[0]+7, &num))
		return 0;
	if(match("\tADD HL,HL",bf[1]))
	{
		num+=num;
		++saved[1];
	}
	else if(matchs("\tCALL cc",bf[1]))
	{
		if(match("lgnot",bf[1]+8))
			num=!num;
		else if(match("neg",bf[1]+8))
			num=-num;
		else if(match("com",bf[1]+8))
			num=~num;
		else
			return 0;

		saved[1]+=3;
	}
	else
		return 0;

	sprintf(bf[1],"\tLD HL,%d",num);

	lindel();

	return 1;
}

/*
	eg: char c[0]

	LD HL,<variable>	LD HL,<variable>
	PUSH HL
	LD HL,0
	POP DE
	ADD HL,DE

	eg: int i[0]

	LD HL,<variable>	LD HL,<variable>
	PUSH HL
	LD HL,0
	ADD HL,HL
	POP DE
	ADD HL,DE

	eg: char c[4]

	LD HL,<variable>	LD HL,<variable> + <num>
	PUSH HL
	LD HL,<num>
	POP DE
	ADD HL,DE

	eg: int i[4]

	LD HL,<variable>	LD HL,<variable> + <result num + num>
	PUSH HL
	LD HL,<num>
	ADD HL,HL
	POP DE
	ADD HL,DE
*/

pass0_2()
{
	int num, isint;
	char *ptr;

	ptr=bf[0]+7;

	if(!matchs("\tLD HL,",bf[0]) || !isalpha(*ptr))
		return 0;
	if(!match("\tPUSH HL",bf[1]))
		return 0;
	if(!matchs("\tLD HL,",bf[2]))
		return 0;
	if(!rint(bf[2]+7,&num))
		return 0;

	if(match("\tADD HL,HL",bf[3]))
		isint=1;
	else
		isint=0;

	if(!match("\tPOP DE",bf[3+isint]))
		return 0;
	if(!match("\tADD HL,DE",bf[4+isint]))
		return 0;

	if(num)
	{
		if(isint)
			num+=num;

		sprintf(bf[4+isint],"%s+%d",bf[0],num);
	}
	else
		strcpy(bf[4+isint],bf[0]);


	saved[2]+=6+isint;

	num=4+isint;

	while(num--)
		lindel();

	return 1;
}

/*
	LD HL,<variable>	LD HL,<variable> + | - <variable | num>
	PUSH HL
	LD HL,<variable | num>
	POP DE
	ADD HL,DE | CALL ccsub
*/

pass0_3()
{
	int num, flagcall, flagnum;
	char *ptr;

	ptr=bf[0]+7;

	if(!matchs("\tLD HL,",bf[0]) || !isalpha(*ptr))
		return 0;
	if(!match("\tPUSH HL",bf[1]))
		return 0;
	if(!matchs("\tLD HL,",bf[2]))
		return 0;
	ptr=bf[2]+7;
	if(isalpha(*ptr))
		flagnum=0;
	else if(rint(ptr,&num))
		flagnum=1;
	else
		return 0;
	if(!match("\tPOP DE",bf[3]))
		return 0;
	if(match("\tADD HL,DE",bf[4]))
		flagcall=0;
	else if(match("\tCALL ccsub",bf[4]))
		flagcall=2;
	else
		return 0;

	strcpy(bf[4], bf[0]);
	if(flagcall)
		strcat(bf[4],"-");
	else
		strcat(bf[4],"+");
	strcat(bf[4],bf[2]+7);

	lindel();lindel();lindel();lindel();

	saved[3]+=6+flagcall;

	return 1;
}

/*
	?			?
	PUSH HL			INC HL
	LD HL,<num>		INC HL
	POP DE			... Until 3 times
	ADD HL,DE
*/

pass1_0()
{
	int i, num;

	if(!match("\tPUSH HL",bf[1]))
			return 0;
	if(!matchs("\tLD HL,",bf[2]) || !rint(bf[2]+7,&num))
			return 0;
	if(num<0 || num>3)
		return 0;
	if(!match("\tPOP DE",bf[3]))
			return 0;
	if(!match("\tADD HL,DE",bf[4]))
			return 0;

	strcpy(bf[4], bf[0]);

	i=4-num;

	while(i--)
		lindel();

	if(num)
	{
		strcpy(bf[0], bf[num]);

		for(i=0; i<num; ++i)
			strcpy(bf[i+1], "\tINC HL");
	}

	saved[0]+=6-num;

	return 1;
}




/*
	?			?
	PUSH HL			LD DE,<anything2>
	LD HL,<anything2>	<arithmetic op>
	POP DE
	<arithmetic op>

	valid arith. ops:

	ADD HL,DE
	CALL ccmul
	CALL ...
*/

pass1_1()
{
	char *ptr;

	if(!match("\tPUSH HL",bf[1]))
			return 0;
	if(!matchs("\tLD HL,",bf[2]))
			return 0;
	if(!match("\tPOP DE",bf[3]))
			return 0;
	if(match("\tADD HL,DE",bf[4]));
	else if(matchs("\tCALL cc",bf[4]))
	{
		ptr=bf[4]+8;

		if(match("mul",ptr));
		else if(match("umul",ptr));
		else if(match("or",ptr));
		else if(match("and",ptr));
		else if(match("xor",ptr));
		else if(match("eq",ptr));
		else if(match("ne",ptr));
		else if(match("lgor",ptr));
		else if(match("lgand",ptr));
		else
			return 0;
	}
	else
		return 0;

	strcpy(bf[3], bf[2]);
	ptr=bf[3]+4;
	*ptr++='D';
	*ptr='E';
	strcpy(bf[2], bf[0]);
	lindel();lindel();
	saved[1]+=2;

	return 1;
}


/*
	LD HL,<anything1>	LD DE,<anything1>
	PUSH HL			LD HL,<anything2>
	LD HL,<anything2>
	POP DE
*/

pass1_2()
{
	char *ptr;

	if(matchs("\tLD HL,",bf[0]))
	{
		if(match("\tPUSH HL",bf[1]))
		{
			if(matchs("\tLD HL,",bf[2]))
			{
				if(match("\tPOP DE",bf[3]))
				{
					strcpy(bf[3],bf[2]);
					strcpy(bf[2],bf[0]);
					ptr=bf[2]+4;
					*ptr++='D';
					*ptr='E';
					lindel();lindel();
					saved[2]+=2;

					return 1;
				}
			}
		}
	}

	return 0;
}




/*
	PUSH HL			EX DE,HL
	LD HL,<anything>	LD HL,<anything>
	POP DE
*/

pass2_0()
{
	if(match("\tPUSH HL",bf[0]))
	{
		if(matchs("\tLD HL,",bf[1]))
		{
			if(match("\tPOP DE",bf[2]))
			{
				owrite("\tEX DE,HL");
				owrite(bf[1]);

				lindel();lindel();lindel();

				++saved[0];

				return 1;
			}
		}
	}

	return 0;
}

/*
	LD HL,0		POP HL
	ADD HL,SP	PUSH HL
	CALL ccgw

	LD HL,2		POP BC
	ADD HL,SP	POP HL
	CALL ccgw	PUSH HL
			PUSH BC

	1 y 4 tambien
*/

pass2_1()
{
	int num;

	if(!matchs("\tLD HL," ,bf[0]) || !rint(bf[0]+7, &num))
		return 0;

	if(!match("\tADD HL,SP" ,bf[1]))
		return 0;

	if(!match("\tCALL ccgw" ,bf[2]))
		return 0;

	if(num==0)
	{
		owrite("\tPOP HL");
		owrite("\tPUSH HL");

		lindel();lindel();lindel();

		saved[1]+=5;
	}
	else if(num==1)
	{
		owrite("\tPOP HL");
		owrite("\tPOP BC");
		owrite("\tPUSH BC");
		owrite("\tPUSH HL");
		owrite("\tLD L,H");
		owrite("\tLD H,C");

		lindel();lindel();lindel();

		++saved[1];
	}
	else if(num==2)
	{
		owrite("\tPOP BC");
		owrite("\tPOP HL");
		owrite("\tPUSH HL");
		owrite("\tPUSH BC");

		lindel();lindel();lindel();

		saved[1]+=3;
	}
	else if(num==4)
	{
		owrite("\tPOP BC");
		owrite("\tPOP DE");
		owrite("\tPOP HL");
		owrite("\tPUSH HL");
		owrite("\tPUSH DE");
		owrite("\tPUSH BC");

		lindel();lindel();lindel();

		++saved[1];
	}
	else
		return 0;

	return 1;
}

/*
	LD HL,num1	LD HL,num1+num2
	ADD HL,SP	ADD HL,SP
	LD DE,num2
	ADD HL,DE

*/

pass2_2()
{
	int num1, num2;

	if(!matchs("\tLD HL,",bf[0]) || !rint(bf[0]+7, &num1))
		return 0;
	if(!match("\tADD HL,SP",bf[1]))
		return 0;
	if(!matchs("\tLD DE,",bf[2]) || !rint(bf[2]+7, &num2))
		return 0;
	if(!match("\tADD HL,DE",bf[3]))
		return 0;


	sprintf(bf[0]+7,"%d",num1+num2);
	owrite(bf[0]);
	owrite(bf[1]);

	lindel();lindel();
	lindel();lindel();

	saved[2]+=4;

	return 1;
}

/*
	CALL ccne	OR A
			SBC HL,DE
*/

pass2_3()
{
	if(match("\tCALL ccne",bf[0]))
	{
		owrite("\tOR A");
		owrite("\tSBC HL,DE");

		lindel();

		/* saved 0 bytes */

		return 1;
	}

	return 0;
}


/*
	CALL ?		JP ?
	RET
*/

pass2_4()
{
	if(matchs("\tCALL " ,bf[0]))
	{
		if(match("\tRET",bf[1]))
		{
			owrite(strcat(strcpy(bf[1],"\tJP"),bf[0]+5));

			lindel();lindel();

			++saved[4];

			return 1;
		}
	}

	return 0;
}

/*
	JP ?	JP ?	(if ? = ?)
	JP ?
*/

pass2_5()
{
	if(matchs("\tJP " ,bf[0]))
	{
		if(matchs("\tJP ",bf[1]))
		{
			if(match(bf[0]+4,bf[1]+4))
			{
				owrite(bf[0]);
				lindel();lindel();
				saved[5]+=3;

				return 1;
			}
		}
	}

	return 0;
}

/*	Treat generated code in previous phases:

	LD HL,<var>	LD HL,(var)
	CALL ccgw
*/

pass2_6()
{
	char *ptr;

	ptr=bf[0]+7;

	if(!matchs("\tLD HL," ,bf[0]) || !isalpha(*ptr))
		return 0;
	if(!match("\tCALL ccgw" ,bf[1]))
		return 0;

	sprintf(bf[1], "\tLD HL,(%s)",ptr);
	lindel();

	saved[6]+=3;

	return 1;
}

/*		JP Z,label1		JP NZ,label2
		JP label2	label1:
	label1:
*/

pass2_7()
{
	char *ptr;

	if(!matchs("\tJP Z," ,bf[0]))
		return 0;
	if(!matchs("\tJP ",bf[1]))
		return 0;
	ptr=bf[2]+strlen(bf[2])-1;
	if(!matchs(bf[0]+6,bf[2]) || *ptr!=':')
		return 0;

	strcpy(bf[0], bf[1]);
	sprintf(bf[1],"\tJP NZ,%s",bf[0]+4);
	lindel();

	saved[7]+=3;

	return 1;
}

match(str1, str2)
char *str1, *str2;
{
	return strcmp(str1, str2)==0;
}

matchs(str1, str2)
char *str1, *str2;
{
	return memcmp(str1, str2, strlen(str1))==0;
}

rint(str, val)
char *str;
int *val;
{
	int minus;

	*val=0;

	if(*str=='-')
	{
		minus=1;
		++str;
	}
	else
		minus=0;

	while(isdigit(*str))
	{
		*val=*val*10+(*str-'0');
		*str++;
	}

	if(*str)
		return 0;

	if(minus)
		*val=-(*val);

	return 1;
}


iopen()
{
	if((ifp=fopen(ifname, "r"))==NULL)
		errorf("Can't open", ifname);

	iline=ieof=0;
}

/* Return 1 on eof, else 0 */

iread(buf, max)
char *buf;
int max;
{
	int i, c;

	if(ieof)
	{
		*buf=0;
		return 1;
	}

	++iline;

	for(i=0; i < max; ++i)
	{
		if((c=fgetc(ifp))==EOF)
		{
			ieof=1;
			*buf=0;

			return i ? 0 : 1;
		}

		if(c!='\n')
			*buf++=c;
		else
		{
			*buf=0;
			return 0;
		}
	}

	errorf("Line too long in", ifname);
}

iclose()
{
	if(fclose(ifp)==EOF)
		errorf("Can't close", ifname);
}

oopen()
{
	if((ofp=fopen(ofname, "w"))==NULL)
		errorf("Can't open", ofname);

	oline=0;
}

owrite(buf)
char *buf;
{
	while(*buf)
	{
		if(fputc(*buf++, ofp)==EOF)
			errorf("Can't write", ofname);
	}

	fputc('\n', ofp);

	++oline;
}

oclose()
{
	if(fclose(ofp)==EOF)
		errorf("Can't close", ofname);
}

putsmry(txt, val)
char *txt;
int val;
{
	int i;

	printf("\t%s ",txt);

	i=50-strlen(txt);

	while(i--)
		putchar('.');

	printf(" %5d\n",val);
}

error(txt)
char *txt;
{
	printf("ERROR: %s\n",txt);
	exit(1);
}

errorf(txt, fname)
char *txt, *fname;
{
	printf("ERROR: %s %s\n",txt,fname);
	exit(1);
}

/*******************/

char xxfcb[54];

del_file(fname)
char *fname;
{
	if(setfcb(fname, xxfcb))
		return -1;
	bdos_a(26, 0x80); /* Set DMA */
	if(bdos_a(19, xxfcb)==255) /* Del file */
		return -1;
	return 0;
}

ren_file(fold, fnew)
char *fold, *fnew;
{
	bdos_a(26, 0x80); /* Set DMA */

	if(setfcb(fold, xxfcb))
		return -1;
	if(bdos_a(17, xxfcb)==255) /* Search old */
		return -1;

	if(setfcb(fnew, xxfcb+16))
		return -1;
	if(bdos_a(17, xxfcb+16)!=255) /* Search new */
		return -1;

	if(bdos_a(23, xxfcb)==255) /* Rename */
		return -1;

	return 0;
}

getdisk()
{
	return bdos_a(25,0);
}


