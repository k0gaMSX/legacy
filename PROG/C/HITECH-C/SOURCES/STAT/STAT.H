/* stat.h, modified for msxdos 10/93 */

/* Flag bits in st_mode:
 *
 * bit 0: file is readonly
 * bit 1: file is hidden
 * bit 2: file is system
 * bit 3: file is volumename
 * bit 4: subdirectory
 * bit 5: archive bit
 * bit 6: reserved
 * bit 7: device is a tty
 *
 */

#define S_IFMT		0xff	/* file type (keine ahnung) */
#define S_IFDIR 	0x10	/* is a directory (bit 4 set) */
#define S_IFREG 	0x67	/* is a regular file (bit 7,4,3 NOT set) */
#define S_IEXEC 	0x67	/* file can be executed */
#define S_IREAD 	0xff	/* file can be read */
#define S_IWRITE	0xfe	/* file can be written (bit 0 NOT set) */
#define S_HIDDEN	0x02	/* file is hidden */
#define S_SYSTEM	0x04	/* file is marked system */
#define S_ARCHIVE	0x20	/* file has been written to */


extern int stat();


struct stat
{
	short	st_mode;	/* flags */
	long	st_atime;	/* access time */
	long	st_mtime;	/* modification time */
	long	st_size;	/* file size in bytes */
};


                                                  