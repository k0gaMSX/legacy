/* ctype.h	Character classification and conversion
 */
#ifndef __CTYPE_H
#define __CTYPE_H

#ifdef _MSX_DOS 	/* HI-TECH-C/MSX-DOS	CTYPE.H */

#define _U	0x01
#define _L	0x02
#define _N	0x04
#define _S	0x08
#define _P	0x10
#define _C	0x20
#define _X	0x40

extern	unsigned char	_ctype_[];
			/* in libc.lib */

#define isalpha(c)	((_ctype_+1)[c]&(_U|_L))
#define isupper(c)	((_ctype_+1)[c]&_U)
#define islower(c)	((_ctype_+1)[c]&_L)
#define isdigit(c)	((_ctype_+1)[c]&_N)
#define isxdigit(c)	((_ctype_+1)[c]&(_N|_X))
#define isspace(c)	((_ctype_+1)[c]&_S)
#define ispunct(c)	((_ctype_+1)[c]&_P)
#define isalnum(c)	((_ctype_+1)[c]&(_U|_L|_N))
#define isprint(c)	((_ctype_+1)[c]&(_P|_U|_L|_N|_S))
#define isgraph(c)	((_ctype_+1)[c]&(_P|_U|_L|_N))
#define iscntrl(c)	((_ctype_+1)[c]&_C)
#define isascii(c)	(!((c)&0xFF80))
#define toascii(c)	((c)&0x7F)

extern char toupper(char);
extern char tolower(char);
extern char * strupr(char *);
extern char * strlwr(char *);

#else		/* UZIX-hosted	CTYPE.H */

extern unsigned char __ctype[];

#define __CT_c	0x01		/* control character */
#define __CT_u	0x02		/* upper case */
#define __CT_l	0x04		/* lower case */
#define __CT_d	0x08		/* numeric digit */
#define __CT_s	0x10		/* whitespace */
#define __CT_p	0x20		/* punctuation */
#define __CT_x	0x40		/* hexadecimal */

#define __CT_a	(__CT_u|__CT_l) /* alpha */

/* always functions ! */
extern int toupper __P((int));
extern int tolower __P((int));

#define _toupper(c)	(islower(c) ? (c)^0x20 : (c))
#define _tolower(c)	(isupper(c) ? (c)^0x20 : (c))
#define __toupper(c)	((c)^0x20)
#define __tolower(c)	((c)^0x20)
#define toascii(c)	((c)&0x7F)

#define _CTYPE(c)	(__ctype[(unsigned char)(c)])

/* Note the '!!' is a cast to 'bool' and even BCC deletes it in an if()  */
#define isascii(c)	(!((c)&~0x7F))
#define isalnum(c)	(!!(_CTYPE(c)&(__CT_a|__CT_d)))
#define isalpha(c)	(!!(_CTYPE(c)&__CT_a))
#define iscntrl(c)	(!!(_CTYPE(c)&__CT_c))
#define isdigit(c)	(!!(_CTYPE(c)&__CT_d))
#define isgraph(c)	(! (_CTYPE(c)&(__CT_c|__CT_s)))
#define islower(c)	(!!(_CTYPE(c)&__CT_l))
#define isprint(c)	(! (_CTYPE(c)&__CT_c))
#define ispunct(c)	(!!(_CTYPE(c)&__CT_p))
#define isspace(c)	(!!(_CTYPE(c)&__CT_s))
#define isupper(c)	(!!(_CTYPE(c)&__CT_u))
#define isxdigit(c)	(!!(_CTYPE(c)&__CT_x))

#define isdecimal(c)	isdigit(c)
#define isoctal(c)	((c) >= '0' && (c) <= '7')

#endif					/* END OF CTYPE.H DEFINITION */

#endif /* __CTYPE_H */
