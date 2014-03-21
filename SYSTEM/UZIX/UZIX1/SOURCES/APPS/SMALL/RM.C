/*
**	rm [-fir] file ...
*/

#include	<stdlib.h>
#include	<stdio.h>
#include	<types.h>
#include	<sys/stat.h>
#include	<dirent.h>
#include	<string.h>
#include	<unistd.h>

int	errcode;

int yes()
{
	int	i, b;

	i = b = getchar();
	while(b != '\n' && b > 0)
		b = getchar();
	return(i == 'y');
}

int dotname(s)
char *s;
{
	if((s[0]&0177) == '.')
		if((s[1]&0177) == '.')
			if(s[2] == '\0' || (s[2]&0177) == '/')
				return(1);
			else
				return(0);
		else if(s[1] == '\0')
			return(1);
	return(0);
}

int rm_dir(f, iflg)
char *f;
int iflg;
{
	if(dotname(f))
		return(0);
	if(iflg) {
		printf("remove directory %s ? ", f);
		fflush(stdout);
		if(!yes())
			return(0);
	}
	if (!rmdir(f)) {
		perror("rm");
		return(1);
	}
	return(0);
}

void rm(arg, fflg, rflg, iflg)
char arg[];
int fflg;
int rflg;
int iflg;
{
	struct	stat		buf;
	struct	dirent		*direct;
	char			name[100];
	DIR			*dirp;

	if(stat(arg, &buf)) {
		if (fflg==0) {
			fprintf(stderr, "%s: No such file or directory\n", arg);
			++errcode;
		}
		return;
	}
	if ((buf.st_mode&S_IFMT) == S_IFDIR) {
		if(rflg) {
			if(iflg && !dotname(arg)) {
				printf("remove directory %s ? ", arg);
				fflush(stdout);
				if(!yes())
					return;
			}
			if((dirp=opendir(arg)) == NULL) {
				fprintf(stderr, "rm: cannot read %s\n", arg);
				exit(2);
			}
			while((direct = readdir(dirp)) != NULL) {
				if(direct->d_ino != 0 && !dotname(direct->d_name)) {
					sprintf(name, "%s/%.14s", arg, direct->d_name);
					rm(name, fflg, rflg, iflg);
				}
			}
			closedir(dirp);
			errcode += rm_dir(arg, iflg);
			return;
		}
		fprintf(stderr, "rm: %s is a directory\n", arg);
		++errcode;
		return;
	}

	if(iflg) {
		printf("remove %s ? ", arg);
		fflush(stdout);
		if(!yes())
			return;
	}
	else if(!fflg) {
		if(access(arg, 02) < 0 && isatty(fileno(stdin))) {
			printf("%s: override mode %o ? ", arg, buf.st_mode&0777);
			fflush(stdout);
			if(!yes())
				return;
		}
	}
	if(unlink(arg) && (fflg==0 || iflg)) {
		fprintf(stderr, "rm: %s not removed. ", arg);
		perror(" ");
		++errcode;
	}
}

void main(argc, argv)
int argc;
char *argv[];
{
	register char *arg;
	int fflg, iflg, rflg;

	fflg = 0;
	if (isatty(0) == 0)
		fflg++;
	iflg = 0;
	rflg = 0;
	if (argc < 2) {
		printf("usage: rm [-fir] files ...\n");
		exit(1);
	}
	while(argc>1 && argv[1][0]=='-') {
		arg = *++argv;
		argc--;

		/*
		 *  all files following a null option are considered file names
		 */
		if (*(arg+1) == '\0') break;

		while(*++arg != '\0')
			switch(*arg) {
			case 'f':
				fflg++;
				break;
			case 'i':
				iflg++;
				break;
			case 'r':
				rflg++;
				break;
			default:
				printf("usage: rm [-fir] files ...\n");
				exit(1);
			}
	}
	while(--argc > 0) {
		if(!strcmp(*++argv, "..")) {
			fprintf(stderr, "rm: cannot remove '..'\n");
			continue;
		}
		rm(*argv, fflg, rflg, iflg);
	}

	exit(errcode?2:0);
}
