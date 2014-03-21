/*
 * t r . c	23.06.94
 *
 * Программа преобразования символов
 *
 * TR копирует стандартный ввод на стандартный вывод с замещением или
 * уничтожением выбранных символов.
 *
 * FROM и TO - строки символов. Эффект TR зависит от длины обеих строк.
 *
 * Если FROM и TO одинаковой длины, символы из TO замещают символы
 * из FROM. Так
 *
 *	TR abcd wxyz +start -end
 *
 * изменит все a в w, b в x, и т.д. TR РАЗЛИЧАЕТ буквы по регистрам.
 *
 * Если TO - пустая строка, все символы из FROM уничтожаются.
 *
 * Если TO не пусто, но короче, чем FROM, все символы из FROM, не
 * имеющие пары в TO, будут заменены на последний символ из TO,
 * НО любая последовательность транслируемых таким образом символов
 * усекается до одного результирующего символа. Так:
 *
 *	TR abcde12345 ABCDE-
 *
 * изменит "aAbB1234cCdD5678eEfF" на "AABB-CCDD-678EEfF".
 *
 * Если символ встречается в FROM более одного раза, используется
 * самое левое появление.  Так, для изменения всех строк из '*' в одну
 * звездочку, используйте TR ** *.
 *
 * В добавление к простым символам, FROM и TO могут включать:
 *
 * Эскейпы
 *	\x есть сам x, но \b - бакспейс, \f - формфид, \n - лайнфид,
 *	\r - ретурн, \t - табулятор, \s - пробел и \DDD - символ с
 *	восьмеричным кодом DDD (используется только 8 бит, цифр может быть
 *	и одна, и две, использование \0 вызывает непредсказуемый результат).
 *	Буквы b, f и т.д. могут быть в двух регистрах.
 *
 * Диапазоны
 *	a-e эквивалентно abcde, и т.п.	Заметьте, что e-a допустимый,
 *	но пустой диапазон.
 *
 * Классы
 *	:z	пустой диапазон
 *	:a	эквивалентно a-zA-Z
 *	:l	эквивалентно a-z
 *	:u	эквивалентно A-Z
 *	:m	эквивалентно а-я
 *	:b	эквивалентно А-Я
 *	:r	эквивалентно а-яА-Я
 *	:d	эквивалентно 0-9
 *	:n	эквивалентно a-zA-Z0-9
 *	:s	диапазон от CTRL/A до пробела (001-040)
 *	:.	все ASCII символы, кроме 0 (001-0377)
 *
 *	Так: TR ":a:." "A-ZA-Z "
 *	транслирует все латинские буквы в верхний регистр, и редуцирует
 *	все соследовательности не-букв в один пробел
 *
 *	Идентификаторы класса могут быть в любом регистре.
 *
 * Отрицания
 *	Если первый символ FROM есть '^', это означает все символы не
 *	из FROM. В этом случае TO должно быть пусто или только из одного
 *	символа.
 *
 * '\' and ':' теряют свое спецзначение, если они последний символ FROM
 * или TO; '-' - если он первый символ; '^' - если он не первый символ
 * FROM; любой символ теряет спецзначение после эскейпа ('\').
 *
 * This program is licensed under GNU GPL license.
 *
 */
 
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#define SSIZE	512	/* размер образца */
#define ESCAPE	'\\'	/* символ эскейпа */
#define NOT	'^'	/* символ отрицания */
#define PCLASS	':'	/* префикс класса */
#define RANGE	'-'	/* спецификатор диапазона */

char *hlp[] = {
	"usage: tr FROM TO [+START] [-END] [filein [fileout]]",
	"\tSTART - starting position for transliteration",
	"\tEND - ending position for transliteration",
	"\tlen(FROM) == len(TO):",
	"\t\tchars in TO are substitutes for chars in FROM",
	"\tlen(TO) == 0:",
	"\t\tany chars in FROM are deleted",
	"\tlen(TO) < len(FROM):",
	"\t\tall chars in FROM beyond the last one to match",
	"\t\tup with one in TO translate into the last char",
	"\t\tin TO; BUT any stream of consecutive characters so",
	"\t\ttranslated is reduced to just one occurence of the",
	"\t\tresulting char.",
	"\tEscapes: \\r \\n \\t \\f \\b \\s \\ddd",
	"\tRanges: a-e is the same as abcde (e-a is empty range)",
	"\tClasses:",
	"\t\t:z empty range",
	"\t\t:a is the same as a-zA-Z",
	"\t\t:l is the same as a-z",
	"\t\t:u is the same as A-Z",
	"\t\t:m is the same as а-я",
	"\t\t:b is the same as А-Я",
	"\t\t:r is the same as а-яА-Я",
	"\t\t:d is the same as 0-9",
	"\t\t:n is the same as a-zA-Z0-9",
	"\t\t:s is the range \\001-\\040",
	"\t\t:. is the range including all ASCII other then \\0",
	"\tNegation: if the first character of FROM is '^',",
	"\t\tany characters not in FROM match. In this case, TO",
	"\t\tmust be null or only a single char",
	0
};

void help(void) {
	register int i = 0;
	while (hlp[i])
		fprintf(stderr,"%s\n",hlp[i++]);
	exit(0);
}

void error(char *s1,char *s2) {
	fprintf(stderr, "tr: %s %s\n", s1, s2 ? s2 : "");
	exit(1);
}

int xindex(unsigned char *array, unsigned char c, int allbut, int lastto) {
	register unsigned char *index;

	for (index = array; *index; ++index)
		if (*index == c)
			break;
	if (allbut == 0)
		return(*index ? (index - array) : (-1));
	if (*index)
		return(-1);
	return(lastto+1);
}

/* Вставка символов с lo до hi (включительно) в ttb */
char *insrange(int lo, int hi, char *ttb) {
	for (lo &= 0377, hi &= 0377; lo <= hi; *ttb++ = lo++)
		;
	return ttb;
}

/* Обработка эскейпов
 *
 *	char esc(ppc)
 *	char **ppc;
 *
 * esc(ppc) распознает и обрабатывает escaped-символы.
 * Если *ppc указывает не на '\', esc() просто вернет символ.
 * Иначе, если следующий символ из множества {b,f,n,r,t,s}, возвращается
 * соответствующий код. Если следующий символ - восьмеричная цифра,
 * обрабатывается \ddd, возвращается полученное значение.
 *
 * Если '\' - последний символ, сам '\' возвращается.
 *
 * Если '\' предшествует любому неупомянутому x, x сам возвращается.
 *
 * Во всех случаях, *ppc указывает на последний символ, "проглоченный" esc(),
 * например 't' если вернули <TAB> для '\t'.
 */
char esc(char **ppc) {
	char c, c1;
	char *pc = *ppc;

	if ((c = *pc) != ESCAPE || pc[1] == 0)
		return(c);
	else {
		c = *++pc;
		c1 = tolower(c);
		*ppc = pc;
		if (c1 == 'b')
			return('\b');
		if (c1 == 'f')
			return('\f');
		if (c1 == 'n')
			return('\n');
		if (c1 == 'r')
			return('\r');
		if (c1 == 't')
			return('\t');
		if (c1 == 's')
			return('\040');
		if (c1 >= '0' && c1 <= '7') {
			c -= '0';
			c1 = pc[1];
			if (c1 >= '0' && c1 <= '7') {
				c = (c << 3) + (c1 - '0');
				pc++;
				c1 = pc[1];
				if (c1 >= '0' && c1 <= '7') {
					c = (c << 3) + (c1 - '0');
					pc++;
				}
			}
			*ppc = pc;
			return (c & 0377);
		}
		return (c);
	}
}

/* Расширение диапазона от последнего символа ttb до следующего
 * символа в *ps (может быть "escaped").
 */
char *dorange(char **ps, char *ttb) {
	(*ps)++;				/* пропуск RANGE */
	return insrange(ttb[-1]+1,esc(ps),ttb);
}

/* Построение ttb (таблицы трансляции) из array. */
char *makttb(char *a, char *ttb, char *xxx) {
	int c;
	char *t = ttb;

	for (; (c = *a) != 0; ++a) {
		if ((ttb - t) >= SSIZE)
			error("Expansion to long for",xxx);
		if (c == ESCAPE)
			*ttb++ = esc(&a);
		else if (c == PCLASS && a[1]) {
			switch (c = tolower(*++a)) {
			case 'z':
				break;
			case 'n':
				ttb = insrange('0','9',ttb);
			case 'a':
				ttb = insrange('A','Z',ttb);
			case 'l':
				ttb = insrange('a','z',ttb);
				break;
			case 'u':
				ttb  = insrange('A','Z',ttb);
				break;
			case 'r':
				ttb = insrange('А','Я',ttb);
			case 'm':
				ttb = insrange('а','п',ttb);
				ttb = insrange('р','я',ttb);
				break;
			case 'b':
				ttb = insrange('А','Я',ttb);
				break;
			case 'd':
				ttb = insrange('0','9',ttb);
				break;
			case 's':
				ttb = insrange(1,' ',ttb);
				break;
			case '.':
				ttb = insrange(1,0377,ttb);
				break;
			default:
				error("Unknown class type",a-1);
			}
		}
		else if (*a == RANGE && ttb != t && a[1])
			ttb = dorange(&a,ttb);
		else	*ttb++ = *a;
	}
	*ttb = 0;
	return t;
}

char	*froms,
	*tos;
int	allbut,
	collapse,
	expander,
	lastto;
int	bp = 0,
	ep = 9999;
FILE	*fin = stdin,
	*fout = stdout;

void process(void) {
	int pos = 0;
	int i, c;

	while ((c = getc(fin)) != EOF) {
		pos = (c == '\t') ? (pos+8-(pos&7)) : pos+1;
		if (pos-1 < bp || (ep > 0 && pos-1 > ep)) {
			putc(c,fout);
			goto Cont;
		}
		i = xindex(froms,c,allbut,lastto);
		if (collapse && i >= lastto && lastto >= 0) { /* коллапс */
			putc(tos[lastto],fout);
			do {
				i = xindex(froms,c = getc(fin),allbut,lastto);
				pos = (c == '\t') ? (pos+8-(pos&7)) : pos+1;
			} while (c != EOF && i >= lastto);
			if (c == EOF)
				break;
		}
		if (i >= 0) {
			if (lastto >= 0)
				putc(tos[i],fout);	/* трансляция */
		}					/* иначе - чикаем */
		else	putc(c,fout);			/* копируем */

Cont:		if (c == '\n')
			pos = 0;
	}
}

void main(int argc, char *argv[]) {
	int i, c;
	char *nfin = NULL, *nfout = NULL;
	char *from, *to;

	if (argc < 3)
		help();
	froms = argv[1];
	tos = argv[2];

	for (i = 3; i < argc; i++) {
		to = argv[i];
		c = *to++;
		if (c  == '+')
			bp = atoi(to);
		else if (c == '-')
			ep = atoi(to);
		else if (nfin == NULL)
			nfin = argv[i];
		else if (nfout == NULL)
			nfout = argv[i];
		else	error("Bad option",argv[i]);
	}
	if (bp >= ep)
		error("Illegal +START/-END parameters",0);
	if (nfin != NULL && (fin = fopen(nfin,"rb")) == NULL)
		error("Can't open file",nfin);
	if (nfout != NULL && (fout = fopen(nfout,"wb")) == NULL)
		error("Can't create file",nfout);
	setvbuf(fin,NULL,_IOFBF,0x7000);
	setvbuf(fout,NULL,_IOFBF,0x7000);
	if ((allbut = (*froms == NOT)) != 0)
		froms++;
	from = malloc(SSIZE+1);
	to = malloc(SSIZE+1);
	if (!from || !to)
		error("Not enough memory",0);
	froms = makttb(froms, from, "FROM");
	if (!tos)
		*to = 0;
	else	makttb(tos, to, "TO");
	tos = to;
	lastto = strlen(tos) - 1;
	collapse = (strlen(froms)-1 > lastto || allbut);
	expander = (strlen(froms)-1 < lastto);

#ifdef DEBUG
	fprintf(stderr,"%s%s, allbut %d, lastto %d\n",
		collapse?"Collapse":"",
		expander?"Expander":"",
		allbut,lastto);
	fprintf(stderr,"to: %s\n",tos);
	fprintf(stderr,"from: %s\n",froms);
	fprintf(stderr,"bp = %d, ep = %d\n",bp,ep);
#endif
	process();
	exit(0);
}
