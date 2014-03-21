/* login.c
 * descripton:	 login into a user account
 * author:	 Alistair Riddoch
 * modification: David Murn <scuffer@hups.apana.org.au>
 *		 Added password entry
 * modification: Shane Kerr <kerr@wizard.net>
 *		 More work on password entry
 */

/* todo:  add a timeout for serial and network logins */
/* ???	  need a signal mechanism (i.e. alarm() and SIGALRM) */
/* 	  real getpass() ! */

#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <pwd.h>

void login(pwd, argv)
	struct passwd *pwd;
	char **argv;
{
	char pname[64];
	char *bname;

/*	chown("/dev/tty",pwd->pw_uid,pwd->pw_gid); */
	pname[0] = '-';
	if ((bname = strrchr(pwd->pw_shell, '/')) != NULL)
		bname++;
	else	bname = pwd->pw_shell;
	strcpy(pname+1, bname);
	argv[0] = pname;
	argv[1] = NULL;
	/* we must set first GID, because we're still root
	   if UID is set first and we aren't logging as root,
	   we won't have permission to change our GID */
	setgid(pwd->pw_gid);
	setuid(pwd->pw_uid);
	chdir(pwd->pw_dir);
	setenv("HOME", pwd->pw_dir, 1);
	setenv("USER", pwd->pw_name, 1);
	execv(pwd->pw_shell, argv);
	perror(pwd->pw_shell);
	exit(1);
}

void main(argc, argv)
	int argc;
	char **argv;
{
	char lbuf[20], *pbuf, salt[3], *s;
	struct passwd *pwd;
	int n;

	argv[0] = "login";
	for (;;) {
		if (argc > 1) {
			strcpy(lbuf, argv[1]);
			argc = 0;
		}
		else {
			fputs("login: ", stdout);
			fflush(stdout);
			if (fgets(lbuf, sizeof(lbuf), stdin) == NULL)
				exit(1);
			n = strlen(lbuf) - 1;
			if (lbuf[n] == '\n')
				lbuf[n] = 0;
			if (lbuf[0] == 0)
				continue;
		}
		pwd = getpwnam(lbuf);
		if ((pwd != NULL) && (pwd->pw_passwd[0] == 0))
			login(pwd, argv);
		pbuf = getpass("Password: ");
		putchar('\n');
		if (pwd != NULL) {
			salt[0] = pwd->pw_passwd[0];
			salt[1] = pwd->pw_passwd[1];
			salt[2] = 0;
			s = crypt(pbuf, salt);
			if (!strcmp(s, pwd->pw_passwd))
				login(pwd, argv);
		}
		fputs("Login incorrect\n\n", stdout);
	}
}

