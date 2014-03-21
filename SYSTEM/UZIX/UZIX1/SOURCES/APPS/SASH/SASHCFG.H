/* Config file for sash.
 * Comment out #define for commands you do not require
 */

/* SASH: size without any defined command: 26162 bytes (MSX) */

/* nice: alias, cp, echo, help, kill, ls, mkdir, more, set, 
         pwd, rm, rmdir */

#define CMD_ALIAS	/* Includes unalias. 1048 bytes; 891 bytes (HTC). --*/
#define CMD_CAT_MORE	/* ? bytes; ? bytes (HTC) */
/*#define CMD_CHGRP	/* 2164 bytes */
#define CMD_CHMOD	/*  260 bytes */
/*#define CMD_CHOWN	/* 2080 bytes */
#define CMD_CHROOT	/*    ? bytes; 45 bytes (HTC) --*/
/*#define CMD_CMP 	/*  904 bytes */
/*#define CMD_CP	/* 1108 bytes; 1266 bytes (HTC) */
/*#define CMD_DD	/* 2524 bytes */
#define CMD_ECHO	/*  264 bytes; 208 bytes (HTC) */
/*#define CMD_EXEC	/*  ? bytes; ? bytes (HTC) */
/*#define CMD_ECHO_LIGHT/*  ? bytes; ? bytes (HTC) */
/*#define CMD_ED	/* 8300 bytes */
/*#define CMD_GREP	/*  144 bytes; 971 bytes (HTC) */
#define CMD_HELP	/*   88 bytes; 66 bytes (HTC) --*/
#define CMD_KILL	/*  532 bytes; 534 bytes (HTC) */
/*#define CMD_LN	/*  716 bytes */
/*#define CMD_LS	/* 7092 bytes; 4050 bytes (HTC) */
#define CMD_LS_LIGHT	/*    ? bytes; 1208 bytes (HTC) */
#define CMD_MKDIR	/*  140 bytes; 144 bytes (HTC) */
/*#define CMD_MKNOD	/*  516 bytes */
/*#define CMD_MORE	/*  608 bytes; 615 bytes (HTC) */
/*#define CMD_MOUNT	/*  600 bytes. Includes umount */
/*#define CMD_MV	/* 1272 bytes */
#define CMD_SET		/*  260 bytes; 325 bytes (HTC) */
#define CMD_PWD 	/*  928 bytes; 781 bytes (HTC) --*/
#define CMD_RM		/*  140 bytes; 101 bytes (HTC) */
/*#define CMD_RMDIR	/*  140 bytes; 400 bytes (HTC) */
#define CMD_SYNC	/*   80 bytes; 17 bytes (HTC) --*/
/*#define CMD_TAR 	/* 5576 bytes */
/*#define CMD_TOUCH	/*  236 bytes */
#define CMD_UMASK	/*  272 bytes; 259 bytes (HTC) --*/
#define CMD_SLEEP	/*      bytes; 224 bytes (HTC) --*/

#define PIPECMD		/* enable pipe (two external commands only) */

#ifdef CMD_LS
#ifdef CMD_LIGHT_LS
#error CMD_LS and CMD_LIGHT_LS defined. Must be exclusive.
#endif
#endif

#ifdef CMD_MORE
#ifdef CMD_CAT_MORE
#error CMD_MORE and CMD_CAT_MORE defined. Must be exclusive.
#endif
#endif

#ifdef CMD_CAT_MORE
#define CMDCAT	1
#define CMDMORE	2
#endif

#ifdef CMD_CP
#define FUNC_COPYFILE
#define FUNC_ISADIR
#define FUNC_BUILDNAME
#endif

#ifdef CMD_MV
#define FUNC_COPYFILE
#define FUNC_ISADIR
#define FUNC_BUILDNAME
#endif

#ifdef CMD_LN
#define FUNC_ISADIR
#define FUNC_BUILDNAME
#endif

#ifdef CMD_LS
#define FUNC_MODESTRING
#define FUNC_TIMESTRING
#endif

#ifdef CMD_TAR
#define FUNC_MODESTRING
#define FUNC_TIMESTRING
#endif
