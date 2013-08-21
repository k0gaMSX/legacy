/*
 *	The BDS C Standard I/O header file --  v1.50	12/29/82
 *
 *	This is the standard header file used with pre-v1.6 BDS C programs.
 *	It is provided, along with the file DEFF15.CRL, in order to allow
 *	the compilation of C programs originally written for v1.5 to be 
 * 	performed under v1.6. For any program <prog.c>, compilation is as
 *	follows:
 *		cc <prog>
 *		clink <prog> -f deff15
 */


/*
 *	General purpose Symbolic constants:
 */

#define BASE 0		/* Base of CP/M system RAM (0 or 0x4200)  */
#define NULL 0
#define EOF -1		/* Physical EOF returned by low level I/O functions */
#define ERROR -1	/* General "on error" return value */
#define OK 0		/* General purpose "no error" return value */
#define JBUFSIZE 6	/* Length of setjump/longjump buffer	*/
#define CPMEOF 0x1a	/* CP/M End-of-text-file marker (sometimes!)  */
#define SECSIZ 128	/* Sector size for CP/M read/write calls */
#define MAXLINE 250	/* Longest line of text expected from file/console */
#define TRUE 1		/* logical true constant */
#define FALSE 0		/* logical false constant */

/*
 *	The NSECTS symbol controls the compilation of the buffered
 *	I/O routines within STDLIB2.C, allowing each user to set the
 *	buffer size most convenient for his system, while keeping
 *	the numbers totally invisible to the C source programs using
 *	buffered I/O (via the BUFSIZ defined symbol.) For larger
 *	NSECTS, the disk I/O is faster...but more ram is taken up.
 *	To change the buffer size allocation, follow these steps:
 *
 *	1) Change NSECTS below
 *	2) Re-compile STDLIB1.C and STDLIB2.C
 *	3) Use CLIB to combine STDLIB1.CRL and STDLIB2.CRL to make
 *	   a new DEFF.CRL.
 *
 *	Make sure you declare all your I/O buffers with the a
 *	statement such as:
 *
 *		char buf_name[BUFSIZ];
 */

#define NSECTS 8	/* Number of sectors to buffer up in ram */

#define BUFSIZ (NSECTS * SECSIZ + 7)	/* Don't touch this */

struct _buf {				/* Or this...	    */
	int _fd;
	int _nleft;
	char *_nextp;
	char _buff[NSECTS * SECSIZ];
	char _flags;
};

#define FILE struct _buf	/* Poor man's "typedef" */

#define _READ 1
#define _WRITE 2


/*
 * Storage allocation data, used by "alloc" and "free"
 */

struct _header  {
	struct _header *_ptr;
	unsigned _size;
 };

struct _header _base;		/* declare this external data to  */
struct _header *_allocp;	/* be used by alloc() and free()  */
