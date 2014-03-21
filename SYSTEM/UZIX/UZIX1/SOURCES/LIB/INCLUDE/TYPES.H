#ifndef __TYPES_H
#define __TYPES_H

#ifndef __FEATURES_H
#include "features.h"
#endif

/* USER! basic data types */
/* ! uchar & uint is counterparts and must be declared simultaneously */
#ifndef uchar_is_defined
#define uchar_is_defined
typedef unsigned char uchar;
typedef unsigned int uint;
#endif

typedef uchar bool_t;	/* boolean value */
typedef uint count_t;	/* counter for anything */
#ifndef _SIZE_T
#define _SIZE_T
typedef uint size_t;
#endif

typedef unsigned int mode_t;
typedef long off_t;

/* file's timestamp structure (non UNIX-standart) */
typedef struct s_time {
	uint	t_time;
	uint	t_date;
} time_t;

/* User's structure for times() system call */
struct tms {
	time_t	tms_utime;
	time_t	tms_stime;
	time_t	tms_cutime;
	time_t	tms_cstime;
	time_t	tms_etime;	/* Elapsed real time */
};

#ifndef utimbuf_is_defined
#define utimbuf_is_defined
/* User's structure for utime() system call */
struct utimbuf {
	time_t	actime;
	time_t	modtime;
};
#endif

/* data structure for stat() */
struct stat {			/* USER! Really only used by users */
	uint	st_dev; 	/* device number */
	uint	st_ino; 	/* inode number */
	mode_t	st_mode;	/* file mode */
	uint	st_nlink;	/* number of links */
	uint	st_uid; 	/* owner id */
	uint	st_gid; 	/* owner group */
	uint	st_rdev;	/* */
	off_t	st_size;	/* file size */
	time_t	st_atime;	/* last access time */
	time_t	st_mtime;	/* last modification time */
	time_t	st_ctime;	/* file creation time */
};

#define DIRNAMELEN	14

/* device directory entry */
typedef struct s_direct {
	unsigned int d_ino;		/* file's inode */
	uchar	d_name[DIRNAMELEN];	/* file name */
} direct_t;

#ifndef NULL
#define NULL		0
#endif

#define BUFSIZE 	512	/* uzix buffer/block size */
#define BUFSIZELOG	9	/* uzix buffer/block size log2 */

#ifndef BUFSIZ
#ifdef PC_HOSTED
#define BUFSIZ		512	/* stdio buffer size */
#else
#define BUFSIZ		256	/* 512 is too much. MSX memory is little. */
#endif
#endif

#define PATHLEN 	256

#endif

