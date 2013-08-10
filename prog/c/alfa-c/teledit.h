
/*
 * Common header file for the TELED package. See TELED.C
 */

/*	The following three defines must be customized by the user:	*/

#define HC	"\033[H*"		/* Home cursor and print a "*"	*/
#define	SPECIAL	'^'-0x40		/* Gets out of terminal mode	*/
#define	CPUCLK 4			/* CPU clock rate, in MHz 	*/
#define EDITOR	TRUE			/* TRUE to include edit ability */

/* 	The rest of the defines need not be modified			*/

#define	SOH 1
#define	EOT 4
#define	ACK 6
#define	BELL 7
#define	CTRL_X	'X' - 0x40
#define	ERRORMAX 10
#define	RETRYMAX 10
#define	LF 10
#define	CR 13
#define	SPS 450				/* loops per second */
#define	NAK 21
#define	TIMEOUT -1
#define	TBFSIZ NSECTS*SECSIZ
#define	ML 1000				/* maximum source lines */
#define SEARCH_FIRST	17		/* BDOS calls */
#define SEARCH_NEXT	18
#define CRC 'C'

int	crc_flag;
int	sectnum;
int	toterr;
int	checksum;
int	fd;
int	bufctr;
int	nlines, nl;			/* number of lines */
int	linect;				/* current line	*/

unsigned crc_value;

char	jump_buf[JBUFSIZE];
char	linebuf[MAXLINE];		/* string buffer */
char	buffer[BUFSIZ];
char	fnambuf[50];			/* name of file for text collection */
char	halfdup;			/* Half-Duplex mode */
char	hostflg;			/* true in Host mode */
char	sflg;				/* transmit flag */
char	fflg;				/* text collection file flag */

