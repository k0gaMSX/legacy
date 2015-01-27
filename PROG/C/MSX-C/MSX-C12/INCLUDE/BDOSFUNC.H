/*
	(C) Copyright by ASCII Corporation, 1989
		All rights Reserved.

	File: bdosfunc.h	MSX-DOS Function Call Support
*/
#ifndef	HEADERbdosfunc
#define HEADERbdosfunc

#ifndef HEADERtype
#include <type.h>
#endif

#define	_TERM0		(TINY)0x00	/* Program terminate		*/
#define	_CONIN		(TINY)0x01	/* Console input		*/
#define	_CONOUT		(TINY)0x02	/* Console output		*/
#define	_AUXIN		(TINY)0x03	/* Auxiliary input		*/
#define	_AUXOUT		(TINY)0x04	/* Auxiliary output		*/
#define	_LSTOUT		(TINY)0x05	/* Printer output		*/
#define	_DIRIO		(TINY)0x06	/* Direct console I/O		*/
#define	_DIRIN		(TINY)0x07	/* Direct console input		*/
#define	_INNOE		(TINY)0x08	/* Console input without echo	*/
#define	_STROUT		(TINY)0x09	/* String output		*/
#define	_BUFIN		(TINY)0x0a	/* Buffered line input		*/
#define	_CONST		(TINY)0x0b	/* Console status		*/
#define	_CPMVER		(TINY)0x0c	/* Return CP/M version number	*/
#define	_DSKRST		(TINY)0x0d	/* Disk reset			*/
#define	_SELDSK		(TINY)0x0e	/* Select disk			*/
#define	_FOPEN		(TINY)0x0f	/* Open file (FCB)		*/
#define	_FCLOSE		(TINY)0x10	/* Close file (FCB)		*/
#define	_SFIRST		(TINY)0x11	/* Search for first (FCB)	*/
#define	_SNEXT		(TINY)0x12	/* Search for next (FCB)	*/
#define	_FDEL		(TINY)0x13	/* Delete file (FCB)		*/
#define	_RDSEQ		(TINY)0x14	/* Read sequential (FCB)	*/
#define	_WRSEQ		(TINY)0x15	/* Write sequential (FCB)	*/
#define	_FMAKE		(TINY)0x16	/* Create file (FCB)		*/
#define	_FREN		(TINY)0x17	/* Rename file (FCB)		*/
#define	_LOGIN		(TINY)0x18	/* Get login vector		*/
#define	_CURDRV		(TINY)0x19	/* Get current drive		*/
#define	_SETDTA		(TINY)0x1a	/* Set disk transfer address	*/
#define	_ALLOC		(TINY)0x1b	/* Get allocation information	*/
/*  < no function >     (TINY)0x1c					*/
/*  < no function >     (TINY)0x1d					*/
/*  < no function >     (TINY)0x1e					*/
/*  < no function >     (TINY)0x1f					*/
/*  < no function >     (TINY)0x20					*/
#define	_RDRND		(TINY)0x21	/* Read random (FCB)		*/
#define	_WRRND		(TINY)0x22	/* Write random (FCB)		*/
#define	_FSIZE		(TINY)0x23	/* Get file size (FCB)		*/
#define	_SETRND		(TINY)0x24	/* Set random record (FCB)	*/
/*  < no function >     (TINY)0x25					*/
#define	_WRBLK		(TINY)0x26	/* Write random block (FCB)	*/
#define	_RDBLK		(TINY)0x27	/* Read random block (FCB)	*/
#define	_WRZER		(TINY)0x28	/* Write random with zero fill (FCB)*/
/*  < no function >     (TINY)0x29					*/
#define	_GDATE		(TINY)0x2a	/* Get date			*/
#define	_SDATE		(TINY)0x2b	/* Set date			*/
#define	_GTIME		(TINY)0x2c	/* Get time			*/
#define	_STIME		(TINY)0x2d	/* Set time			*/
#define	_VERIFY		(TINY)0x2e	/* Set/reset verify flag	*/
#define	_RDABS		(TINY)0x2f	/* Absolute sector read		*/
#define	_WRABS		(TINY)0x30	/* Absolute sector write	*/
#define	_DPARM		(TINY)0x31	/* Get disk parameters		*/
#define	_FFIRST		(TINY)0x40	/* Find first entry		*/
#define	_FNEXT		(TINY)0x41	/* Find next entry		*/
#define	_FNEW		(TINY)0x42	/* Find new entry		*/
#define	_OPEN		(TINY)0x43	/* Open file handle		*/
#define	_CREATE		(TINY)0x44	/* Create file and open handle	*/
#define	_CLOSE		(TINY)0x45	/* Close file handle		*/
#define	_ENSURE		(TINY)0x46	/* Ensure file handle		*/
#define	_DUP		(TINY)0x47	/* Duplicate file  andle	*/
#define	_READ		(TINY)0x48	/* Read from file handle	*/
#define	_WRITE		(TINY)0x49	/* Write to file handle		*/
#define	_SEEK		(TINY)0x4a	/* Seek (position file pointer)	*/
#define	_IOCTL		(TINY)0x4b	/* I/O control for devices	*/
#define	_HTEST		(TINY)0x4c	/* Test file handle		*/
#define	_DELETE		(TINY)0x4d	/* Delete file or subdirectory	*/
#define	_RENAME		(TINY)0x4e	/* Rename file or subdirectory	*/
#define	_MOVE		(TINY)0x4f	/* Move file or subdirectory	*/
#define	_ATTR		(TINY)0x50	/* Change file or subdir attributes*/
#define	_FTIME		(TINY)0x51	/* Get/set file date and time	*/
#define	_HDELET		(TINY)0x52	/* Delete file handle		*/
#define	_HRENAME	(TINY)0x53	/* Rename file handle		*/
#define	_HMOVE		(TINY)0x54	/* Move file handle		*/
#define	_HATTR		(TINY)0x55	/* Change file handle attributes*/
#define	_HFTIME		(TINY)0x56	/* Get/set file handle date and time*/
#define	_GETDTA		(TINY)0x57	/* Get disk transfer address	*/
#define	_GETVFY		(TINY)0x58	/* Get verify flag setting	*/
#define	_GETCD		(TINY)0x59	/* Get current directory	*/
#define	_CHDIR		(TINY)0x5a	/* Change directory		*/
#define	_PARSE		(TINY)0x5b	/* Parse pathname		*/
#define	_PFILE		(TINY)0x5c	/* Parse filename		*/
#define	_CHKCHR		(TINY)0x5d	/* Check character 		*/
#define	_WPATH		(TINY)0x5e	/* Get whole path string	*/
#define	_FLUSH		(TINY)0x5f	/* Flush disk buffers		*/
#define	_FORK		(TINY)0x60	/* Fork a child process		*/
#define	_JOIN		(TINY)0x61	/* Return to parent process	*/
#define	_TERM		(TINY)0x62	/* Terminate with error code	*/
#define	_DEFAB		(TINY)0x63	/* Define abort exit routine	*/
#define	_DEFER		(TINY)0x64	/* Def. critical err handle routine*/
#define	_ERROR		(TINY)0x65	/* Get previous error code	*/
#define	_EXPLAIN	(TINY)0x66	/* Explain error code		*/
#define	_FORMAT		(TINY)0x67	/* Format disk			*/
#define	_RAMD		(TINY)0x68	/* Create or destroy RAMdisk	*/
#define	_BUFFER		(TINY)0x69	/* Allocate sector buffers	*/
#define	_ASSIGN		(TINY)0x6a	/* Logical drive assignment	*/
#define	_GENV		(TINY)0x6b	/* Get environment item		*/
#define	_SENV		(TINY)0x6c	/* Set environment item		*/
#define	_FENV		(TINY)0x6d	/* Find environment item	*/
#define	_DSKCHK		(TINY)0x6e	/* Get/set disk check status	*/
#define	_DOSVER		(TINY)0x6f	/* Get MSX-DOS version number	*/
#define	_REDIR		(TINY)0x70	/* Get/set redirection flags	*/

#ifdef	HEADERbdosfuncver11
#define RESET		_TERM0
#define CONIN		_CONIN
#define CONOUT		_CONOUT
#define AUXIN		_AUXIN
#define RDRIN           _AUXIN
#define AUXOUT		_AUXOUT
#define PUNOUT          _AUXOUT
#define LSTOUT		_LSTOUT
#define DIRCON		_DIRIO
#define RAWIN		_DIRIN
#define DIRIN		_INNOE
#define STROUT		_STROUT
#define GETLIN		_BUFIN
#define CONST		_CONST
#define VERNO		_CPMVER
#define RESDSK		_DSKRST
#define SETDRIVE	_SELDSK
#define OPEN		_FOPEN
#define CLOSE		_FCLOSE
#define SEARF		_SFIRST
#define SEARN		_SNEXT
#define DELETE		_FDEL
#define CPMREAD		_RDSEQ
#define CPMWRITE	_WRSEQ
#define CREATE		_FMAKE
#define RENAME		_FREN
#define LOGVEC		_LOGIN
#define GETDRIVE	_CURDRV
#define SETDMA		_SETDTA
#define GETALOC		_ALLOC
#define READRNDM	_RDRND
#define WRTRNDM		_WRRND
#define FILESIZE	_FSIZE
#define SETREC		_SETRND
#define BLKWRITE	_WRBLK
#define BLKREAD		_RDBLK
#define WRTRNDMZ	_WRZER
#define GETDATE		_GDATE
#define SETDATE		_SDATE
#define GETTIME		_GTIME
#define SETTIME		_STIME
#define SETVERI		_VERIFY
#define ABSREAD		_RDABS
#define ABSWRIT		_WRABS

#define INITDMA         0x0080  /* default DMA area	*/
#define MAXDRIVE        8       /* maxmum disk drive	*/
#define BDOSERR         255     /* BDOS error value	*/

#endif	/*  HEADERbdosfuncver11  */
/*---------------------------------------------------------------------------*/

#define BIOS_WBOOT      '\000'  /* WARM START		*/
#define BIOS_CONST      '\001'  /* console status	*/
#define BIOS_CONIN      '\002'  /* console input	*/
#define BIOS_CONOUT     '\003'  /* console output	*/

typedef	unsigned LONG[2];

typedef	struct {
	char	dc;		/* drive code				*/
	char	name[8];	/* file name				*/
	char	type[3];	/* file name extention			*/

	char	_filler1_[2];
	unsigned recsize;	/* record size used by block i/o	*/
	LONG	filesize;	/* file size in bytes			*/
	unsigned fcbdate;
	unsigned fcbtime;
	char	_filler2_[9];
	LONG	recpos;		/* current record number		*/

	char	mode;		/* file mode    R, W, R/W		*/
} FCB;

typedef	struct {
	TINY    fib_id;		/* always 0xff (ID for FIB)		*/
	char    name[13];	/* file name as an ASCIZ string		*/
	TINY    attr;		/* file attribute			*/
	unsigned fibtime;	/* time of last modification		*/
	unsigned fibdate;	/* date of last modification		*/
	unsigned firstclu;	/* first cluster in chain		*/
	LONG    filesize;	/* file size in bytes			*/
	TINY    dc;		/* logical drive			*/
	TINY    dummy[38];	/* internal information			*/
} FIB;

typedef	struct {
	unsigned af;
	unsigned ix;
	unsigned iy;
	unsigned bc;
	unsigned de;
	unsigned hl;
} XREG;

#define	BDOS	0x0005		/*  BDOS call address			*/
extern	int     bdosh(), call();
extern	char    bdos(),  calla(), bios();
extern	VOID	callxx();

#endif	/*  HEADERbdosfunc  */

                                                                                                       