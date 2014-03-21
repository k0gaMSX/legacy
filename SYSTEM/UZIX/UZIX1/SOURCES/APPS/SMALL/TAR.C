/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * The "tar" command (much simplified).
 */

/* to do: option -ac
	  better unix to/from uzix time conversion routines

   obs.: the original doheader() was incompatible with my TAR of RH Linux 4.
   	 I changed some header handling, specially the size/time/chksum
   	 field, that is separated only by spaces, not 0s. Also, the
   	 printf of listing is buggy with TC3.0/HTC (time is null and
   	 name is replaced by time or time is filled with trash), so I split 
   	 the printf in 3. Also, chksum, mode and mtime can be greater enough to 
   	 be interpreted as negative values for non-unsigned types, so I created 
   	 a badoctal static variable as bad octal flag. 
   	 ACRdC, 05/99
*/

#include <stdio.h>
#include <unistd.h>
#include <alloc.h>
#include <string.h>
#include <errno.h>
#include <types.h>
#include <time.h>
#include <sys/stat.h>

typedef unsigned char BOOL;

#define FALSE   ((BOOL) 0)
#define TRUE    ((BOOL) 1)
#define isoctal(ch)   (((ch) >= '0')  && ((ch) <= '7'))

/*
 * Tar file format.
 */
#define TBLOCK 512
#define NAMSIZ 100

union hblock {
	char dummy[TBLOCK];
	struct header {
		char name[NAMSIZ];
		char mode[8];
		char uid[8];
		char gid[8];
		char size[12];
		char mtime[12];
		char chksum[8];
		char linkflag;
		char linkname[NAMSIZ];
		char extno[4];
		char extotal[4];
		char efsize[12];
	} dbuf;
} dblock;


static	BOOL		inheader;
static	BOOL		badheader;
static	BOOL		badwrite;
static	BOOL		badoctal;
static	BOOL		extracting;
static	BOOL		warnedroot;
static	BOOL		eof;
static	BOOL		verbose;
static	long		datacc;
static	int		outfd;
static	char		outname[NAMSIZ];

static	void		doheader();
static	void		dodata();
static	void		createpath();
static	unsigned long	getoctal();

BOOL	intflag;

time_t unixtouzixtime(unsigned long t) {
 int y=0,m=0,d=0,h=0,mm=0;
 unsigned long t1=t;
 time_t tt;

 if (t1>=31536000) { 
  y=t1/31536000L;
  t1=t1-(y*31536000L);
  y=y-10;
 }
 if (t1>=2592000) {
  m=t1/2592000L;
  t1=t1-(m*2592000L);
  m++;
 }
 if (t1>=86400) {
  d=t1/86400;
  t1=t1-d*86400;
  d++;
 }
 if (t1>=3600) {
  h=t1/3600;
  t1=t1-h*3600;
 }
 if (t1>=60) {
  mm=t1/60;
  t1=t1-m*60;
 }
 tt.t_time=(((int)h << 8) << 3) | ((int)mm << 5) | ((int)t1 >> 1);
 tt.t_date=(((int)y << 8) << 1) | ((int)m << 5) | d; 
 return tt;
}

long uzixtounixtime(time_t *t) {
 int y,m,d,h,mm,s;
 
 s=(t->t_time & 31)*2;
 mm=((t->t_time >> 5) & 63);
 h=((t->t_time >> 11) & 31);
 d=(t->t_date & 31)-1;
 m=((t->t_date >> 5) & 15)-1;
 y=((t->t_date >> 9) & 127)+10;
 return y*31536000L+m*2592000L+d*86400+h*3600+mm*60+s;
}

/*
 * Handle a data block of some specified size.
 */
static void
dodata(cp, count)
	char	*cp;
{
	int	cc;

	datacc -= count;
	if (datacc <= 0)
		inheader = TRUE;

	if (badwrite || !extracting)
		return;

	while (count > 0) {
		cc = write(outfd, cp, count);
		if (cc < 0) {
			perror(outname);
			close(outfd);
			outfd = -1;
			badwrite = TRUE;
			return;
		}
		count -= cc;
	}

	if (datacc <= 0) {
		if (close(outfd))
			perror(outname);
		outfd = -1;
	}
}


/*
 * Attempt to create the directories along the specified path, except for
 * the final component.  The mode is given for the final directory only,
 * while all previous ones get default protections.  Errors are not reported
 * here, as failures to restore files can be reported later.
 */
static void
createpath(name, mode)
	char	*name;
{
	char	*cp;
	char	*cpold;
	char	buf[NAMSIZ];

	strcpy(buf, name);

	cp = strchr(buf, '/');

	while (cp) {
		cpold = cp;
		cp = strchr(cp + 1, '/');

		*cpold = '\0';
		if (mkdir(buf, cp ? 0777 : mode) == 0)
			printf("Directory \"%s\" created\n", buf);

		*cpold = '/';
	}
}


/*
 * Read an octal value in a field of the specified width, with optional
 * spaces on both sides of the number and with an optional null character
 * at the end.	Returns -1 on an illegal format.
 */
static unsigned long
getoctal(cp, len)
	char	*cp;
{
	unsigned long	val;

	badoctal = FALSE;
	while ((len > 0) && (*cp == ' ')) {
		cp++;
		len--;
	}

	if ((len == 0) || !isoctal(*cp)) {
		badoctal = TRUE;
		return -1;
	}

	val = 0;
	while ((len > 0) && isoctal(*cp)) {
		val = val * 8 + *cp++ - '0';
		len--;
	}

	while ((len > 0) && (*cp == ' ')) {
		cp++;
		len--;
	}

	if ((len > 0) && ((*cp != ' ') && (*cp != 0))) {
		badoctal = TRUE;
		return -1;
	}

	return val;
}

#define BUF_SIZE 1024

typedef struct	chunk	CHUNK;
#define CHUNKINITSIZE	4
struct	chunk	{
	CHUNK	*next;
	char	data[CHUNKINITSIZE];	/* actually of varying length */
};

static	CHUNK * chunklist;

/*
 * Return the standard ls-like mode string from a file mode.
 * This is static and so is overwritten on each call.
 */
char *
modestring(mode)
{
	static	char	mbuf[12];

	strcpy(mbuf, "----------");

	/*
	 * Fill in the file type.
	 */
	if (S_ISDIR(mode))
		mbuf[0] = 'd';
	if (S_ISCHR(mode))
		mbuf[0] = 'c';
	if (S_ISBLK(mode))
		mbuf[0] = 'b';
	if (S_ISPIPE(mode))		/* PIPE=FIFO? */
		mbuf[0] = 'p';
#ifdef	S_ISLNK
	if (S_ISLNK(mode))
		mbuf[0] = 'l';
#endif
#ifdef	S_ISSOCK
	if (S_ISSOCK(mode))
		mbuf[0] = 's';
#endif

	/*
	 * Now fill in the normal file permissions.
	 */
	if (mode & S_IRUSR)
		mbuf[1] = 'r';
	if (mode & S_IWUSR)
		mbuf[2] = 'w';
	if (mode & S_IXUSR)
		mbuf[3] = 'x';
	if (mode & S_IRGRP)
		mbuf[4] = 'r';
	if (mode & S_IWGRP)
		mbuf[5] = 'w';
	if (mode & S_IXGRP)
		mbuf[6] = 'x';
	if (mode & S_IROTH)
		mbuf[7] = 'r';
	if (mode & S_IWOTH)
		mbuf[8] = 'w';
	if (mode & S_IXOTH)
		mbuf[9] = 'x';

	/*
	 * Finally fill in magic stuff like suid and sticky text.
	 */
	if (mode & S_ISUID)
		mbuf[3] = ((mode & S_IXUSR) ? 's' : 'S');
	if (mode & S_ISGID)
		mbuf[6] = ((mode & S_IXGRP) ? 's' : 'S');
	if (mode & S_ISVTX)
		mbuf[9] = ((mode & S_IXOTH) ? 't' : 'T');

	return mbuf;
}

/*
 * Get the time to be used for a file.
 * This is down to the minute for new files, but only the date for old files.
 * The string is returned from a static buffer, and so is overwritten for
 * each call.
 */
char *
timestring(t)
	unsigned long	t;
{
	unsigned long	now;
	time_t		tt;
	char		*str;
	static	char	tbuf[26];

	time(&tt);
	now=uzixtounixtime(&tt);

	tt=unixtouzixtime(t);
	str = ctime(&tt);

	strcpy(tbuf, &str[4]);
	tbuf[12] = '\0';

	if ((t > now) || (t < now - 365*24*60*60L)) {
		strcpy(&tbuf[7], &str[20]);
		tbuf[11] = '\0';
	}

	return tbuf;
}

static void
doheader(hp)
	struct	header	*hp;
{
	unsigned int		mode;
	unsigned int		uid;
	unsigned int		gid;
	unsigned int		chksum;
	unsigned long		size;
	unsigned long		mtime;
	char			*name;
	int			cc;
	BOOL			hardlink;
	BOOL			softlink;
	BOOL			headererror;

	/*
	 * If the block is completely empty, then this is the end of the
	 * archive file.  If the name is null, then just skip this header.
	 */
	name = hp->name;
	if (*name == '\0') {
		for (cc = TBLOCK; cc > 0; cc--) {
			if (*name++)
				return;
		}

		eof = TRUE;
		return;
	}

	headererror = FALSE;
	mode = getoctal(hp->mode, sizeof(hp->mode));
	headererror |= badoctal;	
	uid = getoctal(hp->uid, sizeof(hp->uid));
	headererror |= badoctal;	
	gid = getoctal(hp->gid, sizeof(hp->gid));
	headererror |= badoctal;	
	size = getoctal(hp->size, sizeof(hp->size));
	headererror |= badoctal;	
	mtime = getoctal(hp->mtime, sizeof(hp->mtime));
	headererror |= badoctal;	
	chksum = getoctal(hp->chksum, sizeof(hp->chksum));
	headererror |= badoctal;	

	if (headererror) {
		if (!badheader)
			fprintf(stderr, "Bad tar header, skipping\n");
		badheader = TRUE;
		return;
	}

	badheader = FALSE;
	badwrite = FALSE;

	hardlink = ((hp->linkflag == 1) || (hp->linkflag == '1'));
	softlink = ((hp->linkflag == 2) || (hp->linkflag == '2'));

	if (name[strlen(name) - 1] == '/')
		mode |= S_IFDIR;
	else if ((mode & S_IFMT) == 0)
		mode |= S_IFREG;

	if (*name == '/') {
		while (*name == '/')
			name++;

		if (!warnedroot)
			fprintf(stderr, "Absolute paths detected, removing leading slashes\n");
		warnedroot = TRUE;
	}

	if (!extracting) {
		if (verbose) {
			printf("%s %3d/%-d %9d ", modestring(mode),
				uid, gid, size);
			printf("%s ", timestring(mtime));
		}
		printf("%s", name);

		if (hardlink)
			printf(" (link to \"%s\")", hp->linkname);
		else if (softlink)
			printf(" (symlink to \"%s\")", hp->linkname);
		else if (S_ISREG(mode)) {
			inheader = (size == 0);
			datacc = size;
		}

		printf("\n");
		return;
	}

	if (verbose)
		printf("x %s\n", name);


	if (hardlink) {
		if (link(hp->linkname, name) < 0)
			perror(name);
		return;
	}

	if (softlink) {
#ifdef	S_ISLNK
		if (symlink(hp->linkname, name) < 0)
			perror(name);
#else
		fprintf(stderr, "Cannot create symbolic links\n");
#endif
		return;
	}

	if (S_ISDIR(mode)) {
		createpath(name, mode);
		return;
	}

	createpath(name, 0777);

	inheader = (size == 0);
	datacc = size;

	outfd = creat(name, mode);
	if (outfd < 0) {
		perror(name);
		badwrite = TRUE;
		return;
	}

	if (size == 0) {
		close(outfd);
		outfd = -1;
	}
}

void
main(argc, argv)
	char	**argv;
{
	char	*str;
	char	*devname;
	char	*cp;
	int	devfd;
	int	cc;
	long	incc;
	int	blocksize;
	BOOL	createflag;
	BOOL	listflag;
	BOOL	fileflag;
	char	buf[8192];

	if (argc < 2) {
		fprintf(stderr, "usage: tar [xtv]f devname filename ...\n");
		return;
	}

	createflag = FALSE;
	extracting = FALSE;
	listflag = FALSE;
	fileflag = FALSE;
	verbose = FALSE;
	badwrite = FALSE;
	badheader = FALSE;
	warnedroot = FALSE;
	eof = FALSE;
	inheader = TRUE;
	incc = 0;
	datacc = 0;
	outfd = -1;
	blocksize = sizeof(buf);

	for (str = argv[1]; *str; str++) {
		switch (*str) {
			case 'f':	fileflag = TRUE; break;
			case 't':	listflag = TRUE; break;
			case 'x':	extracting = TRUE; break;
			case 'v':	verbose = TRUE; break;

			case 'c':
			case 'a':
				fprintf(stderr, "Writing is not supported\n");
				return;

			default:
				fprintf(stderr, "Unknown tar flag\n");
				return;
		}
	}

	if (!fileflag) {
		fprintf(stderr, "The 'f' flag must be specified\n");
		return;
	}

	if (argc < 3) {
		fprintf(stderr, "Missing input name\n");
		return;
	}
	devname = argv[2];

	if (extracting + listflag != 1) {
		fprintf(stderr, "Exactly one of 'x' or 't' must be specified\n");
		return;
	}

	devfd = open(devname, 0);
	if (devfd < 0) {
		perror(devname);
		return;
	}

	while (TRUE) {
		if ((incc == 0) && !eof) {
			while (incc < blocksize) {
				cc = read(devfd, &buf[incc], blocksize - incc);
				if (cc < 0) {
					perror(devname);
					goto done;
				}

				if (cc == 0)
					break;

				incc += cc;
			}
			cp = buf;
		}

		if (intflag) {
			if (extracting && (outfd >= 0))
				close(outfd);
			close(devfd);
			return;
		}

		if (inheader) {
			if ((incc == 0) || eof)
				goto done;

			if (incc < TBLOCK) {
				fprintf(stderr, "Short block for header\n");
				goto done;
			}

			doheader((struct header *) cp);

			cp += TBLOCK;
			incc -= TBLOCK;

			continue;
		}

		cc = incc;
		if (cc > datacc)
			cc = datacc;

		dodata(cp, cc);

		if (cc % TBLOCK)
			cc += TBLOCK - (cc % TBLOCK);

		cp += cc;
		incc -= cc;
	}

done:
	close(devfd);
}
