/*	c_cpp.c

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	Integrated preprocessor module.

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

	16 Jan 2001 : Last revision.
	16 Apr 2007 : GPL'd.
*/

#ifndef C_MAIN_H
#include "c_main.h"
#endif

#ifndef C_CPP_H
#include "c_cpp.h"
#endif

extern int fi_files;
extern int fi_line;

extern char line[LN_SIZ];
extern int lptr;
extern int ctext;


/*
	DEFINICIONES
*/

#define CPPMAXIFS 5		/* Maximo numero de #if's anidados */

/*
	VARIABLES
*/

int	cppinasm,		/* TRUE = #asm activo */
	cppincmt,		/* TRUE = comentario activo */
	cppinign,		/* TRUE = #if FALSE activo */

	cppiflev,		/* Nivel de anidamiento de #if's */
	cppifact;		/* Nivel de #if activo */

/* Buffer temporal de entrada */

char cpptmp[LN_SIZ];		/* Datos */
int cpptmpx;			/* Indice */

/* Buffer para #define */

char cppmac[CPPMACSIZ];		/* Datos */
int cppmacx;			/* Indice */

/* Hash */

#define CPPHASHSIZ	53	/* Hash (A...Z a...z _) */

int cpphash[CPPHASHSIZ];

/*
	MENSAJES DE ERROR
*/

#define ERASMWE "#asm without #endasm"
#define EREASWA "#endasm without #asm"
#define ERMACAD "Macro already defined"
#define ERMACUD "Macro not exist"
#define ERTMIFS "Too many active #if's"
#define ERELSEW "#else without #if"
#define ERENDIF "#endif without #if"
#define ERBADCM "Illegal # command"
#define EROFMAC	"Macro table full"

/*
	void cpp_start(void)

	Inicializa el cpp.
	Esta funcion es llamada por el nucleo del compilador.
*/

cpp_start()
{
	int i;

	/* Inicializacion de variables */

	cppinasm=
	cppincmt=
	cppinign=
	cppiflev=
	cppifact=
	cppmacx=0;

	for(i=0; i<CPPHASHSIZ; ++i)
		cpphash[i]=0;
}

cpp_end()
{
/*****
	int i;

	for(i=0; i<CPPHASHSIZ; ++i)
	{
		if(cpphash[i])
		{
			co_dec05(i);co_ch('=');co_dec(cpphash[i]);co_nl();
		}
	}
*******/
}

/*
	void p_cmd(void)

	Ejecuta un comando del preprocesador.
*/

p_cmd()
{
	/* Quitamos el simbolo # */

	BfGet();

	/* #asm esta activo ? */

	if(cppinasm)
	{
		if(InSymEq("endasm"))
		{
			p_endasm();
			BfKill();
			return;
		}

		errcont(ERASMWE);

		cppinasm=0;
	}

	/* Estos comandos se ejecutan siempre */

	if(InSymEq("if"))
		p_if(0);
	else if(InSymEq("else"))
		p_else();
	else if(InSymEq("endif"))
		p_endif();
	else if(InSymEq("ifdef"))
		p_if(1);
	else if(InSymEq("ifndef"))
		p_if(2);

	/* Si estamos dentro de un bloque de codigo que no se */
	/* compila, los siguientes comandos no se ejecutan.   */

	else if(cppinign)
	{
		BfKill();
		return;
	}
	else if(InSymEq("define"))
		p_define();
	else if(InSymEq("undef"))
		p_undef();
	else if(InSymEq("include"))
		p_include();
	else if(InSymEq("asm"))
		p_asm();
	else if(InSymEq("endasm"))
		p_endasm();

	/* Error, comando desconocido */

	else
		errcont(ERBADCM);

	/* Invalidar la linea actual en cualquier caso */

	BfKill();
}

/*
	void p_define(void)

	Comando: #define nombre definicion
*/

p_define()
{
	char s[NAME_SIZ];

	/* Ignorar los espacios hasta el nombre */

	BfBlanks();

	/* Tomar el nombre */

	if(!symname(s))
	{
		errcont(ERSYMNM);
		return;
	}

	/* Ignorar los espacios hasta la definicion */

	BfBlanks();

	/* Preprocesar la definicion */

	p_prep(1);

	/* Almacenar macro */

	p_macput(s,line);
}

/*
	void p_undef(void)

	Comando: #undef nombre
*/

p_undef()
{
	char s[NAME_SIZ];

	/* Ignorar los espacios hasta el nombre */

	BfBlanks();

	/* Tomar el nombre */

	if(!symname(s))
	{
		errcont(ERSYMNM);
		return;
	}

	/* Borrar macro */

	p_macdel(s);
}

/*
	void p_include(void)

	Comando: #include <archivo> | "archivo"
*/

p_include()
{
	char chend;

	/* Avanzar hasta archivo */

	BfBlanks();

	/* Preprocesar */

	p_prep(1);

	/* Mensaje en pantalla */

	msgindent();
	co_str("#include ");co_line(line);

	/* Tomar nombre de archivo */

	if(*line=='"')
		chend='"';
	else if(*line=='<')
		chend='>';
	else
		errcont(ERBADCM);

	BfGet();

	while(BfNeq(chend))
	{
		if(!BfGet())
		{
			errcont(ERBADCM);
			return;
		}
	}

	*(line+lptr)=0;

	/* Abrir archivo */

	fi_open(line+1);
}

/*
	void p_endinc(void)

	Comando: Fin de #include.
*/

p_endinc()
{
	fi_close();

	msgindent();
        co_line("#end include");
}
/*
	void p_asm(void)

	Comando: #asm
*/

p_asm()
{
	/* Mensaje en pantalla y en archivo */

/********
	msgindent();
	co_line("#asm");
*******/
	a_opt(0);

	/* Activar indicador */

	cppinasm=1;
}

/*
	void p_endasm(void)

	Comando: #endasm
*/

p_endasm()
{
	/* #asm esta activo ? */

	if(cppinasm)
	{

		/* Mostrar mensaje en pantalla y en archivo */

/**********
		msgindent();
		co_line("#endasm");
***********/
		a_opt(1);

		/* Borrar indicador */

		cppinasm=0;
	}
	else
		errcont(EREASWA);
}

/*
	void p_if(iftype)

	iftype = 0 -- #if	constante
	iftype = 1 -- #ifdef	macro
	iftype = 2 -- #ifndef	macro
*/

p_if(iftype)
int iftype;
{
	char s[NAME_SIZ];
	int val;

	/* Demasiados #if's anidados ? */

	if(cppiflev == CPPMAXIFS)
	{
		errcont(ERTMIFS);
		return;
	}

	/* Se debe ejecutar ? */

	if(!(cppiflev==cppifact && cppinign==0))
	{
		++cppiflev;
		return;
	}

	/* Avanzar hasta el valor */

	BfBlanks();

	/* Mensaje en pantalla */
/**********
	msgindent();
	co_str("#if");
	if(iftype==2)
		co_ch('n');
	if(iftype)
		co_str("def");
	co_ch(' ');
	co_line(line+lptr);
************/
	/* Tomar valor segun tipo de #if */

	++cppiflev;
	++cppifact;

	if(iftype)
	{
		if(!symname(s))
		{
			errcont(ERSYMNM);
			cppinign=1;
			return;
		}

		cppinign=p_macfind(s)!=-1 ? 0 : 1;

		if(iftype==2)
			cppinign=1-cppinign;
	}
	else
	{
		p_prep(1);

		val=0;

		number(&val);

		cppinign=val ? 0 : 1;
	}
}

/*
	void p_else(void)

	Comando: #else
*/

p_else()
{
	/* #if esta activo ? */

	if(!cppiflev)
		errcont(ERELSEW);
	else if(cppiflev==cppifact)
	{
		/* Mensaje en pantalla */

/**********
		msgindent();
		co_line("#else");
************/
		/* Alternar indicador */

		cppinign=1-cppinign;
	}
}

/*
	void p_endif(void)

	Comando: #endif
*/

p_endif()
{
	/* #if esta activo ? */

	if(!cppiflev)
	{
		errcont(ERENDIF);
		return;
	}

	if(cppiflev==cppifact)
	{
		/* Mensaje en pantalla */
/*********
		msgindent();
		co_line("#endif");
***********/
		--cppifact;
		cppinign=0;
	}

	--cppiflev;
}

/*
	GESTION DE MACROS
*/

p_hash(c)
char c;
{
	if(isupper(c))
		return c - 'A';

	if(islower(c))
		return 26 + c - 'a';

	return 52;
}

/*
	void p_macput(char *sname, char *def)

	Almacenar macro.
*/

p_macput(name,def)
char *name,*def;
{
	int ln,ld;

	if(p_macfind(name)==-1)
	{
		ln=strlen(name);
		ld=strlen(def);

		if((cppmacx+ln+ld+2) <= CPPMACSIZ)
		{
			cppmac[cppmacx++]=ln;
			cppmac[cppmacx++]=ld;
			memcpy(cppmac+cppmacx,name,ln);
			cppmacx+=ln;
			memcpy(cppmac+cppmacx,def,ld);
			cppmacx+=ld;

			++cpphash[p_hash(*name)];
		}
		else
			errexit(EROFMAC);
	}
	else
		errcont(ERMACAD);
}

p_macdel(name)
char *name;
{
	int i, size;

	if((i=p_macfind(name))!=-1)
	{
		size=cppmac[i]+(cppmac[i+1] & 0xFF)+2;
		memcpy(cppmac+i,cppmac+i+size,cppmacx-(i+size));
		cppmacx-=size;

		--cpphash[p_hash(*name)];
	}
	else
		errcont(ERMACUD);
}

/*
	int p_macfind(char *name)

	Busca el nombre de una macro.
	Si lo encuentra, devuelve el indice.
	Si no, devuelve -1.
*/

p_macfind(name)
char *name;
{
	int i, ln, size;

	if(cpphash[p_hash(*name)])
	{
		ln=strlen(name);

		for(i=0; i<cppmacx; i+=size)
		{
			if(ln==cppmac[i])
			{
				if(!memcmp(name, cppmac+i+2, ln))
					return i;
			}

			size=cppmac[i]+(cppmac[i+1] & 0xFF)+2;
		}
	}

	return -1;
}

cpp_read()
{
	int c, lastc;

	while(1)
	{
		lptr=lastc=0;

		/* Leer una linea */

		while(1)
		{
			while(lptr!=LN_SIZ)
			{
				c=fi_ch();

				if(c=='\n' || c==EOF)
					break;

				line[lptr++]=lastc=c;
			}

			if(lastc!='\\' || c!='\n' || cppinasm)
				break;

			--lptr;
			++fi_line;
		}

		/* Fin de archivo ? */

		if(!lptr && c==EOF)
		{
			if(fi_files==1)
				return 1;

			p_endinc();
			continue;
		}

		/* Incrementar numero de linea */

		++fi_line;

		/* Byte terminal */

		if(lptr!=LN_SIZ)
			line[lptr]=0;
		else
		{
			line[LN_MAX]=0;

			errcont(ERLTLNG);
		}

		/* Comenzar a partir del primer caracter en la linea */

		lptr=0;

		/* Hay un comentario pendiente de cerrar ? */

		if(cppincmt)
		{
			while(BfWordNeq('*/'))
			{
				if(!BfGet())
					break;
			}

			if(!BfGet())
				continue;

			BfGet();

			cppincmt=0;
		}

		/* Es un comando del preprocesador ? */

		if(BfEq('#'))
		{
			p_prep(0);
			p_cmd();
		}
		else if(!cppinign)
		{
			/* Ensamblador ? */

			if(cppinasm)
				fo_line(line+lptr);

			/* Codigo fuente C */

			else if(Bf())
			{
				if(ctext)
				{
					comment();fo_line(line);
				}

				p_prep(1);

				return 0;
			}
		}
	}
}

p_prep(sym)
int sym;
{
	int i, x;
	char s[NAME_SIZ];

	cpptmpx=0;

	while(Bf())
	{
		/* Compactar espacios */

		if(BfEq(' ') || BfEq('\t'))
		{
			do
			{
				BfGet();
			}
			while(BfEq(' ') || BfEq('\t'));

			p_keepch(' ');
		}

		/* Es una cadena ? */

		else if(BfEq('"'))
			p_preps('"');

		/* Es una comilla simple ? */

		else if(BfEq('\''))
			p_preps('\'');

		/* Es un comentario ? */

		else if(BfWordEq('/*'))
		{
			BfGet();
			BfGet();

			while(BfWordNeq('*/'))
			{
				if(!BfGet())
				{
					cppincmt=1;
					break;
				}
			}

			BfGet();
			BfGet();
		}

		/* Es un simbolo ? */

		else if(sym && issym1st(Bf()))
		{
			i=0;
			do
			{
				if(i<NAME_MAX)
					s[i++]=BfGet();
				else
					BfGet();
			}
			while(issym(Bf()));

			s[i]=0;

			if((x=p_macfind(s))==-1)
				p_keepstr(s, i);
			else
				p_keepstr(cppmac+x+2+cppmac[x],cppmac[x+1] & 0xFF);
		}
		else
			p_keepch(BfGet());
	}

	/* Se ha excedido la longitud de linea ? */

	if(cpptmpx==LN_SIZ)
	{
		errcont(ERLTLNG);

		--cpptmpx;
	}

	/* Poner terminal */

	p_keepch(0);

	/* Copiar buffer temporal en linea a procesar */

	memcpy(line,cpptmp,cpptmpx);

	lptr=0;
}

p_preps(c)
char c;
{
	do
	{
		if(BfEq('\\'))
			p_keepch(BfGet());

		if(Bf())
			p_keepch(BfGet());
		else
			break;
	}
	while(BfNeq(c));

	if(BfGet())
		p_keepch(c);
}

p_keepstr(s, len)
char *s;
int len;
{
	if(cpptmpx+len>LN_SIZ)
		len=LN_SIZ-cpptmpx;

	memcpy(cpptmp+cpptmpx,s,len);
	cpptmpx+=len;
}

p_keepch(c)
char c;
{
	if(cpptmpx!=LN_SIZ)
		cpptmp[cpptmpx++]=c;
}

msgindent()
{
	int i;

	for(i=1;i<fi_files;++i)
	{
		co_ch(' ');
		co_ch(' ');
	}

}

