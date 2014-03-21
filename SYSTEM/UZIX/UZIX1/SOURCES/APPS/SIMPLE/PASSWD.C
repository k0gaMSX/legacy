/* passwd.c
 * description:  change user password
 * author:	 Shane Kerr <kerr@wizard.net>
 * copyright:	 1998 by Shane Kerr <kerr@wizard.net>, under terms of GPL
 */

/* todo:  make executable setuid on execute */
/*	  needs to check setuid bit in fs/exec.c of ELKS kernel */
/* todo:  add a set of rules to make sure trivial passwords are not used */
/* todo:  lock password file while updating */
/*	  need file locking first */
/* todo:  use rename to do an atomic move of temporary file */
/*	  need rename that overwrites first */

#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <paths.h>
#include <time.h>
#include <pwd.h>

/* maximum errors */
#define MAX_FAILURE 5

/* valid characters for a salt value */
static char salt_char[] = 
	"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./";

int main(argc, argv)
	int argc;
	char **argv;
{
	char *s, *pbuf, *tmp_fname, *pwf = _PATH_PASSWD;
	char salt[3], nbuf1[128], nbuf2[128];
	int n, ch, failure_cnt, uid, gid;
	struct passwd *pwd;
	FILE *passwd_fp;
	time_t now;

	switch (argc) {
	case 1:
		if ((pwd = getpwuid(getuid())) == NULL) {
			fprintf(stderr, "%s: Error reading password file\n", argv[0]);
			return 1;
		}
		break;
	case 2:
		if ((pwd = getpwnam(argv[1])) == NULL) {
			fprintf(stderr, "%s: Unknown user %s\n", argv[0], argv[1]);
			return 1;
		}
		if ((getuid() != 0) && (getuid() != pwd->pw_uid)) {
			fprintf(stderr, "You may not change the password for %s.\n",
				argv[1]);
			return 1;
		}
		break;
	default:
		fprintf(stderr, "usage: %s [name]\n", argv[0]);
		return 1;
	}

	printf("Changing password for %s\n", pwd->pw_name);

	if ((getuid() != 0) && (pwd->pw_passwd[0] != 0)) {
		pbuf = getpass("Old password:");
		putchar('\n');
		salt[0] = pwd->pw_passwd[0];
		salt[1] = pwd->pw_passwd[1];
		salt[2] = 0;
		if (strcmp(crypt(pbuf, salt), pwd->pw_passwd)) {
			fprintf(stderr, "Incorrect password for %s.\n", pwd->pw_name);
			return 1;
		}
		memset(pbuf, 0, strlen(pbuf));
	}
	failure_cnt = 0;
	for (;;) {
		pbuf = getpass("New password:");
		putchar('\n');
		strcpy(nbuf1, pbuf);
		pbuf = getpass("Re-enter new password:");
		putchar('\n');
		strcpy(nbuf2, pbuf);
		if (strcmp(nbuf1, nbuf2) == 0) {
			/* need to create a tmp file for the new password */
			if ((tmp_fname = tmpnam(NULL)) == NULL) {
				perror("Error getting temporary file name");
				return 1;
			}
			if ((passwd_fp = fopen(tmp_fname, "w")) == NULL) {
				perror(tmp_fname);
				return 1;
			}
			/* save off our UID */
			uid = pwd->pw_uid;
			gid = pwd->pw_gid;
			time(&now);
			salt[0] = salt_char[(now.t_time) & 0x3F];
			salt[1] = salt_char[(now.t_time >> 6) & 0x3F];
			salt[2] = 0;
			s = crypt(nbuf1, salt);
			/* save entries to the new file */
			setpwent();
			for (n = 0; (pwd = getpwent()) != NULL; ++n) {
				if (pwd->pw_uid == uid && pwd->pw_gid == gid)
					pwd->pw_passwd = s;
				if (putpwent(pwd, passwd_fp) == -1) {
					perror("Error writing password file");
					return 1;
				}
			}
			endpwent();
			/* update the file and move it into position */
			fclose(passwd_fp);
			if (n < 1) {
				fprintf(stderr, "Can't rewrite %s\n", pwf);
			}
			strcpy(nbuf2, pwf);
			strcat(nbuf2, "~");
			unlink(nbuf2);
			if (rename(pwf, nbuf2) == -1) {
				perror("Error renaming old password file");
				return 1;
			}
			if (rename(tmp_fname, pwf) == -1) {
				perror("Error installing new password file");
				return 1;
			}
			/* celebrate our success */
			printf("Password changed.\n");
			return 0;
		}
		if (++failure_cnt >= MAX_FAILURE) {
			fprintf(stderr, "The password for %s is unchanged.\n", pwd->pw_name);
			return 1;
		}
		fprintf(stderr, "They don't match; try again.\n");
	}
}
