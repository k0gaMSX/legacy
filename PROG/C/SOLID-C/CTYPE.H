/*
**	CTYPE.H
**	Character type classification
**	
**	(c) 1995, SOLID
*/

/*	Prototypes.	*/

int	tolower	();	/* convert to lowercase */
int	toupper	();	/* convert to uppercase */
int	isalnum	();	/* A-Za-z0-9 */
int	isalpha	();	/* A-Za-z */
int	isascii	();	/* !..~ */
int	iscntrl	();	/* unprintable control symbol */
int	isdigit	();	/* 0..9 */
int	isgraph	();	/* has graphic reprezentation */
int	islower	();	/* lowercase test */
int	isprint	();	/* printable test */
int	ispunct	();	/* punctuation sign test */
int	isspace	();	/* space test */
int	isupper	();	/* uppercase test */
int	isxdigit();	/* hex digit test */
